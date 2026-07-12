-- ============================================================================
-- MIGRAÇÃO 027 · YTB COACH AI — sessões de equipa, presenças, convocatórias
-- Pedido do fundador: módulo para ajudar os treinadores a serem melhores
-- treinadores. IA gera sessões/microciclos adaptados a escalão, formato
-- (fut7/9/11), nº de atletas, material e tempo (a IA vive no cliente via
-- /api/claude — aqui vive só a PERSISTÊNCIA). Presenças e convocatórias são
-- factos longitudinais dos atletas → emitem eventos no livro-razão.
-- Escrita só por RPC; RLS deny-by-default; leitura só dono (treinador) + admin.
-- Validado em dry-run (2026-07-11): criar/listar sessão, presenças em lote com
-- eventos emitidos e idempotentes, convocatória com eventos por convocado,
-- stats agregadas, intruso bloqueado.
-- ============================================================================

-- guarda estrita: o Coach AI é do TREINADOR (ytb_is_treinador() histórico
-- também deixa passar scouts — aqui não faz sentido um scout gerir treinos
-- de equipa, presenças ou convocatórias)
create or replace function public._ytb_e_treinador_estrito()
returns boolean language sql security definer set search_path = public as $$
  select public.ytb_is_admin() or exists (
    select 1 from public.perfis p
    where lower(p.email)=lower(coalesce(auth.jwt()->>'email',''))
      and p.papel='treinador' and coalesce(p.estado,'aprovado')='aprovado')
$$;
revoke execute on function public._ytb_e_treinador_estrito() from public, anon, authenticated;

create table if not exists public.coach_sessoes (
  id uuid primary key default gen_random_uuid(),
  treinador_email text not null,
  titulo text, data_sessao date not null default current_date,
  escalao text, formato text check (formato in ('fut7','fut9','fut11')),
  n_atletas int, duracao_min int, material jsonb, foco text,
  plano jsonb, origem text not null default 'local' check (origem in ('ia','local')),
  criado_em timestamptz not null default now()
);
create index if not exists coach_sessoes_dono_idx on public.coach_sessoes (treinador_email, data_sessao desc);
alter table public.coach_sessoes enable row level security;
revoke insert, update, delete on public.coach_sessoes from anon, authenticated;
revoke select on public.coach_sessoes from anon;
drop policy if exists cs_dono on public.coach_sessoes;
create policy cs_dono on public.coach_sessoes for select to authenticated
  using (lower(treinador_email) = lower(coalesce(auth.jwt()->>'email','')) or public.ytb_is_admin());

create table if not exists public.coach_presencas (
  id uuid primary key default gen_random_uuid(),
  sessao_id uuid not null references public.coach_sessoes(id) on delete cascade,
  atleta_id uuid not null references public.atletas_360(id) on delete cascade,
  estado text not null check (estado in ('presente','falta','justificada')),
  criado_em timestamptz not null default now(),
  unique (sessao_id, atleta_id)
);
alter table public.coach_presencas enable row level security;
revoke insert, update, delete on public.coach_presencas from anon, authenticated;
revoke select on public.coach_presencas from anon;
drop policy if exists cp_dono on public.coach_presencas;
create policy cp_dono on public.coach_presencas for select to authenticated
  using (exists (select 1 from public.coach_sessoes s where s.id = sessao_id
                   and (lower(s.treinador_email) = lower(coalesce(auth.jwt()->>'email','')) or public.ytb_is_admin())));

create table if not exists public.coach_convocatorias (
  id uuid primary key default gen_random_uuid(),
  treinador_email text not null,
  data_jogo date, adversario text, formato text check (formato in ('fut7','fut9','fut11')),
  lista jsonb not null default '[]'::jsonb,   -- [{atleta_id, numero, papel:'titular'|'suplente'}]
  banco_estrategia text,
  criado_em timestamptz not null default now()
);
alter table public.coach_convocatorias enable row level security;
revoke insert, update, delete on public.coach_convocatorias from anon, authenticated;
revoke select on public.coach_convocatorias from anon;
drop policy if exists cc_dono on public.coach_convocatorias;
create policy cc_dono on public.coach_convocatorias for select to authenticated
  using (lower(treinador_email) = lower(coalesce(auth.jwt()->>'email','')) or public.ytb_is_admin());

create or replace function public.ytb_coach_sessao_criar(
  p_titulo text, p_data date, p_escalao text, p_formato text, p_n_atletas int,
  p_duracao int, p_material jsonb, p_foco text, p_plano jsonb, p_origem text default 'local')
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_id uuid;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_treinador_estrito() then return jsonb_build_object('ok',false,'motivo','sem_papel_treinador'); end if;
  if p_formato is not null and p_formato not in ('fut7','fut9','fut11') then
    return jsonb_build_object('ok',false,'motivo','formato_invalido');
  end if;
  insert into public.coach_sessoes (treinador_email,titulo,data_sessao,escalao,formato,n_atletas,duracao_min,material,foco,plano,origem)
  values (v_email, p_titulo, coalesce(p_data,current_date), p_escalao, p_formato, p_n_atletas, p_duracao, p_material, p_foco, p_plano,
          case when p_origem='ia' then 'ia' else 'local' end)
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;
grant execute on function public.ytb_coach_sessao_criar(text,date,text,text,int,int,jsonb,text,jsonb,text) to authenticated;

create or replace function public.ytb_coach_sessoes(p_limit int default 20)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_treinador_estrito() then return '[]'::jsonb; end if;
  return coalesce((select jsonb_agg(to_jsonb(s) order by s.data_sessao desc, s.criado_em desc)
    from (select * from public.coach_sessoes where lower(treinador_email)=v_email
          order by data_sessao desc, criado_em desc limit greatest(1,least(p_limit,100))) s), '[]'::jsonb);
end $$;
grant execute on function public.ytb_coach_sessoes(int) to authenticated;

-- presenças em lote: upsert; emite evento no livro-razão do atleta na PRIMEIRA
-- marcação (dedupe por ref (coach_presencas, presenca.id)); correções de estado
-- atualizam a linha sem novo evento (a presença é um facto, o estado afina-se).
create or replace function public.ytb_coach_presencas_marcar(p_sessao uuid, p_lista jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; item jsonb; v_atleta uuid; v_estado text; v_pid uuid; v_novo boolean; v_n int := 0;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_treinador_estrito() then return jsonb_build_object('ok',false,'motivo','sem_papel_treinador'); end if;
  if not exists (select 1 from public.coach_sessoes s where s.id=p_sessao and lower(s.treinador_email)=v_email) then
    return jsonb_build_object('ok',false,'motivo','sessao_nao_e_tua');
  end if;
  for item in select * from jsonb_array_elements(coalesce(p_lista,'[]'::jsonb)) loop
    v_atleta := (item->>'atleta_id')::uuid;
    v_estado := item->>'estado';
    if v_atleta is null or v_estado not in ('presente','falta','justificada') then continue; end if;
    insert into public.coach_presencas (sessao_id, atleta_id, estado)
    values (p_sessao, v_atleta, v_estado)
    on conflict (sessao_id, atleta_id) do update set estado = excluded.estado
    returning id, (xmax = 0) into v_pid, v_novo;
    if v_novo then
      insert into public.atleta_eventos (atleta_id,tipo,categoria,titulo,fonte,origem,relevancia,ref_tabela,ref_id,payload)
      values (v_atleta,'presenca_treino','treino',
              case v_estado when 'presente' then 'Presente no treino da equipa'
                            when 'falta' then 'Faltou ao treino da equipa'
                            else 'Falta justificada ao treino' end,
              'treinador','observado',1,'coach_presencas',v_pid::text,
              jsonb_build_object('sessao_id',p_sessao,'estado',v_estado))
      on conflict (ref_tabela, ref_id) where ref_id is not null do nothing;
    end if;
    v_n := v_n + 1;
  end loop;
  return jsonb_build_object('ok',true,'marcadas',v_n);
end $$;
grant execute on function public.ytb_coach_presencas_marcar(uuid,jsonb) to authenticated;

create or replace function public.ytb_coach_convocatoria_criar(
  p_data date, p_adversario text, p_formato text, p_lista jsonb, p_banco text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_id uuid; item jsonb; v_atleta uuid;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_treinador_estrito() then return jsonb_build_object('ok',false,'motivo','sem_papel_treinador'); end if;
  insert into public.coach_convocatorias (treinador_email,data_jogo,adversario,formato,lista,banco_estrategia)
  values (v_email, p_data, p_adversario, p_formato, coalesce(p_lista,'[]'::jsonb), p_banco)
  returning id into v_id;
  for item in select * from jsonb_array_elements(coalesce(p_lista,'[]'::jsonb)) loop
    v_atleta := (item->>'atleta_id')::uuid;
    if v_atleta is null then continue; end if;
    insert into public.atleta_eventos (atleta_id,tipo,categoria,titulo,fonte,origem,relevancia,ref_tabela,ref_id,payload)
    values (v_atleta,'convocatoria','treino',
            case when item->>'papel'='suplente' then 'Convocado (suplente)' else 'Convocado para jogo' end,
            'treinador','observado',2,'coach_convocatorias',v_id::text||':'||v_atleta::text,
            jsonb_build_object('convocatoria_id',v_id,'numero',item->>'numero','papel',item->>'papel','adversario',p_adversario,'data',p_data))
    on conflict (ref_tabela, ref_id) where ref_id is not null do nothing;
  end loop;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;
grant execute on function public.ytb_coach_convocatoria_criar(date,text,text,jsonb,text) to authenticated;

-- stats por atleta do treinador (base da convocatória): presenças últimos 30d
create or replace function public.ytb_coach_stats()
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_treinador_estrito() then return '[]'::jsonb; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'atleta_id', a.id, 'nome', a.nome, 'escalao', a.escalao, 'posicao', a.posicao_principal,
      'presencas_30d', (select count(*) from public.coach_presencas p join public.coach_sessoes s on s.id=p.sessao_id
                         where p.atleta_id=a.id and lower(s.treinador_email)=v_email and p.estado='presente' and s.data_sessao > current_date-30),
      'faltas_30d', (select count(*) from public.coach_presencas p join public.coach_sessoes s on s.id=p.sessao_id
                      where p.atleta_id=a.id and lower(s.treinador_email)=v_email and p.estado='falta' and s.data_sessao > current_date-30),
      'sessoes_30d', (select count(distinct s.id) from public.coach_sessoes s
                       where lower(s.treinador_email)=v_email and s.data_sessao > current_date-30
                         and exists (select 1 from public.coach_presencas p where p.sessao_id=s.id)),
      'ultima_presenca', (select max(s.data_sessao) from public.coach_presencas p join public.coach_sessoes s on s.id=p.sessao_id
                           where p.atleta_id=a.id and lower(s.treinador_email)=v_email and p.estado='presente')
    ) order by a.nome)
    from public.atletas_360 a
    where lower(coalesce(a.fonte_email,''))=v_email and coalesce(a.estado,'')<>'arquivado'
  ), '[]'::jsonb);
end $$;
grant execute on function public.ytb_coach_stats() to authenticated;
