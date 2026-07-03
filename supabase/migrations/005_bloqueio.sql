-- ============================================================================
-- MIGRAÇÃO 004 · BLOQUEIO (corre em ÚLTIMO)
-- ----------------------------------------------------------------------------
-- RLS em todas as tabelas, escritas diretas revogadas a anon/authenticated
-- (tudo passa pelas RPCs security definer), livro-razão imutável ao nível de
-- role, e policies de leitura explícitas e versionadas AQUI (Constituição).
-- NOTA: policies pré-existentes em produção com outros nomes devem ser
-- revistas com migrations/verificacao.sql (lista pg_policies) e removidas à
-- mão se forem permissivas — esta migração não consegue adivinhar nomes.
-- ============================================================================

do $$
declare t text;
begin
  foreach t in array array[
    'atletas_360','perfis','atletas_360_avaliacoes','treinador_avaliacoes',
    'treinador_treinos','familia_treinos','atletas_360_historico',
    'elite_coach_resultados','registos_pendentes','atletas_360_pedidos_contacto',
    'atletas_360_clubes_subscritores','comissoes','avaliacoes_contextuais',
    'scout_plafond','scout_relatorios','consentimentos','atleta_eventos'
  ] loop
    if to_regclass('public.'||t) is null then continue; end if;
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke insert, update, delete on public.%I from anon, authenticated', t);
  end loop;
end $$;

-- anon não lê tabelas de domínio diretamente (as RPCs anon — montra, inscrição —
-- são security definer e não dependem destes grants)
do $$
declare t text;
begin
  foreach t in array array[
    'atletas_360','perfis','atletas_360_avaliacoes','treinador_avaliacoes',
    'treinador_treinos','familia_treinos','atletas_360_historico',
    'elite_coach_resultados','registos_pendentes','atletas_360_pedidos_contacto',
    'atletas_360_clubes_subscritores','comissoes','avaliacoes_contextuais',
    'scout_plafond','scout_relatorios','consentimentos'
  ] loop
    if to_regclass('public.'||t) is null then continue; end if;
    execute format('revoke select on public.%I from anon', t);
  end loop;
end $$;

-- ── LEITURAS: admin vê tudo ──────────────────────────────────────────────────
do $$
declare t text;
begin
  foreach t in array array[
    'atletas_360','perfis','atletas_360_avaliacoes','treinador_avaliacoes',
    'treinador_treinos','familia_treinos','atletas_360_historico',
    'elite_coach_resultados','registos_pendentes','atletas_360_pedidos_contacto',
    'atletas_360_clubes_subscritores','comissoes','avaliacoes_contextuais',
    'scout_plafond','scout_relatorios','consentimentos'
  ] loop
    if to_regclass('public.'||t) is null then continue; end if;
    execute format('drop policy if exists sel_admin on public.%I', t);
    execute format('create policy sel_admin on public.%I for select to authenticated using (public.ytb_is_admin())', t);
  end loop;
end $$;

-- ── LEITURAS: treinador aprovado vê o operacional dele ──────────────────────
do $$
declare t text;
begin
  foreach t in array array['atletas_360','treinador_avaliacoes','treinador_treinos','familia_treinos'] loop
    execute format('drop policy if exists sel_treinador on public.%I', t);
    execute format('create policy sel_treinador on public.%I for select to authenticated using (public.ytb_is_treinador())', t);
  end loop;
end $$;

-- ── LIVRO-RAZÃO imutável ao nível de role (correções = novos eventos) ────────
revoke update, delete on public.atleta_eventos from anon, authenticated;
-- as policies de leitura da atleta_eventos vêm do ciclo1 (família/público) e mantêm-se

-- ── verificação rápida embutida ──────────────────────────────────────────────
-- select tablename, count(*) policies from pg_policies where schemaname='public' group by 1 order by 1;
