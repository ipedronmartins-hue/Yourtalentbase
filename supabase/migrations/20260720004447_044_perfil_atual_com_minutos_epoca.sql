-- 044: ytb_familia_perfil_atual passa a devolver minutos_epoca (pre-preenchimento do formulario).
CREATE OR REPLACE FUNCTION public.ytb_familia_perfil_atual(p_atleta uuid)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin() then
    (select jsonb_build_object(
      'clube_actual', clube_actual, 'equipa', equipa, 'escalao', escalao, 'associacao', associacao,
      'posicao_principal', posicao_principal, 'pe_dominante', pe_dominante,
      'zerozero_url', zerozero_url, 'joga_plus_url', joga_plus_url,
      'encarregado_nome', encarregado_nome, 'encarregado_telefone', encarregado_telefone,
      'epoca_ref', epoca_ref, 'divisao', divisao, 'golos_epoca', golos_epoca, 'jogos_epoca', jogos_epoca,
      'assist_epoca', assist_epoca, 'minutos_epoca', minutos_epoca, 'golos_equipa_epoca', golos_equipa_epoca, 'classificacao_equipa', classificacao_equipa
    ) from public.atletas_360 where id = p_atleta)
  else null end
$function$;
