-- ============================================================================
-- MIGRAÇÃO 018 · SCOUT CRIA ATLETAS · PASSAPORTE COMO CENTRO · FIXES DE QA
-- Adenda do fundador: o scout deixa de só observar — cria atletas, e o
-- Passaporte Digital nasce automaticamente (atleta+biometria+1º report numa
-- só transação). Convergência: família/treinador/scout/admin escrevem no
-- MESMO atletas_360, nunca duplicado (dedupe por nome+ano antes de criar).
--
-- Fix crítico de QA (screenshot do fundador): admin não conseguia eliminar
-- atletas — "null value in column atleta_id... violates not-null constraint".
-- Causa: atleta_eventos_atleta_id_fkey era ON DELETE SET NULL, mas a 007
-- tornou atleta_id NOT NULL. Todo atleta com eventos (todos — a inscrição
-- já emite um) ficava inapagável. Corrigido para ON DELETE CASCADE: apagar
-- o atleta apaga o seu livro (direito ao apagamento; a imutabilidade do
-- livro protege contra adulteração enquanto existe, não contra remoção
-- legalmente exigida — para preservar sem apagar existe "arquivar").
--
-- Descoberta adicional: posicao_principal é NOT NULL + CHECK fechado às 11
-- siglas, sem placeholder possível — o rótulo "(opcional)" nos formulários
-- de treinador/inscrição livre sempre esteve errado. Alinhado aqui
-- (RPCs passam a exigir posição real); rótulos corrigidos nas Fases 2/4.
--
-- Validada em dry-run transacional (2026-07-04): 30 asserções — dedupe,
-- associar sem duplicar, confirmar cria mesmo assim, atleta+biometria+
-- report na mesma transação com 3 eventos automáticos, isolamento entre
-- scouts (leitura/escrita/passaporte), admin biometria + guardar alargado,
-- fluxos existentes de treinador/inscrição livre continuam a funcionar e
-- corretamente exigem posição, "o que mudou" distingue plano novo de
-- atualizado, e o fix do apagar confirmado (9 eventos → apagar → 0).
-- ============================================================================

alter table public.atleta_eventos drop constraint atleta_eventos_atleta_id_fkey;
alter table public.atleta_eventos add constraint atleta_eventos_atleta_id_fkey
  foreign key (atleta_id) references public.atletas_360(id) on delete cascade;

alter table public.atletas_360 add column if not exists sexo text
  check (sexo is null or sexo in ('M','F'));

drop function if exists public.ytb_treinador_inscrever(text,int,text,text,text,text,text);
drop function if exists public.ytb_inscrever_livre(text,int,text,text,text,text,text);

create or replace function public._ytb_e_scout()
returns boolean language sql security definer set search_path = public as $$
  select exists (
    select 1 from public.perfis p
     where lower(p.email) = lower(coalesce(auth.jwt()->>'email',''))
       and p.papel = 'scout' and coalesce(p.estado,'aprovado') = 'aprovado')
$$;
revoke execute on function public._ytb_e_scout() from public, anon, authenticated;

create or replace function public._ytb_pe_norm(p text)
returns text language sql immutable as $$
  select case when p in ('D','E','A') then p
              when p = 'Direito' then 'D'
              when p = 'Esquerdo' then 'E'
              when p in ('Ambidextro','Ambidestro') then 'A'
              else null end
$$;

create or replace function public._ytb_escalao_de(p_escalao text, p_ano int)
returns text language sql immutable as $$
  select coalesce(nullif(trim(p_escalao),''),
                  case when p_ano > 2000 then 'Sub-'||(extract(year from now())::int - p_ano)
                       else 'Sénior' end)
$$;

create or replace function public.ytb_scout_atleta_criar(
  p_nome text, p_ano int, p_mes int default null, p_dia int default null,
  p_sexo text default null, p_nacionalidade text default null,
  p_clube text default null, p_escalao text default null,
  p_pos text default null, p_pe text default null,
  p_assoc text default null, p_esquema text default null,
  p_altura numeric default null, p_peso numeric default null,
  p_zz text default null, p_video text default null,
  p_email_enc text default null,
  p_report jsonb default null,
  p_confirmar_novo boolean default false,
  p_associar_a uuid default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_email text; v_nome_scout text; v_id uuid; v_rep uuid; v_cand jsonb;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or public._ytb_e_scout()) then
    return jsonb_build_object('ok',false,'motivo','sem_papel_scout');
  end if;
  if coalesce(trim(p_nome),'') = '' then
    return jsonb_build_object('ok',false,'motivo','nome');
  end if;
  if p_ano is null or p_ano < 1990 or p_ano > extract(year from now())::int then
    return jsonb_build_object('ok',false,'motivo','ano_invalido');
  end if;
  if p_pos is null or p_pos not in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then
    return jsonb_build_object('ok',false,'motivo','posicao_obrigatoria');
  end if;
  if coalesce(trim(p_clube),'') = '' then
    return jsonb_build_object('ok',false,'motivo','clube_obrigatorio');
  end if;
  if p_dia is not null and p_dia not between 1 and 31 then
    return jsonb_build_object('ok',false,'motivo','dia_invalido');
  end if;
  if p_mes is not null and p_mes not between 1 and 12 then
    return jsonb_build_object('ok',false,'motivo','mes_invalido');
  end if;
  if p_sexo is not null and p_sexo not in ('M','F') then
    return jsonb_build_object('ok',false,'motivo','sexo_invalido');
  end if;
  if p_zz is not null and trim(p_zz) <> '' and p_zz !~* 'zerozero\.pt/\S' then
    return jsonb_build_object('ok',false,'motivo','zerozero_invalido');
  end if;
  if p_email_enc is not null and trim(p_email_enc) <> '' and position('@' in p_email_enc) = 0 then
    return jsonb_build_object('ok',false,'motivo','email_encarregado_invalido');
  end if;
  if p_altura is not null and p_altura not between 80 and 220 then
    return jsonb_build_object('ok',false,'motivo','altura_invalida');
  end if;
  if p_peso is not null and p_peso not between 15 and 120 then
    return jsonb_build_object('ok',false,'motivo','peso_invalido');
  end if;

  if p_associar_a is not null then
    if not exists (select 1 from public.atletas_360 where id = p_associar_a) then
      return jsonb_build_object('ok',false,'motivo','atleta_inexistente');
    end if;
    return jsonb_build_object('ok',true,'id',p_associar_a,'associado',true);
  end if;

  if not p_confirmar_novo then
    select jsonb_agg(jsonb_build_object('id',a.id,'nome',a.nome,
             'ano',a.ano_nascimento,'clube',a.clube_actual))
      into v_cand
      from (select * from public.atletas_360
             where (nome ilike '%'||trim(p_nome)||'%' or trim(p_nome) ilike '%'||nome||'%')
               and (ano_nascimento is null or ano_nascimento = p_ano)
               and coalesce(estado,'') <> 'arquivado'
             limit 5) a;
    if v_cand is not null then
      return jsonb_build_object('ok',false,'motivo','duplicado_possivel','candidatos',v_cand);
    end if;
  end if;

  select nome into v_nome_scout from public.perfis where lower(email) = v_email;

  insert into public.atletas_360
    (nome, primeiro_nome, ano_nascimento, mes_nascimento, dia_nascimento,
     sexo, nacionalidade, escalao, associacao, posicao_principal, pe_dominante,
     clube_actual, zerozero_url, video_path, esquema_tatico,
     estado, visivel_b2b, visivel_publico,
     fonte, fonte_nome, fonte_email, encarregado_email)
  values
    (trim(p_nome), split_part(trim(p_nome),' ',1), p_ano, p_mes, p_dia,
     p_sexo, nullif(trim(p_nacionalidade),''),
     public._ytb_escalao_de(p_escalao, p_ano),
     coalesce(nullif(trim(p_assoc),''), 'Não filiado'),
     p_pos,
     public._ytb_pe_norm(p_pe),
     trim(p_clube), nullif(trim(p_zz),''), nullif(trim(p_video),''),
     nullif(trim(p_esquema),''),
     'aprovado', false, false,
     'scout', coalesce(v_nome_scout, v_email), v_email,
     lower(nullif(trim(p_email_enc),'')))
  returning id into v_id;

  if p_altura is not null or p_peso is not null then
    insert into public.atleta_biometria (atleta_id, altura_cm, peso_kg, fonte)
    values (v_id, p_altura, p_peso, 'scout');
    update public.atletas_360
       set altura_cm = coalesce(p_altura::int, altura_cm),
           peso_kg   = coalesce(p_peso::int,  peso_kg)
     where id = v_id;
  end if;

  if p_report is not null then
    insert into public.relatorios
      (scout, atleta, atleta_id, clube, categoria, posicao, epoca,
       scores, dados, report_data, relatorio_texto, decisao, rendimento, prazo, media_geral)
    values
      (coalesce(v_nome_scout, v_email), trim(p_nome), v_id,
       trim(p_clube),
       public._ytb_escalao_de(p_escalao, p_ano),
       p_pos, coalesce(p_report->>'epoca','2025/2026'),
       p_report->'scores', p_report->'dados', p_report->'dados',
       p_report->>'relatorio_texto', p_report->>'decisao',
       p_report->>'rendimento', p_report->>'prazo',
       (p_report->>'media_geral')::numeric)
    returning id into v_rep;
  end if;

  return jsonb_build_object('ok',true,'id',v_id,'report_id',v_rep);
end $$;

create or replace function public.ytb_treinador_inscrever(
  p_nome text, p_ano int, p_assoc text, p_pos text,
  p_clube text, p_zz text, p_email_enc text,
  p_dia_nasc int default null, p_mes_nasc int default null, p_esquema text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public.ytb_is_treinador() then
    return jsonb_build_object('ok',false,'motivo','sem_papel_treinador');
  end if;
  if coalesce(p_nome,'')='' or p_ano is null then
    return jsonb_build_object('ok',false,'motivo','dados_incompletos');
  end if;
  if p_pos is null or p_pos not in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then
    return jsonb_build_object('ok',false,'motivo','posicao_obrigatoria');
  end if;
  if coalesce(trim(p_clube),'') = '' then
    return jsonb_build_object('ok',false,'motivo','clube_obrigatorio');
  end if;
  if p_zz is null or p_zz !~* 'zerozero\.pt/\S' then
    return jsonb_build_object('ok',false,'motivo','zerozero_invalido');
  end if;
  if p_email_enc is null or position('@' in p_email_enc)=0 then
    return jsonb_build_object('ok',false,'motivo','email_encarregado_invalido');
  end if;
  if p_dia_nasc is not null and p_dia_nasc not between 1 and 31 then
    return jsonb_build_object('ok',false,'motivo','dia_invalido');
  end if;
  if p_mes_nasc is not null and p_mes_nasc not between 1 and 12 then
    return jsonb_build_object('ok',false,'motivo','mes_invalido');
  end if;

  insert into public.atletas_360
    (nome, primeiro_nome, ano_nascimento, mes_nascimento, dia_nascimento, escalao, associacao,
     posicao_principal, clube_actual, zerozero_url, esquema_tatico,
     estado, visivel_b2b, fonte, fonte_nome, fonte_email, encarregado_email)
  values
    (p_nome, split_part(p_nome,' ',1), p_ano, p_mes_nasc, p_dia_nasc,
     public._ytb_escalao_de(null, p_ano),
     coalesce(nullif(trim(p_assoc),''), 'Não filiado'),
     p_pos,
     trim(p_clube),
     p_zz, nullif(trim(p_esquema),''),
     'pendente', false, 'treinador',
     coalesce((select nome from public.perfis where lower(email)=v_email), v_email),
     v_email, lower(trim(p_email_enc)))
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;

create or replace function public.ytb_inscrever_livre(
  p_nome text, p_ano int, p_posicao text, p_clube text,
  p_associacao text, p_zerozero text, p_contacto text,
  p_dia_nasc int default null, p_mes_nasc int default null, p_esquema text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if coalesce(trim(p_nome),'')='' then
    return jsonb_build_object('ok',false,'motivo','nome');
  end if;
  if p_ano is null then
    return jsonb_build_object('ok',false,'motivo','ano');
  end if;
  if p_posicao is null or p_posicao not in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then
    return jsonb_build_object('ok',false,'motivo','posicao_obrigatoria');
  end if;
  if coalesce(trim(p_clube),'') = '' then
    return jsonb_build_object('ok',false,'motivo','clube_obrigatorio');
  end if;
  if p_zerozero is null or p_zerozero !~* 'zerozero\.pt/\S' then
    return jsonb_build_object('ok',false,'motivo','zerozero');
  end if;
  if p_dia_nasc is not null and p_dia_nasc not between 1 and 31 then
    return jsonb_build_object('ok',false,'motivo','dia_invalido');
  end if;
  if p_mes_nasc is not null and p_mes_nasc not between 1 and 12 then
    return jsonb_build_object('ok',false,'motivo','mes_invalido');
  end if;

  insert into public.atletas_360 (
    id, nome, primeiro_nome, ano_nascimento, mes_nascimento, dia_nascimento, escalao,
    associacao, posicao_principal, clube_actual, zerozero_url, esquema_tatico,
    estado, visivel_b2b, visivel_publico,
    fonte, fonte_nome, fonte_email, encarregado_email
  ) values (
    gen_random_uuid(), trim(p_nome), split_part(trim(p_nome),' ',1),
    p_ano, p_mes_nasc, p_dia_nasc,
    public._ytb_escalao_de(null, p_ano),
    coalesce(nullif(trim(p_associacao),''), 'Não filiado'),
    p_posicao,
    trim(p_clube),
    trim(p_zerozero), nullif(trim(p_esquema),''),
    'pendente', false, false,
    'auto', 'Auto-inscrição',
    coalesce(lower(nullif(trim(p_contacto),'')), 'sem-contacto@ytb.local'),
    lower(nullif(trim(p_contacto),''))
  ) returning id into v_id;

  return jsonb_build_object('ok',true,'id',v_id);
end $$;

create or replace function public.ytb_scout_meus_atletas()
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or public._ytb_e_scout()) then return null; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id',a.id,'nome',a.nome,'ano',a.ano_nascimento,
             'clube',a.clube_actual,'escalao',a.escalao,'posicao',a.posicao_principal,
             'estado',a.estado,'criado_em',a.created_at)
           order by a.created_at desc)
      from public.atletas_360 a
     where a.fonte = 'scout' and lower(coalesce(a.fonte_email,'')) = v_email
  ), '[]'::jsonb);
end $$;

create or replace function public._ytb_passaporte_json(v_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare j jsonb;
begin
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
                      from public.elite_coach_resultados where atleta_id=v_atleta group by date_trunc('month',created_at)) m)),
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
revoke execute on function public._ytb_passaporte_json(uuid) from public, anon, authenticated;

create or replace function public.ytb_passaporte_scout(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if public.ytb_is_admin() then
    return public._ytb_passaporte_json(p_atleta);
  end if;
  if not public._ytb_e_scout() then return null; end if;
  if not exists (select 1 from public.atletas_360 a
                  where a.id = p_atleta and a.fonte = 'scout'
                    and lower(coalesce(a.fonte_email,'')) = v_email) then
    return null;
  end if;
  return public._ytb_passaporte_json(p_atleta);
end $$;

create or replace function public.ytb_scout_atleta_editar(p_id uuid, p jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or public._ytb_e_scout()) then
    return jsonb_build_object('ok',false,'motivo','sem_papel_scout');
  end if;
  if not exists (select 1 from public.atletas_360 a
                  where a.id = p_id
                    and (public.ytb_is_admin()
                         or (a.fonte = 'scout' and lower(coalesce(a.fonte_email,'')) = v_email))) then
    return jsonb_build_object('ok',false,'motivo','nao_autorizado');
  end if;

  update public.atletas_360 set
    nome              = case when p ? 'nome' and coalesce(trim(p->>'nome'),'') <> '' then p->>'nome' else nome end,
    primeiro_nome     = case when p ? 'nome' and coalesce(trim(p->>'nome'),'') <> '' then split_part(p->>'nome',' ',1) else primeiro_nome end,
    ano_nascimento    = case when p ? 'ano_nascimento' and public.ytb_num(p->>'ano_nascimento') is not null then (public.ytb_num(p->>'ano_nascimento'))::int else ano_nascimento end,
    mes_nascimento    = case when p ? 'mes_nascimento' then (public.ytb_num(p->>'mes_nascimento'))::int else mes_nascimento end,
    dia_nascimento    = case when p ? 'dia_nascimento' then (public.ytb_num(p->>'dia_nascimento'))::int else dia_nascimento end,
    sexo              = case when p ? 'sexo' and (p->>'sexo') in ('M','F') then p->>'sexo' else sexo end,
    nacionalidade     = case when p ? 'nacionalidade' then p->>'nacionalidade' else nacionalidade end,
    posicao_principal = case when p ? 'posicao_principal' and (p->>'posicao_principal') in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then p->>'posicao_principal' else posicao_principal end,
    pe_dominante      = case when p ? 'pe_dominante' and public._ytb_pe_norm(p->>'pe_dominante') is not null then public._ytb_pe_norm(p->>'pe_dominante') else pe_dominante end,
    clube_actual      = case when p ? 'clube_actual' and coalesce(trim(p->>'clube_actual'),'') <> '' then p->>'clube_actual' else clube_actual end,
    equipa            = case when p ? 'equipa' then p->>'equipa' else equipa end,
    escalao           = case when p ? 'escalao' and coalesce(trim(p->>'escalao'),'') <> '' then p->>'escalao' else escalao end,
    associacao        = case when p ? 'associacao' and coalesce(trim(p->>'associacao'),'') <> '' then p->>'associacao' else associacao end,
    esquema_tatico    = case when p ? 'esquema_tatico' then p->>'esquema_tatico' else esquema_tatico end,
    zerozero_url      = case when p ? 'zerozero_url' then p->>'zerozero_url' else zerozero_url end,
    video_path        = case when p ? 'video_path' then p->>'video_path' else video_path end,
    encarregado_email = case when p ? 'encarregado_email' then lower(nullif(trim(p->>'encarregado_email'),'')) else encarregado_email end
  where id = p_id;

  insert into public.atleta_eventos (atleta_id, tipo, titulo, fonte, origem, relevancia, payload)
  values (p_id, 'atualizacao_scout', 'Ficha atualizada pelo scout', v_email, 'sistema', 1,
          jsonb_build_object('campos', (select jsonb_agg(k) from jsonb_object_keys(p) k)));
  return jsonb_build_object('ok',true);
end $$;

create or replace function public.ytb_scout_atleta_arquivar(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or public._ytb_e_scout()) then
    return jsonb_build_object('ok',false,'motivo','sem_papel_scout');
  end if;
  if not exists (select 1 from public.atletas_360 a
                  where a.id = p_id
                    and (public.ytb_is_admin()
                         or (a.fonte = 'scout' and lower(coalesce(a.fonte_email,'')) = v_email))) then
    return jsonb_build_object('ok',false,'motivo','nao_autorizado');
  end if;
  update public.atletas_360
     set estado = 'arquivado', visivel_b2b = false, visivel_publico = false
   where id = p_id;
  insert into public.atleta_eventos (atleta_id, tipo, titulo, fonte, origem, relevancia)
  values (p_id, 'estado_scout', 'Atleta arquivado pelo scout', v_email, 'sistema', 1);
  return jsonb_build_object('ok',true);
end $$;

create or replace function public.ytb_admin_biometria_registar(
  p_atleta uuid, p_altura_cm numeric, p_peso_kg numeric, p_pe_eu numeric,
  p_medido_em date default current_date
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public.ytb_is_admin() then
    return jsonb_build_object('ok',false,'motivo','nao_admin');
  end if;
  if p_altura_cm is null and p_peso_kg is null and p_pe_eu is null then
    return jsonb_build_object('ok',false,'motivo','sem_valores');
  end if;
  insert into public.atleta_biometria (atleta_id, altura_cm, peso_kg, pe_eu, medido_em, fonte)
  values (p_atleta, p_altura_cm, p_peso_kg, p_pe_eu, coalesce(p_medido_em, current_date), 'admin')
  returning id into v_id;
  update public.atletas_360
     set altura_cm = coalesce(p_altura_cm::int, altura_cm),
         peso_kg   = coalesce(p_peso_kg::int,   peso_kg)
   where id = p_atleta;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;

create or replace function public.ytb_admin_atleta_guardar(p_id uuid, p jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  update public.atletas_360 set
    nome                 = case when p ? 'nome' and coalesce(trim(p->>'nome'),'') <> '' then p->>'nome' else nome end,
    primeiro_nome        = case when p ? 'nome' and coalesce(trim(p->>'nome'),'') <> '' then split_part(p->>'nome',' ',1) else primeiro_nome end,
    ano_nascimento       = case when p ? 'ano_nascimento' and public.ytb_num(p->>'ano_nascimento') is not null then (public.ytb_num(p->>'ano_nascimento'))::int else ano_nascimento end,
    mes_nascimento       = case when p ? 'mes_nascimento' then (public.ytb_num(p->>'mes_nascimento'))::int else mes_nascimento end,
    dia_nascimento       = case when p ? 'dia_nascimento' then (public.ytb_num(p->>'dia_nascimento'))::int else dia_nascimento end,
    sexo                 = case when p ? 'sexo' and (p->>'sexo') in ('M','F') then p->>'sexo'
                                when p ? 'sexo' and coalesce(p->>'sexo','') = '' then null else sexo end,
    nacionalidade        = case when p ? 'nacionalidade' then p->>'nacionalidade' else nacionalidade end,
    posicao_principal    = case when p ? 'posicao_principal' and (p->>'posicao_principal') in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then p->>'posicao_principal' else posicao_principal end,
    pe_dominante         = case when p ? 'pe_dominante' and public._ytb_pe_norm(p->>'pe_dominante') is not null then public._ytb_pe_norm(p->>'pe_dominante') else pe_dominante end,
    clube_actual         = case when p ? 'clube_actual' and coalesce(trim(p->>'clube_actual'),'') <> '' then p->>'clube_actual' else clube_actual end,
    equipa               = case when p ? 'equipa' then p->>'equipa' else equipa end,
    escalao              = case when p ? 'escalao' and coalesce(trim(p->>'escalao'),'') <> '' then p->>'escalao' else escalao end,
    associacao           = case when p ? 'associacao' and coalesce(trim(p->>'associacao'),'') <> '' then p->>'associacao' else associacao end,
    esquema_tatico       = case when p ? 'esquema_tatico' then p->>'esquema_tatico' else esquema_tatico end,
    zerozero_url         = case when p ? 'zerozero_url' then p->>'zerozero_url' else zerozero_url end,
    joga_plus_url        = case when p ? 'joga_plus_url' then p->>'joga_plus_url' else joga_plus_url end,
    rating_geral         = case when p ? 'rating_geral' then p->>'rating_geral' else rating_geral end,
    badge_estado         = case when p ? 'badge_estado' then p->>'badge_estado' else badge_estado end,
    area_excelencia_1    = case when p ? 'area_excelencia_1' then p->>'area_excelencia_1' else area_excelencia_1 end,
    area_excelencia_2    = case when p ? 'area_excelencia_2' then p->>'area_excelencia_2' else area_excelencia_2 end,
    area_excelencia_3    = case when p ? 'area_excelencia_3' then p->>'area_excelencia_3' else area_excelencia_3 end,
    encarregado_nome     = case when p ? 'encarregado_nome' then p->>'encarregado_nome' else encarregado_nome end,
    encarregado_telefone = case when p ? 'encarregado_telefone' then p->>'encarregado_telefone' else encarregado_telefone end,
    encarregado_email    = case when p ? 'encarregado_email' then lower(nullif(trim(p->>'encarregado_email'),'')) else encarregado_email end,
    epoca_ref            = case when p ? 'epoca_ref' then p->>'epoca_ref' else epoca_ref end,
    divisao              = case when p ? 'divisao' then p->>'divisao' else divisao end,
    golos_epoca          = case when p ? 'golos_epoca' then (public.ytb_num(p->>'golos_epoca'))::int else golos_epoca end,
    jogos_epoca          = case when p ? 'jogos_epoca' then (public.ytb_num(p->>'jogos_epoca'))::int else jogos_epoca end,
    assist_epoca         = case when p ? 'assist_epoca' then (public.ytb_num(p->>'assist_epoca'))::int else assist_epoca end,
    golos_equipa_epoca   = case when p ? 'golos_equipa_epoca' then (public.ytb_num(p->>'golos_equipa_epoca'))::int else golos_equipa_epoca end,
    classificacao_equipa = case when p ? 'classificacao_equipa' then p->>'classificacao_equipa' else classificacao_equipa end,
    estado               = case when p ? 'estado' and (p->>'estado') in ('pendente','aprovado','rejeitado') then p->>'estado' else estado end,
    visivel_b2b          = case when p ? 'visivel_b2b' and (p->>'visivel_b2b')='false' then false else visivel_b2b end,
    visivel_publico      = case when p ? 'visivel_publico' and (p->>'visivel_publico')='false' then false else visivel_publico end,
    notas_admin          = case when p ? 'notas_admin' then p->>'notas_admin' else notas_admin end
  where id = p_id;
  insert into public.atleta_eventos (atleta_id,tipo,categoria,titulo,fonte,origem,relevancia,payload)
  values (p_id,'atualizacao_admin','marco','Ficha atualizada pelo admin','admin','sistema',1,
          jsonb_build_object('campos', (select jsonb_agg(k) from jsonb_object_keys(p) k)));
  return jsonb_build_object('ok',true);
end $$;

create or replace function public.ytb_plano_atual(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_id uuid; v_plano jsonb; v_em timestamptz; v_treinador text;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return null; end if;
  if not exists (
    select 1 from public.atletas_360 a
     where a.id = p_atleta and lower(coalesce(a.encarregado_email,'')) = v_email
  ) then return null; end if;

  select t.id, t.plano, t.criado_em into v_id, v_plano, v_em
    from public.treinador_treinos t
   where t.atleta_id = p_atleta
   order by t.criado_em desc limit 1;

  if v_id is null then return jsonb_build_object('tem', false); end if;

  select coalesce(pf.nome, av.treinador_email) into v_treinador
    from public.treinador_treinos t
    left join public.treinador_avaliacoes av on av.id = t.avaliacao_id
    left join public.perfis pf on lower(pf.email) = lower(coalesce(av.treinador_email,''))
   where t.id = v_id;
  if v_treinador is null then
    select coalesce(pf.nome, av.treinador_email) into v_treinador
      from public.treinador_avaliacoes av
      left join public.perfis pf on lower(pf.email) = lower(coalesce(av.treinador_email,''))
     where av.atleta_id = p_atleta
     order by av.criado_em desc limit 1;
  end if;

  return jsonb_build_object(
    'tem', true, 'prescrito_id', v_id, 'criado_em', v_em, 'plano', v_plano,
    'treinador_nome', coalesce(v_treinador, 'O teu treinador'),
    'feitas', (
      select coalesce(jsonb_agg(distinct jsonb_build_object('semana', f.semana, 'sessao', f.sessao)), '[]'::jsonb)
      from public.familia_treinos f
      where f.atleta_id = p_atleta and f.prescrito_id = v_id and f.semana is not null
    ));
end $$;

create or replace function public.ytb_o_que_mudou(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_email text; v_desde timestamptz;
  v_novidades jsonb; v_pendencias jsonb := '[]'::jsonb;
  v_ultimo_treino timestamptz; v_meses_bio int;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_encarregado(p_atleta) then return null; end if;

  select visto_em into v_desde from public.atleta_vistos
   where email = v_email and atleta_id = p_atleta;

  select coalesce(jsonb_agg(jsonb_build_object(
           'em', e.criado_em, 'tipo', e.tipo,
           'msg', case e.tipo
             when 'treino_prescrito' then
               case when coalesce(e.fonte,'') = 'auto'
                    then 'Plano de continuação pronto — o caminho não para 🎯'
                    when exists (select 1 from public.treinador_treinos t2
                                  where t2.atleta_id = e.atleta_id and t2.criado_em < e.criado_em - interval '1 minute')
                    then 'O treinador atualizou o teu plano de treino 🎯'
                    else 'O treinador deixou um plano de treino novo 🎯' end
             when 'avaliacao_treinador'  then 'O treinador fez uma nova avaliação'
             when 'avaliacao'            then 'Um observador registou uma nova avaliação'
             when 'relatorio_jogo'       then 'Há um novo relatório de observação'
             when 'relatorio_scout'      then 'Um scout observou o teu atleta'
             when 'estado_admin'         then coalesce(e.titulo,'O registo foi atualizado')
             when 'interesse_clube'      then 'Um clube mostrou interesse — a YTB contacta-te'
             else coalesce(e.titulo, 'Novidade no percurso')
           end) order by e.criado_em desc), '[]'::jsonb)
    into v_novidades
    from public.atleta_eventos e
   where e.atleta_id = p_atleta
     and (v_desde is null or e.criado_em > v_desde)
     and coalesce(e.fonte,'') not in ('familia','encarregado')
     and e.tipo <> 'consentimento';

  select max(e.criado_em) into v_ultimo_treino
    from public.atleta_eventos e
   where e.atleta_id = p_atleta and e.tipo = 'treino_executado';

  if v_ultimo_treino is not null
     and v_ultimo_treino between now() - interval '72 hours' and now() - interval '24 hours' then
    v_pendencias := v_pendencias || jsonb_build_object(
      'tipo','streak_risco','msg','A sequência está em risco — um treino hoje mantém a chama 🔥');
  end if;

  if exists (select 1 from public.treinador_treinos t
              where t.atleta_id = p_atleta
                and t.criado_em > coalesce(v_ultimo_treino, '-infinity'::timestamptz)) then
    v_pendencias := v_pendencias || jsonb_build_object(
      'tipo','plano_por_comecar','msg','Há um plano de treino à espera do primeiro treino');
  end if;

  if to_regclass('public.atleta_biometria') is not null then
    execute 'select (extract(epoch from now() - max(criado_em)) / 2592000)::int
               from public.atleta_biometria where atleta_id = $1'
      into v_meses_bio using p_atleta;
    if v_meses_bio is null or v_meses_bio >= 3 then
      v_pendencias := v_pendencias || jsonb_build_object(
        'tipo','biometria','msg', case when v_meses_bio is null
          then 'Regista a altura, o peso e o tamanho do pé — a trajetória começa na primeira medição'
          else 'Já passaram '||v_meses_bio||' meses desde a última medição — atualiza altura e peso' end);
    end if;
  end if;

  return jsonb_build_object(
    'desde', v_desde, 'novidades', v_novidades,
    'nao_vistos', jsonb_array_length(v_novidades), 'pendencias', v_pendencias);
end $$;

grant execute on function public.ytb_scout_atleta_criar(text,int,int,int,text,text,text,text,text,text,text,text,numeric,numeric,text,text,text,jsonb,boolean,uuid) to authenticated;
grant execute on function public.ytb_scout_meus_atletas() to authenticated;
grant execute on function public.ytb_passaporte_scout(uuid) to authenticated;
grant execute on function public.ytb_scout_atleta_editar(uuid,jsonb) to authenticated;
grant execute on function public.ytb_scout_atleta_arquivar(uuid) to authenticated;
grant execute on function public.ytb_admin_biometria_registar(uuid,numeric,numeric,numeric,date) to authenticated;
grant execute on function public.ytb_treinador_inscrever(text,int,text,text,text,text,text,int,int,text) to authenticated;
grant execute on function public.ytb_inscrever_livre(text,int,text,text,text,text,text,int,int,text) to anon, authenticated;
