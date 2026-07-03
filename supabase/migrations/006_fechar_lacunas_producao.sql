-- ============================================================================
-- MIGRAÇÃO 006 · FECHO DE LACUNAS REAIS DE PRODUÇÃO
-- ----------------------------------------------------------------------------
-- Esta migração só existe porque inspecionámos pg_policies AO VIVO em
-- produção (nhshnplaiolxwcfuijfo) em 2026-07-02. Nenhuma auditoria por
-- ficheiros conseguiria ver isto — são policies que nunca estiveram em
-- nenhum .sql do repositório.
--
-- ACHADO CRÍTICO: existem policies "ALL ... USING (true)" e policies de
-- INSERT/UPDATE sem qualquer restrição, concedidas a `anon` e/ou
-- `authenticated`, em tabelas nucleares — incluindo `atletas_360` em si
-- (a360_staff: qualquer utilizador autenticado tinha ALL sobre TODOS os
-- atletas). Isto tornava as RPCs das migrações 001-003 decorativas: a
-- policy antiga, mais permissiva, ganhava sempre (policies são OR'd).
--
-- Esta migração:
--   (a) remove essas policies antigas pelo nome exato encontrado;
--   (b) liga RLS nas tabelas que estavam completamente desligadas
--       (achado original: profiles, atletas, inscricoes, relatorios,
--       gondomar_atletas, liga_jogadores, liga_jogos);
--   (c) fecha o sistema paralelo `ytb_*` (utilizadores/pagamentos/comissões/
--       inscrições/notificações/competências/avaliações) e outras tabelas
--       mortas (sugestoes, treino_resultados, comissao_regras) — confirmado
--       por grep: ZERO páginas vivas referenciam qualquer uma destas;
--   (d) NÃO apaga nenhuma linha, NÃO apaga nenhuma tabela — só fecha acesso
--       de cliente. Os dados ficam intactos e visíveis via SQL/dashboard.
--   (e) preserva leitura só-para-admin em `relatorios` (admin360.html lê-a).
--       `pagamentos` e `comissoes` já tinham policies corretas
--       (pag_admin / comissoes_dono) — não mexidas.
-- ============================================================================

-- ── (a) POLICIES PERIGOSAS PRÉ-EXISTENTES — remover pelo nome exato ─────────

-- atletas_360: o achado mais grave — ALL/true para qualquer authenticated,
-- e INSERT sem restrição para anon+authenticated (contorna ytb_treinador_inscrever)
drop policy if exists a360_staff on public.atletas_360;
drop policy if exists atletas_insercao_publica on public.atletas_360;
drop policy if exists atletas_update_autorizado on public.atletas_360;  -- redundante: escrita agora só por RPC

-- atletas_360_avaliacoes: inserção pública direta + leitura em bloco
drop policy if exists avaliacoes_insercao_publica on public.atletas_360_avaliacoes;
drop policy if exists avals_insert_scout on public.atletas_360_avaliacoes;
drop policy if exists avaliacoes_leitura_auth on public.atletas_360_avaliacoes;

-- atletas_360_stats: ALL/true + inserções/updates públicos diretos
drop policy if exists stats_staff on public.atletas_360_stats;
drop policy if exists stats_insercao_publica on public.atletas_360_stats;
drop policy if exists stats_insert_colaborador on public.atletas_360_stats;
drop policy if exists stats_update_colaborador on public.atletas_360_stats;

-- atletas_360_historico / match_reports: inserção pública direta
drop policy if exists historico_insercao_publica on public.atletas_360_historico;
drop policy if exists reports_insert_colaborador on public.atletas_360_match_reports;

-- atletas_360_colaboradores: sistema de "colaborador" que nunca vi em ficheiro —
-- lia e escrevia (incl. token_acesso!) sem qualquer autenticação
drop policy if exists colab_insert_publico on public.atletas_360_colaboradores;
drop policy if exists colab_leitura_token on public.atletas_360_colaboradores;
drop policy if exists colab_update_proprio on public.atletas_360_colaboradores;
-- colab_admin_total fica (admin-only, correta)

-- atleta_eventos: leitura em bloco para qualquer authenticated, para além das
-- policies corretas (ev_auth_read / ev_public_read, que ficam)
drop policy if exists ev_leitura_auth on public.atleta_eventos;

-- familia_treinos: leitura em bloco além da correta (familia_treino_dono, fica)
drop policy if exists ft_leitura_auth on public.familia_treinos;

-- avaliacoes_contextuais: leitura em bloco de narrativas IA sobre menores
drop policy if exists avctx_leitura_subscritor on public.avaliacoes_contextuais;

-- relatorios: única policy existente é demasiado ampla (authenticated=true);
-- RLS estava DESLIGADO nesta tabela, por isso nunca teve efeito nenhum —
-- substitui-se por leitura só-admin ao ligar RLS abaixo
drop policy if exists relatorios_leitura_auth on public.relatorios;

-- sugestoes: 5 policies, todas para `anon`, todas sem restrição — CRUD público total
drop policy if exists allow_anon_insert on public.sugestoes;
drop policy if exists insert_publico on public.sugestoes;
drop policy if exists select_publico on public.sugestoes;
drop policy if exists update_publico on public.sugestoes;
drop policy if exists delete_publico on public.sugestoes;

-- treino_resultados: ALL para `public` (pior que anon: literalmente toda a gente)
drop policy if exists open_pilot on public.treino_resultados;

-- sistema paralelo ytb_*: mesma policy-padrão perigosa repetida 7 vezes
drop policy if exists ytb_atletas_staff on public.ytb_atletas;
drop policy if exists aval_staff on public.ytb_avaliacoes;
drop policy if exists ytb_comissoes_staff on public.ytb_comissoes;
drop policy if exists ytb_inscricoes_staff on public.ytb_inscricoes;
drop policy if exists ytb_notificacoes_staff on public.ytb_notificacoes;
drop policy if exists ytb_pagamentos_staff on public.ytb_pagamentos;
drop policy if exists ytb_utilizadores_staff on public.ytb_utilizadores;
drop policy if exists comp_leitura on public.ytb_competencias;

-- ── (b) LIGAR RLS nas 7 tabelas encontradas completamente desligadas ────────
alter table public.profiles          enable row level security;
alter table public.atletas           enable row level security;
alter table public.inscricoes        enable row level security;
alter table public.relatorios        enable row level security;
alter table public.gondomar_atletas  enable row level security;
alter table public.liga_jogadores    enable row level security;
alter table public.liga_jogos        enable row level security;

-- relatorios precisa de continuar legível pelo admin (admin360.html lê-a)
create policy sel_admin on public.relatorios for select to authenticated
  using (public.ytb_is_admin());

-- profiles/atletas/inscricoes/gondomar_atletas/liga_jogadores/liga_jogos:
-- zero páginas vivas, zero policies novas — RLS ligado + sem policies = deny-all
-- (continuam visíveis via SQL Editor/dashboard, que usa service_role)

-- ── (c) revogar escrita direta nas tabelas ainda tocáveis pelo cliente ──────
do $$
declare t text;
begin
  foreach t in array array[
    'atletas_360','atletas_360_avaliacoes','atletas_360_stats','atletas_360_historico',
    'atletas_360_match_reports','atletas_360_colaboradores','profiles','atletas',
    'inscricoes','relatorios','gondomar_atletas','liga_jogadores','liga_jogos',
    'sugestoes','treino_resultados','atleta_acesso','scout_creditos',
    'ytb_atletas','ytb_avaliacoes','ytb_comissoes','ytb_inscricoes',
    'ytb_notificacoes','ytb_pagamentos','ytb_utilizadores','ytb_competencias',
    'comissao_regras','pagamentos','ia_uso','atletas_360_analise','atletas_360_rate_limit'
  ] loop
    if to_regclass('public.'||t) is null then continue; end if;
    execute format('revoke insert, update, delete on public.%I from anon, authenticated', t);
    execute format('revoke select on public.%I from anon', t);
  end loop;
end $$;

-- nota: `authenticated` mantém SELECT ao nível de GRANT nalgumas destas tabelas
-- por herança do esquema original — mas sem policy nenhuma (ou só a
-- sel_admin acima), RLS bloqueia de qualquer forma. anon fica sem SELECT
-- em toda a lista, incluindo relatorios/pagamentos/etc.
