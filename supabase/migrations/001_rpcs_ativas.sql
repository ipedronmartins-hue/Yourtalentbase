-- ============================================================================
-- MIGRAÇÃO 001 · RPCs ATIVAS (consolidação verbatim dos ficheiros vivos)
-- gestao_perfis + inscricao_livre + scouting360 + scout_plafond +
-- passaporte_admin + passaporte_familia_email + treino_familia + montra(v1)
-- Nota: 002 recria ytb_consentir_email e ytb_montra em v2 (a ordem importa).
-- ============================================================================

-- ─────────── gestao_perfis.sql ───────────
-- ============================================================================
-- YourTalentBase · GESTÃO DE PAPÉIS (perfis)
-- ----------------------------------------------------------------------------
-- Permite ao ADMIN atribuir um papel a um utilizador. O papel é o que destranca
-- as features: scout (observar/descobrir), treinador (acompanhar), familia,
-- admin. Sem isto, os papéis só se metiam por SQL à mão.
--
-- Modelo: o admin atribui por EMAIL (mesmo antes da pessoa entrar). Quando essa
-- pessoa fizer login (Supabase Auth) com esse email, já tem o papel.
-- Gate: SÓ quem já é admin pode atribuir papéis. Tudo validado.
-- Corre depois de ciclo1/2 (precisa da tabela perfis).
-- ============================================================================

-- ── Atribuir / mudar o papel de um utilizador ───────────────────────────────
create or replace function public.ytb_definir_papel(p_email text, p_papel text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_admin text; v_alvo text; v_papel text;
begin
  v_admin := auth.jwt() ->> 'email';
  if not exists (select 1 from public.perfis where lower(email) = lower(v_admin) and papel = 'admin') then
    return jsonb_build_object('status','negado','motivo','só o admin pode atribuir papéis');
  end if;

  v_papel := lower(trim(coalesce(p_papel,'')));
  if v_papel not in ('scout','treinador','familia','admin') then
    return jsonb_build_object('status','erro','motivo','papel inválido (scout/treinador/familia/admin)');
  end if;

  v_alvo := lower(trim(coalesce(p_email,'')));
  if v_alvo = '' or position('@' in v_alvo) = 0 then
    return jsonb_build_object('status','erro','motivo','email inválido');
  end if;

  -- upsert sem depender de constraint única em perfis.email
  if exists (select 1 from public.perfis where lower(email) = v_alvo) then
    update public.perfis set papel = v_papel where lower(email) = v_alvo;
  else
    insert into public.perfis(email, papel) values (v_alvo, v_papel);
  end if;

  return jsonb_build_object('status','ok','email',v_alvo,'papel',v_papel);
end $$;

grant execute on function public.ytb_definir_papel(text, text) to authenticated;

-- ── Listar os perfis (para a interface do admin) ────────────────────────────
create or replace function public.ytb_listar_perfis()
returns table(email text, nome text, papel text)
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.perfis where lower(perfis.email) = lower(auth.jwt() ->> 'email') and perfis.papel = 'admin') then
    raise exception 'só o admin pode listar perfis' using errcode = '42501';
  end if;
  return query select p.email, p.nome, p.papel from public.perfis p order by p.papel, p.email;
end $$;

grant execute on function public.ytb_listar_perfis() to authenticated;

-- ─────────── inscricao_livre.sql ───────────
-- ============================================================
-- INSCRIÇÃO LIVRE (grátis) — atletas / pais inscrevem-se a si próprios
-- Perfil básico, entra em 'pendente' para revisão do Admin.
-- ZeroZero obrigatório (lado do servidor) = detetor de inventados.
-- Chamável por anónimos (a RLS é contornada pela security definer).
-- ============================================================
create or replace function public.ytb_inscrever_livre(
  p_nome text,
  p_ano int,
  p_posicao text,
  p_clube text,
  p_associacao text,
  p_zerozero text,
  p_contacto text
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if coalesce(trim(p_nome),'') = '' then
    return jsonb_build_object('ok',false,'motivo','nome');
  end if;
  -- anti-inventados: exige um perfil real em zerozero.pt
  if p_zerozero is null or p_zerozero !~* 'zerozero\.pt/\S' then
    return jsonb_build_object('ok',false,'motivo','zerozero');
  end if;

  insert into public.atletas_360(
    id, nome, primeiro_nome, ano_nascimento, escalao,
    associacao, posicao_principal, clube_actual, zerozero_url,
    estado, visivel_b2b, visivel_publico,
    fonte, fonte_nome, fonte_email, encarregado_email
  ) values (
    gen_random_uuid(), trim(p_nome), split_part(trim(p_nome),' ',1),
    p_ano,
    case when p_ano is not null and p_ano > 2000
         then 'Sub-'||(extract(year from now())::int - p_ano) else null end,
    nullif(trim(p_associacao),''), nullif(trim(p_posicao),''),
    nullif(trim(p_clube),''), trim(p_zerozero),
    'pendente', false, false,
    'auto', 'Auto-inscrição',
    lower(nullif(trim(p_contacto),'')), lower(nullif(trim(p_contacto),''))
  ) returning id into v_id;

  return jsonb_build_object('ok',true,'id',v_id);
end $$;

grant execute on function public.ytb_inscrever_livre(text,int,text,text,text,text,text) to anon, authenticated;

-- ─────────── fase7_scouting360.sql ───────────
-- ============================================================================
-- YourTalentBase · FASE 7 · SCOUTING360 — MOTOR DE DESCOBERTA
-- ----------------------------------------------------------------------------
-- Deixa de ser uma lista. Ordena por TRAJETÓRIA, não por popularidade.
-- RGPD: só aparecem atletas com consentimento B2B (visivel_b2b + consentido).
-- Gate: clube (subscritor) / scout / admin. Corre depois de ciclo1/2/passaporte.
-- ============================================================================

create or replace function public.ytb_scouting360(p_ordenar text default 'evolucao', p_limit int default 50)
returns table(
  atleta_id          uuid,
  nome               text,
  posicao            text,
  clube              text,
  escalao            text,
  foto               text,
  evolucao_pct       numeric,
  treinabilidade     numeric,
  compromisso        numeric,
  consistencia       numeric,
  nivel_competitivo  numeric,
  nivel_verificacao  text,
  observadores       bigint,
  eventos            bigint,
  epocas             bigint
)
language plpgsql security definer set search_path = public as $$
begin
  -- só clube/scout/admin pode descobrir
  if not exists (
    select 1 from public.perfis pf
    where pf.email = auth.jwt() ->> 'email' and pf.papel in ('clube','scout','admin')
  ) then
    raise exception 'sem permissão para descoberta' using errcode = '42501';
  end if;

  return query
  select a.id, a.nome, a.posicao_principal, a.clube_actual, a.escalao, a.foto_path,
    p.evolucao_pct::numeric, p.treinabilidade::numeric, p.compromisso::numeric,
    p.consistencia::numeric, p.nivel_competitivo::numeric, p.nivel_verificacao,
    (select count(distinct e.fonte) from public.atleta_eventos e where e.atleta_id = a.id and e.origem = 'observado'),
    (select count(*) from public.atleta_eventos e where e.atleta_id = a.id),
    (select count(distinct date_part('year', e.criado_em)) from public.atleta_eventos e where e.atleta_id = a.id)
  from public.atletas_360 a
  join public.atleta_passaporte p on p.atleta_id = a.id
  -- RGPD: só atletas cuja família consentiu visibilidade B2B
  where a.visivel_b2b = true and a.consentido_em is not null and a.estado = 'aprovado'
    and coalesce(a.oculto_pelo_responsavel, false) = false
  order by
    case p_ordenar
      when 'evolucao'       then p.evolucao_pct::numeric
      when 'treinabilidade' then p.treinabilidade::numeric
      when 'compromisso'    then p.compromisso::numeric
      when 'consistencia'   then p.consistencia::numeric
      when 'observados'     then (select count(distinct e.fonte) from public.atleta_eventos e where e.atleta_id = a.id and e.origem = 'observado')::numeric
      when 'verificados'    then (select count(distinct e.fonte) from public.atleta_eventos e where e.atleta_id = a.id and e.origem = 'observado' and e.tipo = 'avaliacao')::numeric
      when 'densidade'      then (select count(*) from public.atleta_eventos e where e.atleta_id = a.id)::numeric
      else p.evolucao_pct::numeric
    end desc nulls last
  limit p_limit;
end $$;

grant execute on function public.ytb_scouting360(text, int) to authenticated;

-- ─────────── scout_relatorios_plafond.sql ───────────
-- ============================================================
-- SCOUT REPORT — PLAFOND DE RELATÓRIOS EM PDF
-- Modelo: 39,90€ = 3 relatórios exportáveis em PDF (recarregável).
--   • scout_plafond  → créditos comprados por scout (email)
--   • scout_relatorios → registo de cada PDF gerado (= 1 crédito gasto)
--   restantes = créditos - relatórios gerados
-- RPCs (security definer, RLS fechada por baixo):
--   ytb_scout_plafond()                  → {creditos, usados, restantes}
--   ytb_scout_gerar(atleta, nome)        → consome 1 e regista, ou recusa
--   ytb_scout_creditar(email, n)         → ADMIN credita +n (após pagamento)
-- ============================================================

create table if not exists public.scout_plafond (
  email        text primary key,
  creditos     int  not null default 0,
  criado_em    timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create table if not exists public.scout_relatorios (
  id           uuid primary key default gen_random_uuid(),
  scout_email  text not null,
  atleta_id    uuid references public.atletas_360(id) on delete set null,
  atleta_nome  text,
  criado_em    timestamptz not null default now()
);
create index if not exists idx_scout_rel_email on public.scout_relatorios(scout_email);

-- RLS fechada: acesso só pelas RPCs (security definer)
alter table public.scout_plafond enable row level security;
alter table public.scout_relatorios enable row level security;

-- ---------- ler o plafond do scout autenticado ----------
create or replace function public.ytb_scout_plafond()
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_email text; v_cred int; v_uso int;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return jsonb_build_object('creditos',0,'usados',0,'restantes',0); end if;
  select coalesce(creditos,0) into v_cred from public.scout_plafond where email = v_email;
  v_cred := coalesce(v_cred,0);
  select count(*) into v_uso from public.scout_relatorios where scout_email = v_email;
  return jsonb_build_object('creditos',v_cred,'usados',v_uso,'restantes',greatest(v_cred - v_uso,0));
end $$;

-- ---------- consumir 1 crédito e registar o relatório ----------
create or replace function public.ytb_scout_gerar(p_atleta uuid, p_nome text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_email text; v_cred int; v_uso int; v_rest int; v_id uuid;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return jsonb_build_object('ok',false,'motivo','sem_sessao','restantes',0); end if;

  select coalesce(creditos,0) into v_cred from public.scout_plafond where email = v_email;
  v_cred := coalesce(v_cred,0);
  select count(*) into v_uso from public.scout_relatorios where scout_email = v_email;
  v_rest := v_cred - v_uso;

  if v_rest <= 0 then
    return jsonb_build_object('ok',false,'motivo','sem_creditos','restantes',0);
  end if;

  insert into public.scout_relatorios(scout_email, atleta_id, atleta_nome)
  values (v_email, p_atleta, p_nome)
  returning id into v_id;

  return jsonb_build_object('ok',true,'ref',v_id,'restantes',v_rest - 1);
end $$;

-- ---------- ADMIN: creditar +n relatórios a um scout ----------
create or replace function public.ytb_scout_creditar(p_email text, p_n int default 3)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_admin text; v_email text; v_cred int;
begin
  v_admin := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_admin not in ('ipedronmartins@gmail.com','yourtalentbase@gmail.com')
     and not exists (select 1 from public.perfis p
                      where lower(p.email)=v_admin and p.papel='admin' and p.estado='aprovado')
  then
    return jsonb_build_object('ok',false,'motivo','sem_permissao');
  end if;

  v_email := lower(coalesce(p_email,''));
  if v_email = '' then return jsonb_build_object('ok',false,'motivo','email_invalido'); end if;

  insert into public.scout_plafond(email, creditos) values (v_email, greatest(p_n,0))
  on conflict (email) do update set creditos = public.scout_plafond.creditos + greatest(p_n,0),
                                    atualizado_em = now()
  returning creditos into v_cred;

  return jsonb_build_object('ok',true,'email',v_email,'creditos',v_cred);
end $$;

grant execute on function public.ytb_scout_plafond() to authenticated;
grant execute on function public.ytb_scout_gerar(uuid, text) to authenticated;
grant execute on function public.ytb_scout_creditar(text, int) to authenticated;

-- ─────────── ytb_passaporte_admin.sql ───────────
-- ============================================================
-- VER PASSAPORTE (ADMIN)
-- Abre QUALQUER passaporte a partir do painel, por ID de atleta.
-- Retrato idêntico ao ytb_passaporte(token), mas:
--   • entra pelo ID do atleta (não precisa de token de família)
--   • só responde a ADMINS autenticados (emails-mestre ou perfil admin aprovado)
-- NÃO altera a função da família (ytb_passaporte) — é segura e aditiva.
-- ============================================================
create or replace function public.ytb_passaporte_admin(p_atleta uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_atleta uuid := p_atleta; j jsonb; v_email text;
begin
  -- porta de admin: só emails-mestre OU perfil com papel admin aprovado
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email not in ('ipedronmartins@gmail.com', 'yourtalentbase@gmail.com')
     and not exists (
       select 1 from public.perfis p
        where lower(p.email) = v_email and p.papel = 'admin' and p.estado = 'aprovado')
  then
    return null;                                   -- sem permissão de admin
  end if;

  if v_atleta is null then
    return null;
  end if;

  select jsonb_build_object(
    'identidade', jsonb_build_object(
      'nome', a.nome, 'posicao', a.posicao_principal, 'clube', a.clube_actual,
      'escalao', a.escalao, 'associacao', a.associacao,
      'foto', (case when coalesce(a.foto_consentida,false) then a.foto_path else null end)),

    'indicadores', (select to_jsonb(p) - 'atleta_id'
                    from public.atleta_passaporte p where p.atleta_id = v_atleta),

    'densidade', jsonb_build_object(
      'eventos',      (select count(*) from public.atleta_eventos e where e.atleta_id = v_atleta),
      'avaliacoes',   (select count(*) from public.atleta_eventos e where e.atleta_id = v_atleta and e.tipo = 'avaliacao'),
      'observadores', (select count(distinct e.fonte) from public.atleta_eventos e where e.atleta_id = v_atleta and e.origem = 'observado'),
      'epocas',       (select count(distinct date_part('year', e.criado_em)) from public.atleta_eventos e where e.atleta_id = v_atleta)),

    'evolucao_serie', (
      select coalesce(jsonb_agg(jsonb_build_object(
               't', av.created_at,
               'v', round(coalesce(public.ytb_num(av.rating), (coalesce(public.ytb_num(av.dim_treinabilidade),0)+coalesce(public.ytb_num(av.dim_compromisso),0))/2.0) * 20)
             ) order by av.created_at), '[]'::jsonb)
      from public.atletas_360_avaliacoes av where av.atleta_id = v_atleta),

    'marcos', (
      select coalesce(jsonb_agg(jsonb_build_object('titulo', e.titulo, 'em', e.criado_em)
                      order by e.criado_em desc), '[]'::jsonb)
      from public.atleta_eventos e where e.atleta_id = v_atleta and e.categoria = 'marco'),

    'carreira', (
      select coalesce(jsonb_agg(jsonb_build_object('epoca', h.epoca) order by h.created_at desc), '[]'::jsonb)
      from public.atletas_360_historico h where h.atleta_id = v_atleta),

    'timeline', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select jsonb_build_object(
                 'categoria', e.categoria, 'origem', e.origem, 'titulo', e.titulo,
                 'fonte', e.fonte, 'em', e.criado_em, 'impacto', e.impacto) as t
        from public.atleta_eventos e where e.atleta_id = v_atleta
        order by e.relevancia desc nulls last, e.criado_em desc
        limit 12) s),

    'atividade', jsonb_build_object(
      'prescritos', (select coalesce(sum(coalesce((t.plano->>'sessoes')::int,1)),0) from public.treinador_treinos t where t.atleta_id = v_atleta),
      'concluidos', (select count(*) from public.familia_treinos f where f.atleta_id = v_atleta and f.prescrito_id is not null),
      'execucoes',  (select count(*) from public.familia_treinos f where f.atleta_id = v_atleta),
      'ultima',     (select max(f.created_at) from public.familia_treinos f where f.atleta_id = v_atleta),
      'semanas_ativas', (select count(distinct date_trunc('week', f.created_at)) from public.familia_treinos f where f.atleta_id = v_atleta)),

    'cognitivo', jsonb_build_object(
      'total',      (select count(*) from public.elite_coach_resultados r where r.atleta_id = v_atleta),
      'acerto_pct', (select round(100.0*avg((r.correto)::int)) from public.elite_coach_resultados r where r.atleta_id = v_atleta),
      'por_tipo', (select coalesce(jsonb_agg(jsonb_build_object('cenario',t.cenario,'total',t.total,'acerto_pct',t.acerto) order by t.total desc),'[]'::jsonb)
                   from (select coalesce(cenario_id,'—') cenario, count(*) total, round(100.0*avg((correto)::int)) acerto
                         from public.elite_coach_resultados where atleta_id=v_atleta group by coalesce(cenario_id,'—')) t),
      'serie', (select coalesce(jsonb_agg(jsonb_build_object('t',m.mes,'v',m.acerto) order by m.mes),'[]'::jsonb)
                from (select date_trunc('month',created_at) mes, round(100.0*avg((correto)::int)) acerto
                      from public.elite_coach_resultados where atleta_id=v_atleta group by date_trunc('month',criado_em)) m)),

    'relatorios', (
      select coalesce(jsonb_agg(jsonb_build_object('fonte', e.fonte, 'titulo', e.titulo, 'em', e.criado_em) order by e.criado_em desc), '[]'::jsonb)
      from public.atleta_eventos e where e.atleta_id = v_atleta and e.origem = 'observado' and e.tipo = 'avaliacao'),

    'media', jsonb_build_object(
      'video',   (select case when coalesce(a2.video_consentido,false) then a2.video_path else null end from public.atletas_360 a2 where a2.id = v_atleta),
      'galeria', '[]'::jsonb)
  ) into j
  from public.atletas_360 a where a.id = v_atleta;

  return j;
end $$;

grant execute on function public.ytb_passaporte_admin(uuid) to authenticated;

-- ─────────── passaporte_familia_email.sql ───────────
-- ============================================================
-- ACESSO DA FAMÍLIA POR MAGIC LINK
-- O email da inscrição (encarregado_email) é a ÚNICA chave.
-- A sessão do Supabase Auth (signInWithOtp) já É o "token" —
-- não há ID nem PIN nem link com token embebido.
--
-- Regra de ouro: cada RPC verifica auth.jwt() email contra
-- encarregado_email NA BASE DE DADOS. Nunca confiar no cliente.
--
--   ytb_meus_atletas()              → lista os atletas do email autenticado
--   ytb_passaporte_email(atleta)    → passaporte completo, SÓ se o email é o encarregado
--   ytb_consentir_email(atleta,v)   → consentimento, SÓ se o email é o encarregado
-- ============================================================

-- ---------- listar os atletas do encarregado autenticado ----------
create or replace function public.ytb_meus_atletas()
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return '[]'::jsonb; end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', a.id, 'nome', a.nome, 'escalao', a.escalao,
             'clube', a.clube_actual, 'consentido', (a.consentido_em is not null)
           ) order by a.nome)
    from public.atletas_360 a
    where lower(coalesce(a.encarregado_email,'')) = v_email
  ), '[]'::jsonb);
end $$;

-- ---------- abrir o passaporte — só se o email autenticado é o encarregado deste atleta ----------
create or replace function public.ytb_passaporte_email(p_atleta uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_atleta uuid; v_email text; j jsonb;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return null; end if;

  select a.id into v_atleta
    from public.atletas_360 a
   where a.id = p_atleta and lower(coalesce(a.encarregado_email,'')) = v_email
   limit 1;

  if v_atleta is null then
    return null;     -- este email não é o encarregado deste atleta — acesso negado
  end if;

  select jsonb_build_object(
    'identidade', jsonb_build_object(
      'nome', a.nome, 'posicao', a.posicao_principal, 'clube', a.clube_actual,
      'escalao', a.escalao, 'associacao', a.associacao,
      'foto', (case when coalesce(a.foto_consentida,false) then a.foto_path else null end)),

    'indicadores', (select to_jsonb(p) - 'atleta_id'
                    from public.atleta_passaporte p where p.atleta_id = v_atleta),

    'densidade', jsonb_build_object(
      'eventos',      (select count(*) from public.atleta_eventos e where e.atleta_id = v_atleta),
      'avaliacoes',   (select count(*) from public.atleta_eventos e where e.atleta_id = v_atleta and e.tipo = 'avaliacao'),
      'observadores', (select count(distinct e.fonte) from public.atleta_eventos e where e.atleta_id = v_atleta and e.origem = 'observado'),
      'epocas',       (select count(distinct date_part('year', e.criado_em)) from public.atleta_eventos e where e.atleta_id = v_atleta)),

    'evolucao_serie', (
      select coalesce(jsonb_agg(jsonb_build_object(
               't', av.created_at,
               'v', round(coalesce(public.ytb_num(av.rating), (coalesce(public.ytb_num(av.dim_treinabilidade),0)+coalesce(public.ytb_num(av.dim_compromisso),0))/2.0) * 20)
             ) order by av.created_at), '[]'::jsonb)
      from public.atletas_360_avaliacoes av where av.atleta_id = v_atleta),

    'marcos', (
      select coalesce(jsonb_agg(jsonb_build_object('titulo', e.titulo, 'em', e.criado_em)
                      order by e.criado_em desc), '[]'::jsonb)
      from public.atleta_eventos e where e.atleta_id = v_atleta and e.categoria = 'marco'),

    'carreira', (
      select coalesce(jsonb_agg(jsonb_build_object('epoca', h.epoca) order by h.created_at desc), '[]'::jsonb)
      from public.atletas_360_historico h where h.atleta_id = v_atleta),

    'timeline', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select jsonb_build_object(
                 'categoria', e.categoria, 'origem', e.origem, 'titulo', e.titulo,
                 'fonte', e.fonte, 'em', e.criado_em, 'impacto', e.impacto) as t
        from public.atleta_eventos e where e.atleta_id = v_atleta
        order by e.relevancia desc nulls last, e.criado_em desc
        limit 12) s),

    'atividade', jsonb_build_object(
      'prescritos', (select coalesce(sum(coalesce((t.plano->>'sessoes')::int,1)),0) from public.treinador_treinos t where t.atleta_id = v_atleta),
      'concluidos', (select count(*) from public.familia_treinos f where f.atleta_id = v_atleta and f.prescrito_id is not null),
      'execucoes',  (select count(*) from public.familia_treinos f where f.atleta_id = v_atleta),
      'ultima',     (select max(f.created_at) from public.familia_treinos f where f.atleta_id = v_atleta),
      'semanas_ativas', (select count(distinct date_trunc('week', f.created_at)) from public.familia_treinos f where f.atleta_id = v_atleta)),

    'cognitivo', jsonb_build_object(
      'total',      (select count(*) from public.elite_coach_resultados r where r.atleta_id = v_atleta),
      'acerto_pct', (select round(100.0*avg((r.correto)::int)) from public.elite_coach_resultados r where r.atleta_id = v_atleta),
      'por_tipo', (select coalesce(jsonb_agg(jsonb_build_object('cenario',t.cenario,'total',t.total,'acerto_pct',t.acerto) order by t.total desc),'[]'::jsonb)
                   from (select coalesce(cenario_id,'—') cenario, count(*) total, round(100.0*avg((correto)::int)) acerto
                         from public.elite_coach_resultados where atleta_id=v_atleta group by coalesce(cenario_id,'—')) t),
      'serie', (select coalesce(jsonb_agg(jsonb_build_object('t',m.mes,'v',m.acerto) order by m.mes),'[]'::jsonb)
                from (select date_trunc('month',created_at) mes, round(100.0*avg((correto)::int)) acerto
                      from public.elite_coach_resultados where atleta_id=v_atleta group by date_trunc('month',criado_em)) m)),

    'relatorios', (
      select coalesce(jsonb_agg(jsonb_build_object('fonte', e.fonte, 'titulo', e.titulo, 'em', e.criado_em) order by e.criado_em desc), '[]'::jsonb)
      from public.atleta_eventos e where e.atleta_id = v_atleta and e.origem = 'observado' and e.tipo = 'avaliacao'),

    'media', jsonb_build_object(
      'video',   (select case when coalesce(a2.video_consentido,false) then a2.video_path else null end from public.atletas_360 a2 where a2.id = v_atleta),
      'galeria', '[]'::jsonb)
  ) into j
  from public.atletas_360 a where a.id = v_atleta;

  return j;
end $$;

-- ---------- consentir — só se o email autenticado é o encarregado deste atleta ----------
-- Espelha o ytb_consentir(token) existente (mesmos efeitos: aprova o atleta,
-- torna visível, regista o evento de auditoria), mas com o email como chave.
create or replace function public.ytb_consentir_email(p_atleta uuid, p_versao text default 'v1')
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_nome text; v_ja boolean; v_email text;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return jsonb_build_object('ok',false,'motivo','sem_sessao'); end if;

  select a.id, a.nome, (a.consentido_em is not null)
    into v_id, v_nome, v_ja
    from public.atletas_360 a
   where a.id = p_atleta and lower(coalesce(a.encarregado_email,'')) = v_email
   limit 1;

  if v_id is null then
    return jsonb_build_object('ok',false,'motivo','nao_autorizado');  -- este email não é o encarregado deste atleta
  end if;

  if not v_ja then
    update public.atletas_360
       set consentido_em        = now(),
           consentido_por       = v_email,
           versao_consentimento = p_versao,
           estado               = 'aprovado',
           visivel_b2b          = true
     where id = v_id;

    insert into public.atleta_eventos
      (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia,
       ref_tabela, ref_id, payload, criado_em)
    values
      (v_id, 'consentimento', 'marco', 'Consentimento do encarregado',
       'encarregado', 'sistema', 5,
       'consentimento', v_id::text,
       jsonb_build_object('versao', p_versao, 'por', v_email),
       now())
    on conflict (ref_tabela, ref_id) where ref_id is not null do nothing;
  end if;

  return jsonb_build_object('ok',true,'id',v_id,'nome',v_nome,'ja_consentido',v_ja);
end $$;

grant execute on function public.ytb_meus_atletas() to authenticated;
grant execute on function public.ytb_passaporte_email(uuid) to authenticated;
grant execute on function public.ytb_consentir_email(uuid, text) to authenticated;

-- ─────────── treino_familia.sql ───────────
-- ============================================================
-- TREINO DA FAMÍLIA — o miúdo vê o plano, faz, e dá feedback.
-- Tudo autenticado por EMAIL (encarregado): só o dono do atleta
-- vê o plano e só ele grava feedback.
--
--   ytb_plano_atual(atleta)                         → plano mais recente
--   ytb_treino_feedback(atleta,prescrito,sem,ses,conf,txt) → grava sessão feita
--
-- Colunas de feedback garantidas (aditivo, não mexe no que existe).
-- ============================================================

alter table public.familia_treinos add column if not exists feedback text;
alter table public.familia_treinos add column if not exists semana   int;
alter table public.familia_treinos add column if not exists sessao   int;

-- ---------- plano de treino atual do atleta (só o encarregado) ----------
create or replace function public.ytb_plano_atual(p_atleta uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_email text; v_id uuid; v_plano jsonb; v_em timestamptz;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return null; end if;

  -- porta: este email tem de ser o encarregado deste atleta
  if not exists (
    select 1 from public.atletas_360 a
     where a.id = p_atleta and lower(coalesce(a.encarregado_email,'')) = v_email
  ) then
    return null;
  end if;

  select t.id, t.plano, t.criado_em
    into v_id, v_plano, v_em
    from public.treinador_treinos t
   where t.atleta_id = p_atleta
   order by t.criado_em desc
   limit 1;

  if v_id is null then
    return jsonb_build_object('tem', false);
  end if;

  -- quais sessões (semana/sessão) já foram marcadas como feitas — para o ecrã saber o que falta
  return jsonb_build_object(
    'tem', true,
    'prescrito_id', v_id,
    'criado_em', v_em,
    'plano', v_plano,
    'feitas', (
      select coalesce(jsonb_agg(distinct jsonb_build_object('semana', f.semana, 'sessao', f.sessao)), '[]'::jsonb)
      from public.familia_treinos f
      where f.atleta_id = p_atleta and f.prescrito_id = v_id and f.semana is not null
    )
  );
end $$;

-- ---------- feedback da família: marca uma sessão como feita (só o encarregado) ----------
create or replace function public.ytb_treino_feedback(
  p_atleta uuid, p_prescrito_id uuid,
  p_semana int, p_sessao int,
  p_confianca int, p_feedback text
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return jsonb_build_object('ok', false, 'motivo', 'sem_sessao'); end if;

  if not exists (
    select 1 from public.atletas_360 a
     where a.id = p_atleta and lower(coalesce(a.encarregado_email,'')) = v_email
  ) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;

  insert into public.familia_treinos
    (atleta_id, prescrito_id, confianca, semana, sessao, feedback, created_at)
  values
    (p_atleta, p_prescrito_id,
     case when p_confianca between 1 and 5 then p_confianca else null end,
     p_semana, p_sessao, nullif(trim(p_feedback), ''), now());

  return jsonb_build_object('ok', true);
end $$;

grant execute on function public.ytb_plano_atual(uuid) to authenticated;
grant execute on function public.ytb_treino_feedback(uuid, uuid, int, int, int, text) to authenticated;

-- ─────────── montra_publica.sql ───────────
-- ============================================================
-- MONTRA PÚBLICA — listagem aberta de atletas (sem login)
-- O funil: um scout tropeça na montra → regista-se para ver o resto.
--
-- PRIVACIDADE (são menores): devolve SÓ campos semi-públicos
-- (nome, posição, escalão, clube, indicador de rating). NUNCA
-- contactos, debilidades, email, nem o passaporte completo.
-- Só aparece quem tem visivel_publico = true E já consentiu.
-- Chamável por anónimos.
-- ============================================================
create or replace function public.ytb_montra()
returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'nome',    a.nome,
             'posicao', a.posicao_principal,
             'escalao', a.escalao,
             'clube',   a.clube_actual,
             'rating',  a.rating_geral
           ) order by a.nome)
    from public.atletas_360 a
    where coalesce(a.visivel_publico, false) = true
      and a.consentido_em is not null
  ), '[]'::jsonb);
end $$;

grant execute on function public.ytb_montra() to anon, authenticated;
