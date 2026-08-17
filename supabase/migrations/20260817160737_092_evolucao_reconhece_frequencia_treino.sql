-- 092: complemento a 091. So evitar que a evolucao desca (piso 0) nao chega
-- -- o fundador apontou o risco certo: sem reconhecimento real, um atleta
-- que treina muito e so ve "0%" tem incentivo para comecar a inflacionar o
-- diario. Quem treina 4+ vezes por semana em media (ultimas 8 semanas) passa
-- a ter um piso positivo real (5%), nao so "nao negativo". Consistencia alta
-- mas com menos de 4x/semana mantem o piso 0 da 091. Testado em dry-run e em
-- produção: caso real com 4.8 treinos/semana -> evolucao final +5 (era -1
-- bruto), ytb_scouting360 com sessão real de scout continua a devolver os
-- mesmos 18 atletas.

create or replace view public.atleta_passaporte as
select
  b.atleta_id, b.treinabilidade, b.compromisso, b.nivel_competitivo,
  case
    when b.evolucao_pct is null then null
    when (select count(*) from atleta_eventos e where e.atleta_id=b.atleta_id and e.tipo='treino_executado' and e.criado_em >= now()-interval '56 days') / 8.0 >= 4
      then greatest(b.evolucao_pct, 5)
    when b.consistencia >= 70 then greatest(b.evolucao_pct, 0)
    else b.evolucao_pct
  end as evolucao_pct,
  b.consistencia, b.horas_treino_extra, b.adesao_plano, b.nivel_verificacao,
  b.dias_desde_avaliacao, b.confianca_dado, b.n_eventos, b.ultimo_evento
from public._atleta_passaporte_base b;
