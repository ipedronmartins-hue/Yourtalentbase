-- ============================================================================
-- MIGRAÇÃO 003 · LEGADO FORA
-- ----------------------------------------------------------------------------
-- Elimina COMPLETAMENTE o caminho token/PIN (Constituição · nunca 4) e limpa
-- o armazenamento de passwords em texto simples (nunca segredos no repositório
-- ou na base fora do Auth). O acesso vivo é: magic link + email do encarregado.
-- ============================================================================

-- funções do caminho antigo (todas com grant a anon — superfície dormente)
drop function if exists public.ytb_consentir(uuid, text);
drop function if exists public.ytb_atleta_por_token(uuid);
drop function if exists public.ytb_acesso(text, text);
drop function if exists public.ytb_criar_acesso(uuid);
drop function if exists public.ytb_passaporte(uuid);
drop function if exists public.ytb_cognitivo(uuid);

-- tabela de sessões por token
drop table if exists public.sessao_familia;

-- coluna do token de consentimento embebível em links
alter table public.atletas_360 drop column if exists token_consentimento;

-- passwords temporárias em texto simples: purga de valores (a coluna fica,
-- vazia, para não partir selects antigos; nunca mais é escrita — ver 002)
update public.atletas_360_clubes_subscritores
   set password_temporaria = null
 where password_temporaria is not null;
