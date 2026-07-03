-- ============================================================================
-- MIGRAÇÃO 005 · BLOQUEIO
-- RLS em todas as tabelas nucleares, escritas diretas revogadas a
-- anon/authenticated (tudo passa pelas RPCs security definer), livro-razão
-- imutável ao nível de role, policies de leitura explícitas.
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

do $$
declare t text;
begin
  foreach t in array array['atletas_360','treinador_avaliacoes','treinador_treinos','familia_treinos'] loop
    execute format('drop policy if exists sel_treinador on public.%I', t);
    execute format('create policy sel_treinador on public.%I for select to authenticated using (public.ytb_is_treinador())', t);
  end loop;
end $$;

revoke update, delete on public.atleta_eventos from anon, authenticated;