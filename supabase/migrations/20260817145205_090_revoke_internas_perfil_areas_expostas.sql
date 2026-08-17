-- 090: mesma classe de falha das migrações 040/058/074 — funções internas
-- (prefixo _, nunca supostas chamáveis diretamente) nasceram com o EXECUTE
-- por omissão do Postgres a PUBLIC/authenticated e nunca foram fechadas.
--
-- Achado grave: _ytb_perfil_areas(uuid) e _ytb_evolucao_semanal_areas(uuid)
-- (migrações 086/087) aceitam um atleta_id em bruto e devolvem as 5 notas
-- de área (técnica/decisão/tática/físico/mental) e a evolução semanal desse
-- atleta, SEM nenhuma verificação de posse — qualquer utilizador autenticado
-- (qualquer família, treinador ou scout, de qualquer academia) podia chamar
-- /rest/v1/rpc/_ytb_perfil_areas com o UUID de outra criança e receber as
-- classificações dela diretamente. Viola a regra "nunca expor notas de
-- menores" da Constituição. Nenhum destes é chamado do frontend (só de
-- dentro de _ytb_passaporte_json, que é security definer) — o revoke não
-- quebra nada.
--
-- Também fechados por coerência com a convenção: _ytb_nome_publico (resolve
-- nome real a partir de email arbitrário — podia contornar o "admin nunca
-- aparece com nome pessoal à família"), _ytb_e_treinador_estrito (baixo
-- risco, só revela o próprio papel) e _ytb_debilidade_dominio (sem risco,
-- lookup puro, fechado só por convenção).

revoke all on function public._ytb_perfil_areas(uuid) from public, anon, authenticated;
revoke all on function public._ytb_evolucao_semanal_areas(uuid) from public, anon, authenticated;
revoke all on function public._ytb_nome_publico(text,text) from public, anon, authenticated;
revoke all on function public._ytb_e_treinador_estrito() from public, anon, authenticated;
revoke all on function public._ytb_debilidade_dominio(text) from public, anon, authenticated;
