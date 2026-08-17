-- 091: evolucao_pct (atleta_passaporte) media so as avaliacoes do treinador,
-- divididas ao meio por data (ntile 2) -- nunca pesa treino registado. Com
-- poucos dias de avaliacao (caso real encontrado em produção: um atleta com
-- só 4 dias de avaliação), essa divisao e ruido estatistico, nao tendencia
-- -- e pode dar negativo mesmo com o atleta a treinar quase todos os dias
-- (consistencia=83/100, 25h de diario nesse caso).
--
-- O fundador foi direto: "um atleta que treina todos os dias praticamente
-- nao pode ter um valor a baixar" -- o passaporte nao pode ser so o que a
-- plataforma mediu por acaso, tem de ser um todo.
--
-- Fix: atleta_passaporte passa a wrapper fino sobre a view original
-- (renomeada para _atleta_passaporte_base, logica interna intocada -- zero
-- risco de re-escrever as outras 12 colunas a mao). So evolucao_pct e
-- ajustada: quando consistencia>=70 (treina na grande maioria das semanas),
-- o piso e 0 -- nunca aparece negativo. Consistencia baixa continua a poder
-- mostrar queda real. Testado em dry-run e em produção: caso real -1 -> 0,
-- 23 linhas preservadas nos dois lados, ytb_scouting360 com sessão real
-- de scout continua a devolver os mesmos 18 atletas.

alter view public.atleta_passaporte rename to _atleta_passaporte_base;

create view public.atleta_passaporte as
select
  atleta_id, treinabilidade, compromisso, nivel_competitivo,
  case
    when evolucao_pct is null then null
    when consistencia >= 70 then greatest(evolucao_pct, 0)
    else evolucao_pct
  end as evolucao_pct,
  consistencia, horas_treino_extra, adesao_plano, nivel_verificacao,
  dias_desde_avaliacao, confianca_dado, n_eventos, ultimo_evento
from public._atleta_passaporte_base;
