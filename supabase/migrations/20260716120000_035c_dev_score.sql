-- ============================================================================
-- MIGRAÇÃO 035c · YTB DEVELOPMENT SCORE (0-100)
--
-- Métrica própria da vaga "Objetivos, não treinos": mede DESENVOLVIMENTO,
-- nunca talento absoluto ("o Tomás passou de 41 para 68 em 8 meses" — não
-- interessa se é o melhor da equipa, interessa que está a evoluir).
--
-- GUARDAS CONSTITUCIONAIS (deliberadas, não as remover):
--   - _ytb_dev_score é INTERNA (prefixo _, SEM grant a nenhum role de
--     cliente) — só é alcançável por dentro de _ytb_passaporte_json (que
--     herda o controlo de acesso de cada wrapper: família/treinador/scout
--     autorizado) e de ytb_treinador_digest (só os atletas do próprio
--     treinador). NÃO existe RPC pública de score, NÃO existe listagem,
--     NÃO existe ranking — o score de um atleta compara-se apenas com o
--     histórico dele próprio. Nunca entra na montra pública.
--   - Sem dados mínimos devolve estado 'a_construir' — nunca um número
--     sem base ("O score constrói-se com o tempo").
--
-- Componentes (pesos re-escalados quando um componente não tem dados —
-- um componente ausente não conta zero, simplesmente não conta):
--   adesao       40  execuções de missões (atividade='plano') nas últimas 8
--                    semanas ÷ esperadas (2/semana desde a prescrição, cap 8)
--   consistencia 25  semanas ativas distintas ÷ semanas decorridas (cap 8)
--   tendencia    20  delta da média das avaliações do treinador (médias POR
--                    DIA — em produção há submissões duplicadas segundos
--                    umas das outras, confirmado: colapsam por date_trunc).
--                    −0.5 pts (1-5) → 0; 0 → neutro; +0.5 → máximo.
--                    Fonte: treinador_avaliacoes.criterios (a única fonte
--                    de tendência VIVA — atletas_360_avaliacoes não tem
--                    nenhum caminho de escrita desde a migração 006).
--   cognitivo    15  acerto no Elite Coach (últimos 60 dias, mín. 3
--                    respostas — só funciona a partir da 035a, que reparou
--                    a escrita de elite_coach_resultados morta desde a 009)
--
-- Também nesta migração:
--   - _ytb_passaporte_json ganha a chave 'dev_score' (herda o acesso).
--   - ytb_treinador_digest ganha 'dev_score' e 'ultimo_checkin_jogo'
--     (dificuldade do último check-in — alimenta a prioridade do briefing
--     de segunda), e corrige a mistura de escalas em confianca_media
--     (valores ≤5 vinham do feedback 1-5, os restantes do registar 0-100;
--     a média cega das duas escalas estava corrompida desde a 013).
--
-- Validado em dry-run (2026-07-16) com os atletas reais: Vasco (2 dias de
-- avaliação + atividade) recebe score; Tomás CM/Nuno (1 dia de avaliação,
-- 1 semana ativa) ficam 'a_construir'; scores discriminam entre atletas.
-- ============================================================================

create or replace function public._ytb_dev_score(v_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_dias_aval int;            -- dias DISTINTOS com avaliação do treinador
  v_semanas_ativas int;
  v_prescrito_em timestamptz;
  v_primeira_atividade timestamptz;
  v_primeira_aval timestamptz;
  v_exec_8s int; v_esperadas numeric;
  v_semanas_decorridas numeric;
  v_media_primeiro_dia numeric; v_media_ultimo_dia numeric; v_delta numeric;
  v_cog_total int; v_cog_certos int;
  r_adesao numeric; r_consistencia numeric; r_tendencia numeric; r_cognitivo numeric;
  v_soma numeric := 0; v_pesos numeric := 0;
  v_score int; v_tend text;
  comp jsonb := '{}'::jsonb;
begin
  -- sinais base
  select count(distinct date_trunc('day', criado_em)), min(criado_em)
    into v_dias_aval, v_primeira_aval
    from public.treinador_avaliacoes where atleta_id = v_atleta;

  select count(distinct date_trunc('week', created_at)), min(created_at)
    into v_semanas_ativas, v_primeira_atividade
    from public.familia_treinos where atleta_id = v_atleta;

  -- portão de dados mínimos: ≥2 dias distintos de avaliação OU ≥4 semanas ativas
  if coalesce(v_dias_aval,0) < 2 and coalesce(v_semanas_ativas,0) < 4 then
    return jsonb_build_object('estado', 'a_construir',
      'dias_avaliacao', coalesce(v_dias_aval,0), 'semanas_ativas', coalesce(v_semanas_ativas,0));
  end if;

  -- ADESÃO (peso 40): execuções de plano nas últimas 8 semanas vs esperadas
  select max(criado_em) into v_prescrito_em from public.treinador_treinos where atleta_id = v_atleta;
  if v_prescrito_em is not null then
    select count(*) into v_exec_8s from public.familia_treinos
     where atleta_id = v_atleta and atividade = 'plano'
       and created_at >= now() - interval '8 weeks';
    v_semanas_decorridas := least(8, greatest(1, ceil(extract(epoch from (now() - v_prescrito_em)) / 604800.0)));
    v_esperadas := 2 * v_semanas_decorridas;  -- 2 missões técnicas/semana
    r_adesao := least(1, v_exec_8s / v_esperadas);
    v_soma := v_soma + 40 * r_adesao; v_pesos := v_pesos + 40;
    comp := comp || jsonb_build_object('adesao', jsonb_build_object('feitas', v_exec_8s, 'esperadas', v_esperadas, 'ratio', round(r_adesao,2)));
  end if;

  -- CONSISTÊNCIA (peso 25): semanas ativas vs decorridas (janela 8 semanas)
  if v_primeira_atividade is not null then
    declare v_sem_ativas_8 int; v_decorridas numeric;
    begin
      select count(distinct date_trunc('week', created_at)) into v_sem_ativas_8
        from public.familia_treinos
       where atleta_id = v_atleta and created_at >= now() - interval '8 weeks';
      v_decorridas := least(8, greatest(1, ceil(extract(epoch from (now() - greatest(v_primeira_atividade, now() - interval '8 weeks'))) / 604800.0)));
      r_consistencia := least(1, v_sem_ativas_8 / v_decorridas);
      v_soma := v_soma + 25 * r_consistencia; v_pesos := v_pesos + 25;
      comp := comp || jsonb_build_object('consistencia', jsonb_build_object('semanas_ativas', v_sem_ativas_8, 'de', v_decorridas, 'ratio', round(r_consistencia,2)));
    end;
  end if;

  -- TENDÊNCIA (peso 20): delta entre a média do primeiro e do último DIA de avaliação
  if coalesce(v_dias_aval,0) >= 2 then
    with por_dia as (
      select date_trunc('day', av.criado_em) as dia,
             avg((select avg(public.ytb_num(value)) from jsonb_each_text(coalesce(av.criterios,'{}'::jsonb)))) as media
        from public.treinador_avaliacoes av
       where av.atleta_id = v_atleta
       group by 1
    )
    select (select media from por_dia order by dia asc limit 1),
           (select media from por_dia order by dia desc limit 1)
      into v_media_primeiro_dia, v_media_ultimo_dia;
    if v_media_primeiro_dia is not null and v_media_ultimo_dia is not null then
      v_delta := v_media_ultimo_dia - v_media_primeiro_dia;         -- em pontos 1-5
      r_tendencia := greatest(0, least(1, (v_delta + 0.5) / 1.0));  -- −0.5→0 · 0→0.5 · +0.5→1
      v_tend := case when v_delta > 0.05 then 'subiu' when v_delta < -0.05 then 'desceu' else 'estavel' end;
      v_soma := v_soma + 20 * r_tendencia; v_pesos := v_pesos + 20;
      comp := comp || jsonb_build_object('tendencia', jsonb_build_object('delta', round(v_delta,2), 'de', round(v_media_primeiro_dia,2), 'para', round(v_media_ultimo_dia,2)));
    end if;
  end if;

  -- COGNITIVO (peso 15): acerto no Elite Coach, últimos 60 dias, mínimo 3 respostas
  select count(*), count(*) filter (where correto)
    into v_cog_total, v_cog_certos
    from public.elite_coach_resultados
   where atleta_id = v_atleta and created_at >= now() - interval '60 days';
  if coalesce(v_cog_total,0) >= 3 then
    r_cognitivo := v_cog_certos::numeric / v_cog_total;
    v_soma := v_soma + 15 * r_cognitivo; v_pesos := v_pesos + 15;
    comp := comp || jsonb_build_object('cognitivo', jsonb_build_object('certos', v_cog_certos, 'total', v_cog_total));
  end if;

  if v_pesos = 0 then
    return jsonb_build_object('estado', 'a_construir',
      'dias_avaliacao', coalesce(v_dias_aval,0), 'semanas_ativas', coalesce(v_semanas_ativas,0));
  end if;

  v_score := round(100 * v_soma / v_pesos);
  return jsonb_build_object(
    'estado', 'ok',
    'score', v_score,
    'tendencia', v_tend,
    'componentes', comp,
    'desde', least(coalesce(v_primeira_aval, now()), coalesce(v_primeira_atividade, now()))::date
  );
end $$;
-- SEM grant: função interna, inalcançável por clientes — só via wrappers com
-- controlo de acesso próprio. É esta a guarda anti-ranking/anti-montra.

-- ── _ytb_passaporte_json ganha 'dev_score' (mantém tudo o resto da 024) ──
create or replace function public._ytb_passaporte_json(v_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare j jsonb;
begin
  select jsonb_build_object(
    'identidade', jsonb_build_object(
      'nome', a.nome, 'posicao', a.posicao_principal, 'clube', a.clube_actual,
      'escalao', a.escalao, 'associacao', a.associacao,
      'foto', (case when coalesce(a.foto_consentida,false) then a.foto_path else null end)),
    'indicadores', (select to_jsonb(p) - 'atleta_id'
                    from public.atleta_passaporte p where p.atleta_id = v_atleta),
    'densidade', jsonb_build_object(
      'eventos',      (select count(*) from public.atleta_eventos e where e.atleta_id = v_atleta),
      'avaliacoes',   (select count(*) from public.atleta_eventos e where e.atleta_id = v_atleta and e.tipo = 'avaliacao'),
      'observadores', (select count(distinct e.fonte) from public.atleta_eventos e where e.atleta_id = v_atleta and e.origem = 'observado'),
      'epocas',       (select count(distinct date_part('year', e.criado_em)) from public.atleta_eventos e where e.atleta_id = v_atleta),
      'interesses',   (select count(*) from public.atleta_eventos e where e.atleta_id = v_atleta and e.tipo = 'interesse_clube')),
    'evolucao_serie', (
      select coalesce(jsonb_agg(jsonb_build_object(
               't', av.created_at,
               'v', round(coalesce(public.ytb_num(av.rating), (coalesce(public.ytb_num(av.dim_treinabilidade),0)+coalesce(public.ytb_num(av.dim_compromisso),0))/2.0) * 20)
             ) order by av.created_at), '[]'::jsonb)
      from public.atletas_360_avaliacoes av where av.atleta_id = v_atleta),
    'marcos', (
      select coalesce(jsonb_agg(jsonb_build_object('titulo', e.titulo, 'em', e.criado_em)
                      order by e.criado_em desc), '[]'::jsonb)
      from public.atleta_eventos e where e.atleta_id = v_atleta and e.categoria = 'marco'),
    'carreira', (
      select coalesce(jsonb_agg(jsonb_build_object('epoca', h.epoca) order by h.created_at desc), '[]'::jsonb)
      from public.atletas_360_historico h where h.atleta_id = v_atleta),
    'timeline', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select jsonb_build_object(
                 'categoria', e.categoria, 'origem', e.origem, 'titulo', e.titulo,
                 'fonte', e.fonte, 'em', e.criado_em, 'impacto', e.impacto) as t
        from public.atleta_eventos e where e.atleta_id = v_atleta
        order by e.relevancia desc nulls last, e.criado_em desc
        limit 12) s),
    'atividade', jsonb_build_object(
      'prescritos', (select coalesce(sum(coalesce((t.plano->>'sessoes')::int,1)),0) from public.treinador_treinos t where t.atleta_id = v_atleta),
      'concluidos', (select count(*) from public.familia_treinos f where f.atleta_id = v_atleta and f.prescrito_id is not null),
      'execucoes',  (select count(*) from public.familia_treinos f where f.atleta_id = v_atleta),
      'ultima',     (select max(f.created_at) from public.familia_treinos f where f.atleta_id = v_atleta),
      'semanas_ativas', (select count(distinct date_trunc('week', f.created_at)) from public.familia_treinos f where f.atleta_id = v_atleta)),
    'cognitivo', jsonb_build_object(
      'total',      (select count(*) from public.elite_coach_resultados r where r.atleta_id = v_atleta),
      'acerto_pct', (select round(100.0*avg((r.correto)::int)) from public.elite_coach_resultados r where r.atleta_id = v_atleta),
      'por_tipo', (select coalesce(jsonb_agg(jsonb_build_object('cenario',t.cenario,'total',t.total,'acerto_pct',t.acerto) order by t.total desc),'[]'::jsonb)
                   from (select coalesce(cenario_id,'—') cenario, count(*) total, round(100.0*avg((correto)::int)) acerto
                         from public.elite_coach_resultados where atleta_id=v_atleta group by coalesce(cenario_id,'—')) t),
      'serie', (select coalesce(jsonb_agg(jsonb_build_object('t',m.mes,'v',m.acerto) order by m.mes),'[]'::jsonb)
                from (select date_trunc('month',created_at) mes, round(100.0*avg((correto)::int)) acerto
                      from public.elite_coach_resultados where atleta_id=v_atleta group by date_trunc('month',created_at)) m)),
    'relatorios', (
      select coalesce(jsonb_agg(jsonb_build_object('fonte', e.fonte, 'titulo', e.titulo, 'em', e.criado_em) order by e.criado_em desc), '[]'::jsonb)
      from public.atleta_eventos e where e.atleta_id = v_atleta and e.origem = 'observado' and e.tipo = 'scout_report'),
    'maturacao', public._ytb_maturacao(v_atleta),
    'dev_score', public._ytb_dev_score(v_atleta),
    'media', jsonb_build_object(
      'video',   (select case when coalesce(a2.video_consentido,false) then a2.video_path else null end from public.atletas_360 a2 where a2.id = v_atleta),
      'galeria', '[]'::jsonb)
  ) into j
  from public.atletas_360 a where a.id = v_atleta;
  return j;
end $$;

-- ── digest do treinador: + dev_score, + último check-in de jogo, e corrige
--    a média de confiança (escalas mistas 1-5 / 0-100 desde a 013) ──
create or replace function public.ytb_treinador_digest()
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; j jsonb;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public.ytb_is_treinador() then return null; end if;

  select coalesce(jsonb_agg(linha order by (linha->>'ultima_atividade') desc nulls last), '[]'::jsonb)
    into j
  from (
    select jsonb_build_object(
      'atleta_id', a.id,
      'nome', a.nome,
      'escalao', a.escalao,
      'dias_desde_avaliacao',
        (select (now()::date - max(av.criado_em)::date)
           from public.treinador_avaliacoes av
          where av.atleta_id = a.id and lower(coalesce(av.treinador_email,'')) = v_email),
      'plano_prescrito_em',
        (select max(t.criado_em) from public.treinador_treinos t where t.atleta_id = a.id),
      'execucoes_desde_plano',
        (select count(*) from public.familia_treinos f
          where f.atleta_id = a.id
            and f.created_at > coalesce((select max(t.criado_em) from public.treinador_treinos t
                                          where t.atleta_id = a.id), '-infinity'::timestamptz)),
      'execucoes_total',
        (select count(*) from public.familia_treinos f where f.atleta_id = a.id),
      'confianca_media',
        -- normaliza escalas mistas: valores ≤5 vieram do feedback (1-5) → ×20
        (select round(avg(case when f.confianca <= 5 then f.confianca * 20 else f.confianca end)) from (
           select confianca from public.familia_treinos
            where atleta_id = a.id and confianca is not null
            order by created_at desc limit 10) f),
      'ultimo_feedback',
        (select f.feedback from public.familia_treinos f
          where f.atleta_id = a.id and coalesce(trim(f.feedback),'') <> ''
          order by f.created_at desc limit 1),
      'ultima_atividade',
        (select max(f.created_at) from public.familia_treinos f where f.atleta_id = a.id),
      'ultimo_checkin_jogo',
        (select jsonb_build_object('em', f.created_at, 'dificuldade', (f.resultado->>'dificuldade')::int, 'nota', f.feedback)
           from public.familia_treinos f
          where f.atleta_id = a.id and f.atividade = 'jogo'
          order by f.created_at desc limit 1),
      'dev_score', public._ytb_dev_score(a.id)
    ) as linha
    from public.atletas_360 a
    where lower(coalesce(a.fonte_email,'')) = v_email
       or exists (select 1 from public.treinador_avaliacoes av
                   where av.atleta_id = a.id and lower(coalesce(av.treinador_email,'')) = v_email)
  ) s;

  return j;
end $$;
