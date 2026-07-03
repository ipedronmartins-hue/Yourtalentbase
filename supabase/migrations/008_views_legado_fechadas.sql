-- MIGRAÇÃO 008 · VIEWS LEGADO FECHADAS (aplicada em prod)
revoke select on public.v_descoberta_anonima from anon, authenticated;
revoke select on public.v_pagamentos_mensal  from anon, authenticated;
revoke select on public.v_pontos_evolucao    from anon, authenticated;
alter view public.v_descoberta_anonima set (security_invoker = on);
alter view public.v_pagamentos_mensal  set (security_invoker = on);
alter view public.v_pontos_evolucao    set (security_invoker = on);
