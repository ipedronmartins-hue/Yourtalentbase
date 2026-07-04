-- ============================================================================
-- VERIFICAÇÃO · correr em produção ANTES (ver diffs) e DEPOIS (confirmar)
-- Não altera nada. Só lê catálogos.
-- ============================================================================

-- 1) Tabelas esperadas vs existentes
with esperadas(t) as (values
  ('atletas_360'),('perfis'),('atletas_360_avaliacoes'),('treinador_avaliacoes'),
  ('treinador_treinos'),('familia_treinos'),('atletas_360_historico'),
  ('elite_coach_resultados'),('registos_pendentes'),('atletas_360_pedidos_contacto'),
  ('atletas_360_clubes_subscritores'),('comissoes'),('avaliacoes_contextuais'),
  ('scout_plafond'),('scout_relatorios'),('consentimentos'),('atleta_eventos'))
select e.t as tabela,
       case when to_regclass('public.'||e.t) is null then '✗ EM FALTA' else '✓' end as estado
from esperadas e order by 2 desc, 1;

-- 1b) Tabelas referenciadas pela config de triggers cuja existência é incerta
select 'relatorios' as tabela_incerta, to_regclass('public.relatorios') is not null as existe
union all
select 'familia_avaliacoes', to_regclass('public.familia_avaliacoes') is not null;

-- 2) Funções esperadas (novas) vs existentes
select p.proname, count(*) as variantes
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in (
  'ytb_is_admin','ytb_is_treinador','ytb_treinador_inscrever','ytb_treinador_avaliar',
  'ytb_admin_atleta_estado','ytb_admin_atleta_guardar','ytb_admin_atleta_apagar',
  'ytb_admin_whatsapp','ytb_admin_registo_decidir','ytb_admin_pedido_contacto',
  'ytb_admin_clube_registar','ytb_admin_clube_remover','ytb_admin_aval_contextual',
  'ytb_admin_perfil_estado','ytb_consentimentos','ytb_consentir_ambito','ytb_revogar',
  'ytb_consentir_email','ytb_montra','ytb_emitir_evento','ytb_num')
group by 1 order by 1;

-- 3) LEGADO: tem de dar ZERO linhas depois da 003
select p.proname as legado_ainda_presente
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in
  ('ytb_consentir','ytb_atleta_por_token','ytb_acesso','ytb_criar_acesso','ytb_cognitivo')
union all
select 'tabela sessao_familia' where to_regclass('public.sessao_familia') is not null
union all
select 'coluna token_consentimento' where exists (
  select 1 from information_schema.columns
  where table_schema='public' and table_name='atletas_360' and column_name='token_consentimento')
union all
select 'ytb_passaporte(uuid) [token]' where exists (
  select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='ytb_passaporte'
    and pg_get_function_identity_arguments(p.oid) = 'p_token uuid');

-- 4) Passwords em texto simples: tem de dar 0 depois da 003
select count(*) as passwords_por_purgar
from public.atletas_360_clubes_subscritores where password_temporaria is not null;

-- 5) RLS ligado? (todas 't' depois da 004)
select c.relname as tabela, c.relrowsecurity as rls_on
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
  and c.relname like any (array['atletas%','treinador%','familia%','perfis','consentimentos','scout%','comissoes','registos%','elite%','atleta_eventos','avaliacoes_contextuais'])
order by 1;

-- 6) POLICIES existentes — REVER À MÃO as que não forem sel_admin/sel_treinador/
--    ev_public_read/ev_auth_read (podem ser permissivas antigas)
select tablename, policyname, cmd, roles
from pg_policies where schemaname='public' order by tablename, policyname;

-- 7) Triggers de emissão de eventos ligados (esperado: ~12, incl. scout_relatorios)
select c.relname as tabela, t.tgname
from pg_trigger t join pg_class c on c.oid=t.tgrelid
where not t.tgisinternal and t.tgname like 'ytb_ev_%' order by 1;

-- 8) Escritas diretas ainda concedidas? (esperado: ZERO linhas para anon/authenticated)
select grantee, table_name, privilege_type
from information_schema.role_table_grants
where table_schema='public' and grantee in ('anon','authenticated')
  and privilege_type in ('INSERT','UPDATE','DELETE')
order by table_name, grantee;
