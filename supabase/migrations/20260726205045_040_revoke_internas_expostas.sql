-- ============================================================================
-- 056 · fechar funções internas expostas por omissão do Postgres
-- ----------------------------------------------------------------------------
-- Auditoria 2026-07-26 (pré-piloto), complementar à migração 048: a 048
-- mudou _ytb_passaporte_json para (uuid, v_incluir_sensiveis) de propósito,
-- para fechar "clube/scout/treinador veem maturação" — mas assinatura nova
-- = função nova aos olhos do Postgres, e nasceu com o EXECUTE por omissão a
-- PUBLIC, sem herdar o revoke que a versão de 1 parâmetro tinha desde a
-- migração 018. A 048 fechou QUEM vê os dados através do wrapper certo; não
-- fechou a PORTA em si — qualquer pessoa sem sessão, com o UUID de um
-- atleta, continuava a poder chamar /rest/v1/rpc/_ytb_passaporte_json
-- diretamente e saltar o wrapper todo, recebendo o passaporte inteiro (nome,
-- clube, timeline, carreira, scout reports, dev_score e, com a flag,
-- maturação). _ytb_maturacao tinha o mesmo problema isolado. Mais 6 funções
-- internas (prefixo _, nunca supostas chamáveis diretamente) estavam com o
-- mesmo grant por omissão — sem dados sensíveis próprios, mas fecham-se por
-- coerência com a convenção.
--
-- Este ficheiro só aperta grants (revoke). Os wrappers públicos que já
-- chamam estas funções internamente (ytb_passaporte_email,
-- ytb_passaporte_treinador, ytb_passaporte_admin, etc.) são todos security
-- definer — continuam a funcionar, porque o dono da função mantém sempre
-- execute sobre o que é seu. Mesmo padrão já usado e provado na migração
-- 037 para _ytb_dev_score.
-- ============================================================================

revoke all on function public._ytb_passaporte_json(uuid, boolean) from public, anon, authenticated;
revoke all on function public._ytb_maturacao(uuid) from public, anon, authenticated;
revoke all on function public._ytb_notificar_admin(text, text, text) from public, anon, authenticated;
revoke all on function public._ytb_e_encarregado(uuid) from public, anon, authenticated;
revoke all on function public._ytb_e_clube() from public, anon, authenticated;
revoke all on function public._ytb_streak_marco(uuid) from public, anon, authenticated;
revoke all on function public._ytb_trig_notificar_inscricao() from public, anon, authenticated;
revoke all on function public._ytb_trig_notificar_pedido_contacto() from public, anon, authenticated;
revoke all on function public._ytb_trig_notificar_registo_treinador() from public, anon, authenticated;
