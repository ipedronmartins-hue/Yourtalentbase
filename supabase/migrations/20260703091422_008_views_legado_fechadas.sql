-- ============================================================================
-- MIGRAÇÃO 008 · VIEWS LEGADO FECHADAS
-- Views herdam os privilégios do DONO por omissão (contornam RLS). Três views
-- do sistema antigo tinham SELECT concedido a clientes:
--   · v_descoberta_anonima  → anon+authenticated: dados de menores (ano,
--     posição, escalão, pé, stats) pseudo-anonimizados por token_ocultar
--   · v_pontos_evolucao     → authenticated: scores + altura_cm +
--     altura_adulta_cm (dados de maturação — categoria mais protegida)
--   · v_pagamentos_mensal   → authenticated: finanças da empresa
-- Zero páginas vivas as utilizam (verificado por grep). Dados intactos;
-- acesso de cliente removido. security_invoker=on como defesa em profundidade
-- (se algum grant voltar, o RLS das tabelas de base volta a mandar).
-- ============================================================================

revoke select on public.v_descoberta_anonima from anon, authenticated;
revoke select on public.v_pagamentos_mensal  from anon, authenticated;
revoke select on public.v_pontos_evolucao    from anon, authenticated;

alter view public.v_descoberta_anonima set (security_invoker = on);
alter view public.v_pagamentos_mensal  set (security_invoker = on);
alter view public.v_pontos_evolucao    set (security_invoker = on);

-- nota: a coluna atletas_360.token_ocultar (resto do paradigma token) fica
-- anotada para remoção no M2 — não se dropa coluna sem varrer o site real.