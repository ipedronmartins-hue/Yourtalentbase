-- ============================================================================
-- MIGRAÇÃO 006 · FECHO DE LACUNAS REAIS DE PRODUÇÃO
-- Remove policies perigosas pré-existentes (encontradas por inspeção viva de
-- pg_policies), liga RLS nas tabelas que estavam desligadas, e fecha o
-- sistema paralelo legado. NÃO apaga nenhuma linha nem nenhuma tabela.
-- ============================================================================

-- (a) POLICIES PERIGOSAS PRÉ-EXISTENTES
drop policy if exists a360_staff on public.atletas_360;
drop policy if exists atletas_insercao_publica on public.atletas_360;
drop policy if exists atletas_update_autorizado on public.atletas_360;

drop policy if exists avaliacoes_insercao_publica on public.atletas_360_avaliacoes;
drop policy if exists avals_insert_scout on public.atletas_360_avaliacoes;
drop policy if exists avaliacoes_leitura_auth on public.atletas_360_avaliacoes;

drop policy if exists stats_staff on public.atletas_360_stats;
drop policy if exists stats_insercao_publica on public.atletas_360_stats;
drop policy if exists stats_insert_colaborador on public.atletas_360_stats;
drop policy if exists stats_update_colaborador on public.atletas_360_stats;

drop policy if exists historico_insercao_publica on public.atletas_360_historico;
drop policy if exists reports_insert_colaborador on public.atletas_360_match_reports;

drop policy if exists colab_insert_publico on public.atletas_360_colaboradores;
drop policy if exists colab_leitura_token on public.atletas_360_colaboradores;
drop policy if exists colab_update_proprio on public.atletas_360_colaboradores;

drop policy if exists ev_leitura_auth on public.atleta_eventos;

drop policy if exists ft_leitura_auth on public.familia_treinos;

drop policy if exists avctx_leitura_subscritor on public.avaliacoes_contextuais;

drop policy if exists relatorios_leitura_auth on public.relatorios;

drop policy if exists allow_anon_insert on public.sugestoes;
drop policy if exists insert_publico on public.sugestoes;
drop policy if exists select_publico on public.sugestoes;
drop policy if exists update_publico on public.sugestoes;
drop policy if exists delete_publico on public.sugestoes;

drop policy if exists open_pilot on public.treino_resultados;

drop policy if exists ytb_atletas_staff on public.ytb_atletas;
drop policy if exists aval_staff on public.ytb_avaliacoes;
drop policy if exists ytb_comissoes_staff on public.ytb_comissoes;
drop policy if exists ytb_inscricoes_staff on public.ytb_inscricoes;
drop policy if exists ytb_notificacoes_staff on public.ytb_notificacoes;
drop policy if exists ytb_pagamentos_staff on public.ytb_pagamentos;
drop policy if exists ytb_utilizadores_staff on public.ytb_utilizadores;
drop policy if exists comp_leitura on public.ytb_competencias;

-- (b) LIGAR RLS nas 7 tabelas que estavam completamente desligadas
alter table public.profiles          enable row level security;
alter table public.atletas           enable row level security;
alter table public.inscricoes        enable row level security;
alter table public.relatorios        enable row level security;
alter table public.gondomar_atletas  enable row level security;
alter table public.liga_jogadores    enable row level security;
alter table public.liga_jogos        enable row level security;

-- relatorios continua legível pelo admin (admin360.html lê-a)
drop policy if exists sel_admin on public.relatorios;
create policy sel_admin on public.relatorios for select to authenticated
  using (public.ytb_is_admin());

-- (c) revogar escrita direta e leitura anon nas tabelas ainda tocáveis
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