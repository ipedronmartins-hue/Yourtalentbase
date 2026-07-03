-- ============================================================================
-- MIGRAÇÃO 004 · LEGADO FORA
-- Elimina COMPLETAMENTE o caminho token/PIN (Constituição · nunca 4) e limpa
-- o armazenamento de passwords em texto simples. O acesso vivo é:
-- magic link + email do encarregado.
-- ============================================================================

drop function if exists public.ytb_consentir(uuid, text);
drop function if exists public.ytb_atleta_por_token(uuid);
drop function if exists public.ytb_acesso(text, text);
drop function if exists public.ytb_criar_acesso(uuid);
drop function if exists public.ytb_passaporte(uuid);
drop function if exists public.ytb_cognitivo(uuid);

drop table if exists public.sessao_familia;

alter table public.atletas_360 drop column if exists token_consentimento;

update public.atletas_360_clubes_subscritores
   set password_temporaria = null
 where password_temporaria is not null;