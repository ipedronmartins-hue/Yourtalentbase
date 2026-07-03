-- ============================================================================
-- MIGRAÇÃO 000 · ESQUEMA BASE REPRODUTÍVEL (no-op seguro onde já existe)
-- ============================================================================
do $pgc$ begin
  begin execute 'create extension if not exists pgcrypto';
  exception when others then null;
  end;
end $pgc$;

create table if not exists public.atletas_360 (
  id uuid primary key default gen_random_uuid(),
  nome text, primeiro_nome text, ano_nascimento int,
  escalao text, associacao text, posicao_principal text,
  clube_actual text, equipa text, divisao text, epoca_ref text,
  zerozero_url text, joga_plus_url text,
  golos_epoca int, jogos_epoca int, assist_epoca int,
  golos_equipa_epoca int, classificacao_equipa text,
  area_excelencia_1 text, area_excelencia_2 text, area_excelencia_3 text,
  rating_geral text, badge_estado text, stats_actualizadas_em timestamptz,
  estado text default 'pendente', estado_motivo text,
  aprovado_por text, aprovado_em timestamptz,
  visivel_b2b boolean default false, visivel_publico boolean default false,
  oculto_pelo_responsavel boolean default false,
  fonte text, fonte_nome text, fonte_email text,
  encarregado_email text, encarregado_nome text, encarregado_telefone text,
  foto_path text, foto_consentida boolean default false,
  video_path text, video_consentido boolean default false,
  consentido_em timestamptz, consentido_por text, versao_consentimento text,
  token_consentimento uuid default gen_random_uuid(),
  whatsapp_enviado boolean, whatsapp_enviado_em timestamptz, whatsapp_enviado_por text,
  notas_admin text,
  criado_em timestamptz default now()
);
alter table public.atletas_360 add column if not exists oculto_pelo_responsavel boolean default false;
alter table public.atletas_360 add column if not exists encarregado_email text;
alter table public.atletas_360 add column if not exists rating_geral text;
alter table public.atletas_360 add column if not exists visivel_publico boolean default false;

create table if not exists public.perfis (
  email text primary key, nome text, papel text, estado text default 'aprovado',
  criado_em timestamptz default now()
);
alter table public.perfis add column if not exists estado text default 'aprovado';

create table if not exists public.atletas_360_avaliacoes (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.atletas_360(id) on delete cascade,
  rating numeric, dim_treinabilidade numeric, dim_compromisso numeric,
  dim_impacto numeric, dim_competitividade numeric,
  peso_avaliacao numeric, avaliador_tipo text, fonte text,
  payload jsonb, criado_em timestamptz default now()
);
create table if not exists public.treinador_avaliacoes (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.atletas_360(id) on delete cascade,
  treinador_id text, treinador_email text,
  criterios jsonb, debilidades jsonb, criado_em timestamptz default now()
);
create table if not exists public.treinador_treinos (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.atletas_360(id) on delete cascade,
  treinador_id text, avaliacao_id uuid, plano jsonb, fonte text,
  created_at timestamptz default now()
);
create table if not exists public.familia_treinos (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.atletas_360(id) on delete cascade,
  prescrito_id uuid, confianca int, semana int, sessao int,
  feedback text, nota_treinador text, tempo numeric, flags jsonb,
  created_at timestamptz default now()
);
alter table public.familia_treinos add column if not exists feedback text;
alter table public.familia_treinos add column if not exists semana int;
alter table public.familia_treinos add column if not exists sessao int;
alter table public.familia_treinos add column if not exists nota_treinador text;
create table if not exists public.atletas_360_historico (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.atletas_360(id) on delete cascade,
  epoca text, payload jsonb, criado_em timestamptz default now()
);
create table if not exists public.elite_coach_resultados (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.atletas_360(id) on delete cascade,
  cenario text, correto boolean, payload jsonb, criado_em timestamptz default now()
);

create table if not exists public.registos_pendentes (
  id uuid primary key default gen_random_uuid(),
  nome text, email text, telefone text, papel text, mensagem text,
  estado text default 'pendente', criado_em timestamptz default now()
);
create table if not exists public.atletas_360_pedidos_contacto (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.atletas_360(id) on delete set null,
  clube_nome text, contacto text, mensagem text,
  estado text default 'novo',
  whatsapp_enviado_em timestamptz, resolvido_em timestamptz, resposta_em timestamptz,
  criado_em timestamptz default now()
);
create table if not exists public.atletas_360_clubes_subscritores (
  id uuid primary key default gen_random_uuid(),
  clube_nome text, responsavel_nome text, responsavel_email text,
  responsavel_telefone text, responsavel_cargo text,
  password_temporaria text,
  plano text, valor_mensal numeric, subscrito_em timestamptz default now(),
  estado_subscricao text default 'ativa', notas_admin text,
  criado_em timestamptz default now()
);
create table if not exists public.comissoes (
  id uuid primary key default gen_random_uuid(),
  treinador_email text, atleta_id uuid, valor numeric,
  pago_ao_treinador boolean default false, criado_em timestamptz default now()
);
create table if not exists public.avaliacoes_contextuais (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.atletas_360(id) on delete cascade,
  texto_ia text, snapshot jsonb, gerado_por text, modelo text,
  criado_em timestamptz default now()
);
create table if not exists public.scout_plafond (
  email text primary key, creditos int default 0, atualizado_em timestamptz default now()
);
create table if not exists public.scout_relatorios (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.atletas_360(id) on delete set null,
  scout_email text, atleta_nome text, criado_em timestamptz default now()
);
create index if not exists idx_scout_rel_email on public.scout_relatorios(scout_email);

create table if not exists public.sessao_familia (
  token uuid primary key default gen_random_uuid(),
  atleta_id uuid, expira_em timestamptz, criado_em timestamptz default now()
);
create index if not exists idx_sessao_familia_atleta on public.sessao_familia(atleta_id);

create table if not exists public.atleta_eventos (
  id            uuid primary key default gen_random_uuid(),
  atleta_id     uuid not null references public.atletas_360(id) on delete cascade,
  tipo          text not null,
  categoria     text,
  titulo        text,
  fonte         text,
  origem        text not null default 'observado'
                check (origem in ('observado','declarado','sistema')),
  relevancia    smallint not null default 1 check (relevancia between 1 and 5),
  impacto       smallint,
  ref_tabela    text,
  ref_id        text,
  versao_regua  text,
  payload       jsonb,
  criado_em     timestamptz not null default now()
);
alter table public.atleta_eventos add column if not exists categoria    text;
alter table public.atleta_eventos add column if not exists origem       text not null default 'observado';
alter table public.atleta_eventos add column if not exists relevancia   smallint not null default 1;
alter table public.atleta_eventos add column if not exists impacto      smallint;
alter table public.atleta_eventos add column if not exists ref_tabela   text;
alter table public.atleta_eventos add column if not exists ref_id       text;
alter table public.atleta_eventos add column if not exists versao_regua text;
alter table public.atleta_eventos add column if not exists payload      jsonb;

create unique index if not exists atleta_eventos_ref_uk
  on public.atleta_eventos (ref_tabela, ref_id)
  where ref_id is not null;
create index if not exists atleta_eventos_atleta_idx
  on public.atleta_eventos (atleta_id, criado_em desc);
create index if not exists atleta_eventos_relev_idx
  on public.atleta_eventos (atleta_id, relevancia desc, criado_em desc);

create or replace function public.ytb_emitir_evento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  j        jsonb := to_jsonb(NEW);
  v_campo  text  := coalesce(nullif(TG_ARGV[4], ''), 'atleta_id');
  v_atleta uuid;
begin
  v_atleta := nullif(j ->> v_campo, '')::uuid;
  if v_atleta is null then
    return NEW;
  end if;

  insert into public.atleta_eventos
    (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, impacto,
     ref_tabela, ref_id, versao_regua, payload, criado_em)
  values
    (v_atleta,
     TG_ARGV[0],
     TG_ARGV[5],
     TG_ARGV[2],
     coalesce(j ->> 'fonte', j ->> 'avaliador_tipo', TG_ARGV[1]),
     coalesce(nullif(TG_ARGV[3], ''), 'observado'),
     coalesce(nullif(TG_ARGV[6], '')::smallint, 1),
     null,
     TG_TABLE_NAME,
     coalesce(j ->> 'id', j ->> 'uuid'),
     j ->> 'versao_regua',
     j,
     coalesce(nullif(j ->> 'criado_em',  '')::timestamptz,
              nullif(j ->> 'created_at', '')::timestamptz,
              now()))
  on conflict (ref_tabela, ref_id) where ref_id is not null do nothing;

  return NEW;
end;
$$;

do $outer$
declare
  cfg record;
begin
  for cfg in
    select * from (values
      ('atletas_360',                    'inscricao',            'sistema',   'Atleta inscrito',          'sistema',    'id',        'marco',      '2'),
      ('atletas_360_avaliacoes',         'avaliacao',            'scout',     'Avaliação 360',            'observado',  'atleta_id', 'avaliacao',  '4'),
      ('relatorios',                     'relatorio_jogo',       'scout',     'Relatório de observação',  'observado',  'atleta_id', 'avaliacao',  '4'),
      ('treinador_avaliacoes',           'avaliacao_treinador',  'treinador', 'Avaliação do treinador',   'observado',  'atleta_id', 'avaliacao',  '4'),
      ('familia_avaliacoes',             'autoavaliacao_familia','familia',   'Autoavaliação da família', 'declarado',  'atleta_id', 'avaliacao',  '2'),
      ('avaliacoes_contextuais',         'avaliacao',            'admin',     'Avaliação contextual',     'observado',  'atleta_id', 'avaliacao',  '4'),
      ('familia_treinos',                'treino_executado',     'familia',   'Treino concluído',         'declarado',  'atleta_id', 'treino',     '1'),
      ('treinador_treinos',              'treino_prescrito',     'treinador', 'Plano de treino',          'sistema',    'atleta_id', 'treino',     '3'),
      ('elite_coach_resultados',         'decisao_tatica',       'familia',   'Cenário Elite Coach',      'declarado',  'atleta_id', 'treino',     '1'),
      ('atletas_360_historico',          'epoca_registada',      'familia',   'Época registada',          'declarado',  'atleta_id', 'historico',  '3'),
      ('atletas_360_pedidos_contacto',   'interesse_clube',      'clube',     'Interesse de clube',       'sistema',    'atleta_id', 'marco',      '5')
    ) as t(tbl, tipo, fonte, titulo, origem, campo, categoria, relev)
  loop
    if to_regclass('public.' || cfg.tbl) is null then
      continue;
    end if;

    execute format('drop trigger if exists ytb_ev_%I on public.%I', cfg.tbl, cfg.tbl);
    execute format(
      'create trigger ytb_ev_%I after insert on public.%I '
      || 'for each row execute function public.ytb_emitir_evento(%L,%L,%L,%L,%L,%L,%L)',
      cfg.tbl, cfg.tbl, cfg.tipo, cfg.fonte, cfg.titulo, cfg.origem, cfg.campo, cfg.categoria, cfg.relev
    );

    execute format($bf$
      insert into public.atleta_eventos
        (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, impacto,
         ref_tabela, ref_id, versao_regua, payload, criado_em)
      select
        nullif(to_jsonb(t) ->> %L, '')::uuid,
        %L,
        %L,
        %L,
        coalesce(to_jsonb(t) ->> 'fonte', to_jsonb(t) ->> 'avaliador_tipo', %L),
        %L,
        %L::smallint,
        null,
        %L,
        coalesce(to_jsonb(t) ->> 'id', to_jsonb(t) ->> 'uuid'),
        to_jsonb(t) ->> 'versao_regua',
        to_jsonb(t),
        coalesce(nullif(to_jsonb(t) ->> 'criado_em',  '')::timestamptz,
                 nullif(to_jsonb(t) ->> 'created_at', '')::timestamptz,
                 now())
      from public.%I t
      where nullif(to_jsonb(t) ->> %L, '') is not null
        and coalesce(to_jsonb(t) ->> 'id', to_jsonb(t) ->> 'uuid') is not null
      on conflict (ref_tabela, ref_id) where ref_id is not null do nothing
    $bf$, cfg.campo, cfg.tipo, cfg.categoria, cfg.titulo, cfg.fonte, cfg.origem,
          cfg.relev, cfg.tbl, cfg.tbl, cfg.campo);

  end loop;
end;
$outer$;

alter table public.atleta_eventos enable row level security;

drop policy if exists ev_public_read on public.atleta_eventos;
create policy ev_public_read on public.atleta_eventos
  for select to anon
  using (exists (
    select 1 from public.atletas_360 a
    where a.id = atleta_eventos.atleta_id
      and coalesce(a.visivel_publico, false) = true
      and coalesce(a.oculto_pelo_responsavel, false) = false
      and coalesce(a.estado, '') = 'aprovado'
  ));

drop policy if exists ev_auth_read on public.atleta_eventos;
create policy ev_auth_read on public.atleta_eventos
  for select to authenticated
  using (exists (
    select 1 from public.atletas_360 a
    where a.id = atleta_eventos.atleta_id
      and (
        a.encarregado_email = (auth.jwt() ->> 'email')
        or (
          coalesce(a.visivel_publico, false) = true
          and coalesce(a.oculto_pelo_responsavel, false) = false
          and coalesce(a.estado, '') = 'aprovado'
        )
      )
  ));

do $$
begin
  if to_regclass('public.scout_relatorios') is not null then
    drop trigger if exists ytb_ev_scout_relatorios on public.scout_relatorios;
    create trigger ytb_ev_scout_relatorios after insert on public.scout_relatorios
      for each row execute function public.ytb_emitir_evento(
        'relatorio_scout','scout','Relatório de scout gerado','observado','atleta_id','avaliacao','3');
    insert into public.atleta_eventos
      (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia,
       ref_tabela, ref_id, payload, criado_em)
    select t.atleta_id, 'relatorio_scout', 'avaliacao', 'Relatório de scout gerado',
           coalesce(t.scout_email,'scout'), 'observado', 3,
           'scout_relatorios', t.id::text, to_jsonb(t), t.criado_em
    from public.scout_relatorios t
    where t.atleta_id is not null
    on conflict (ref_tabela, ref_id) where ref_id is not null do nothing;
  end if;
end $$;

create or replace function public.ytb_num(t text) returns numeric language sql immutable as $$
  select case when t ~ '^\s*-?[0-9]+(\.[0-9]+)?\s*$' then trim(t)::numeric else null end
$$;

create or replace view public.atleta_passaporte as
with
aval_obs as (
  select atleta_id,
         ytb_num(payload->>'dim_treinabilidade')   as treinabilidade,
         ytb_num(payload->>'dim_compromisso')       as compromisso,
         ytb_num(payload->>'dim_impacto')           as impacto,
         ytb_num(payload->>'dim_competitividade')   as competitividade,
         coalesce(ytb_num(payload->>'peso_avaliacao'), 0.4) as peso,
         coalesce(payload->>'avaliador_tipo', fonte)  as avaliador,
         criado_em
  from public.atleta_eventos
  where tipo = 'avaliacao' and origem = 'observado'
),
rel as (
  select atleta_id, ytb_num(payload->>'media_geral') as media5
  from public.atleta_eventos where tipo = 'relatorio_jogo'
),
tr as (
  select atleta_id,
         coalesce(ytb_num(payload->>'tempo'), 0)       as tempo_min,
         coalesce(ytb_num(payload->>'confianca'), 100) as confianca,
         nullif(payload->>'prescrito_id','')             as prescrito_id,
         coalesce(jsonb_array_length(
            case when jsonb_typeof(payload->'flags')='array'
                 then payload->'flags' else '[]'::jsonb end), 0) as n_flags,
         criado_em,
         date_trunc('week', criado_em) as semana
  from public.atleta_eventos where tipo = 'treino_executado'
),
aval_dec as (
  select atleta_id from public.atleta_eventos
  where tipo = 'autoavaliacao_familia' or (categoria='avaliacao' and origem='declarado')
),
base as ( select distinct atleta_id from public.atleta_eventos )
select
  b.atleta_id,
  greatest(0, least(100, round(
     (select sum(treinabilidade*peso)/nullif(sum(peso),0) from aval_obs a where a.atleta_id=b.atleta_id) * 20
  )))::int as treinabilidade,
  greatest(0, least(100, round(
     (select sum(compromisso*peso)/nullif(sum(peso),0) from aval_obs a where a.atleta_id=b.atleta_id) * 20
  )))::int as compromisso,
  greatest(0, least(100, round(
       coalesce((select sum((impacto+competitividade)/2.0*peso)/nullif(sum(peso),0) from aval_obs a where a.atleta_id=b.atleta_id) * 20, 0) * 0.7
     + coalesce((select avg(media5) from rel r where r.atleta_id=b.atleta_id) * 20, 0) * 0.3
  )))::int as nivel_competitivo,
  greatest(0, least(100, round(
     100.0 * (select count(distinct semana) from tr t where t.atleta_id=b.atleta_id and t.criado_em >= now()-interval '26 weeks') / 26.0
  )))::int as consistencia,
  round( coalesce((select sum(tempo_min) from tr t where t.atleta_id=b.atleta_id), 0) / 60.0, 1) as horas_treino_extra,
  greatest(0, least(100, round(
     100.0 * (select count(*) from tr t where t.atleta_id=b.atleta_id and t.prescrito_id is not null)
            / nullif((select count(*) from tr t where t.atleta_id=b.atleta_id), 0)
  )))::int as adesao_plano,
  ( with rec as (select avg((treinabilidade+compromisso)/2.0) v from aval_obs a
                  where a.atleta_id=b.atleta_id and a.criado_em>=now()-interval '6 months'),
         vel as (select avg((treinabilidade+compromisso)/2.0) v from aval_obs a
                  where a.atleta_id=b.atleta_id and a.criado_em<now()-interval '18 months'
                                                and a.criado_em>=now()-interval '24 months')
    select round((rec.v - vel.v)/nullif(vel.v,0) * 100) from rec, vel )::int as evolucao_pct,
  ( select case
       when bool_or(avaliador ilike '%scout%') and bool_or(avaliador ilike '%treinador%') then 'scout+treinador'
       when bool_or(avaliador ilike '%scout%')     then 'scout'
       when bool_or(avaliador ilike '%treinador%') then 'treinador'
       when count(*) > 0                           then 'contextual'
       else 'sem_avaliacao' end
    from aval_obs a where a.atleta_id=b.atleta_id ) as nivel_verificacao,
  ( select (now()::date - max(criado_em)::date) from aval_obs a where a.atleta_id=b.atleta_id )::int as dias_desde_avaliacao,
  greatest(0, least(100, round(
       coalesce( (select count(*)::numeric from aval_obs a where a.atleta_id=b.atleta_id)
                 / nullif((select count(*) from aval_obs a where a.atleta_id=b.atleta_id)
                        + (select count(*) from aval_dec d where d.atleta_id=b.atleta_id), 0), 0) * 100 * 0.4
     + least(20, (select count(distinct avaliador) from aval_obs a where a.atleta_id=b.atleta_id) * 10)
     + coalesce( (select avg(confianca) from tr t where t.atleta_id=b.atleta_id), 100) * 0.4
     - coalesce( (select sum(n_flags) from tr t where t.atleta_id=b.atleta_id), 0)
  )))::int as confianca_dado,
  ( select count(*)       from public.atleta_eventos e where e.atleta_id=b.atleta_id ) as n_eventos,
  ( select max(criado_em) from public.atleta_eventos e where e.atleta_id=b.atleta_id ) as ultimo_evento
from base b;
