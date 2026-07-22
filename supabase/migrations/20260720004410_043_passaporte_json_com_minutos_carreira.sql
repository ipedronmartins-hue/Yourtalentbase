-- 043: _ytb_passaporte_json (vista central do passaporte, usada por todos os rostos)
-- passa a incluir minutos no bloco carreira.
CREATE OR REPLACE FUNCTION public._ytb_passaporte_json(v_atleta uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
      from public.atleta_eventos e
      where e.atleta_id = v_atleta and e.categoria = 'marco'
        and e.tipo not in ('atualizacao_admin','estado_admin')),
    'carreira', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'epoca', h.epoca, 'clube', h.clube, 'escalao', h.escalao,
               'divisao', h.divisao, 'classificacao', h.classificacao_texto,
               'golos', h.golos, 'jogos', h.jogos, 'assist', h.assistencias, 'minutos', h.minutos, 'golos_equipa', h.golos_equipa,
               'titulos', to_jsonb(coalesce(h.titulos, array[]::text[]))
             ) order by h.epoca desc), '[]'::jsonb)
      from public.atletas_360_historico h where h.atleta_id = v_atleta),
    'timeline', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select jsonb_build_object(
                 'categoria', e.categoria, 'origem', e.origem, 'titulo', e.titulo,
                 'fonte', e.fonte, 'em', e.criado_em, 'impacto', e.impacto) as t
        from public.atleta_eventos e where e.atleta_id = v_atleta
          and e.tipo not in ('atualizacao_admin','estado_admin')
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
end $function$;
