-- ============================================================================
-- 059 · fecha OUTRA VEZ o _ytb_passaporte_json exposto por omissão
-- ----------------------------------------------------------------------------
-- Mesma falha da migração 056 (fechada há horas), reaberta pela 057
-- (avaliação contextual entra no passaporte): essa migração mudou a
-- assinatura de _ytb_passaporte_json de (uuid, boolean) para
-- (uuid, boolean, boolean) — DROP+CREATE correto para o problema que
-- resolvia (evitar sobrecarga ambígua), mas assinatura nova = função nova
-- aos olhos do Postgres, e nasceu outra vez com EXECUTE por omissão a
-- PUBLIC, sem herdar o revoke da 056. Confirmado em produção antes deste
-- ficheiro: anon conseguia chamar a versão de 3 parâmetros diretamente.
--
-- Padrão a partir de agora: sempre que _ytb_passaporte_json mudar de
-- assinatura (e vai voltar a mudar), o revoke tem de ser reaplicado à
-- assinatura nova na MESMA migração que a cria — não depois, numa
-- migração à parte como esta.
-- ============================================================================

revoke all on function public._ytb_passaporte_json(uuid, boolean, boolean) from public, anon, authenticated;
