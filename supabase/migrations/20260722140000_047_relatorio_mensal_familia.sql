-- 047: relatorio mensal a familia — a "peca central de valor" das regras de produto,
-- e o artefacto que a academia envia ao pai como prova da mensalidade.
-- Separa explicitamente o observado (avaliacoes de treinador) do declarado
-- (atividade/missoes = compromisso, nunca prova). Proveniencia no rodape.
CREATE OR REPLACE FUNCTION public.ytb_relatorio_mensal(p_atleta uuid, p_ano int, p_mes int)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_ini date; v_fim date; j jsonb;
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_ano < 2020 or p_ano > 2100 or p_mes < 1 or p_mes > 12 then
    return jsonb_build_object('ok', false, 'motivo', 'periodo_invalido');
  end if;
  v_ini := make_date(p_ano, p_mes, 1);
  v_fim := (v_ini + interval '1 month')::date;

  select jsonb_build_object(
    'ok', true,
    'periodo', jsonb_build_object('ano', p_ano, 'mes', p_mes),
    'identidade', (select jsonb_build_object(
        'nome', a.nome, 'escalao', a.escalao, 'clube', a.clube_actual,
        'posicao', a.posicao_principal, 'epoca_ref', a.epoca_ref)
      from public.atletas_360 a where a.id = p_atleta),
    'atividade', jsonb_build_object(
      'execucoes', (select count(*) from public.familia_treinos f
                     where f.atleta_id = p_atleta and f.created_at >= v_ini and f.created_at < v_fim),
      'das_quais_prescritas', (select count(*) from public.familia_treinos f
                     where f.atleta_id = p_atleta and f.prescrito_id is not null
                       and f.created_at >= v_ini and f.created_at < v_fim),
      'semanas_ativas', (select count(distinct date_trunc('week', f.created_at)) from public.familia_treinos f
                     where f.atleta_id = p_atleta and f.created_at >= v_ini and f.created_at < v_fim),
      'prescritos_no_mes', (select count(*) from public.treinador_treinos t
                     where t.atleta_id = p_atleta and t.criado_em >= v_ini and t.criado_em < v_fim)),
    'avaliacoes', (select coalesce(jsonb_agg(jsonb_build_object(
        'em', av.data_observacao, 'por', av.avaliador_nome, 'contexto', av.contexto_jogo,
        'impacto', av.dim_impacto, 'compromisso', av.dim_compromisso,
        'treinabilidade', av.dim_treinabilidade, 'competitividade', av.dim_competitividade,
        'observacao', av.observacao
      ) order by av.data_observacao), '[]'::jsonb)
      from public.atletas_360_avaliacoes av
      where av.atleta_id = p_atleta and av.created_at >= v_ini and av.created_at < v_fim
        and coalesce(av.estado,'') not in ('rejeitado','rascunho')),
    'biometria', jsonb_build_object(
      'atual', (select jsonb_build_object('altura_cm', b.altura_cm, 'peso_kg', b.peso_kg, 'em', b.medido_em)
                from public.atleta_biometria b
                where b.atleta_id = p_atleta and b.medido_em < v_fim
                order by b.medido_em desc limit 1),
      'anterior', (select jsonb_build_object('altura_cm', b.altura_cm, 'peso_kg', b.peso_kg, 'em', b.medido_em)
                from public.atleta_biometria b
                where b.atleta_id = p_atleta and b.medido_em < v_ini
                order by b.medido_em desc limit 1)),
    'marcos', (select coalesce(jsonb_agg(jsonb_build_object('titulo', e.titulo, 'em', e.criado_em, 'origem', e.origem)
                order by e.criado_em), '[]'::jsonb)
      from public.atleta_eventos e
      where e.atleta_id = p_atleta and e.categoria = 'marco'
        and e.tipo not in ('atualizacao_admin','estado_admin')
        and e.criado_em >= v_ini and e.criado_em < v_fim),
    'proveniencia', jsonb_build_object(
      'eventos_no_mes', (select count(*) from public.atleta_eventos e
          where e.atleta_id = p_atleta and e.criado_em >= v_ini and e.criado_em < v_fim
            and e.tipo not in ('atualizacao_admin','estado_admin')),
      'eventos_total', (select count(*) from public.atleta_eventos e
          where e.atleta_id = p_atleta and e.tipo not in ('atualizacao_admin','estado_admin')),
      'observadores_distintos', (select count(distinct av.avaliador_email) from public.atletas_360_avaliacoes av
          where av.atleta_id = p_atleta),
      'primeiro_registo', (select min(e.criado_em)::date from public.atleta_eventos e where e.atleta_id = p_atleta)),
    'dev_score', public._ytb_dev_score(p_atleta)
  ) into j;

  return j;
end $function$;
