-- 045: ytb_epoca_fechar passa a arquivar minutos_epoca para o historico ao fechar a
-- epoca (antes desta correcao, minutos introduzidos durante a epoca eram perdidos).
CREATE OR REPLACE FUNCTION public.ytb_epoca_fechar(p_atleta uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  a record; v_ref text; v_curta text; v_prox text; v_resumo text;
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;

  select epoca_ref, divisao, golos_epoca, jogos_epoca, assist_epoca, minutos_epoca,
         golos_equipa_epoca, classificacao_equipa, clube_actual, escalao
    into a from public.atletas_360 where id = p_atleta;
  if not found then return jsonb_build_object('ok', false, 'motivo', 'atleta_invalido'); end if;

  v_ref := trim(coalesce(a.epoca_ref,''));
  if not (v_ref ~ '^(\d{2}|\d{4})/\d{2}$') then
    return jsonb_build_object('ok', false, 'motivo', 'sem_epoca');
  end if;
  v_curta := right(split_part(v_ref,'/',1), 2) || '/' || split_part(v_ref,'/',2);

  if a.golos_epoca is null and a.jogos_epoca is null and a.assist_epoca is null
     and a.minutos_epoca is null and a.golos_equipa_epoca is null and a.classificacao_equipa is null then
    return jsonb_build_object('ok', false, 'motivo', 'sem_estatisticas');
  end if;
  if coalesce(trim(a.clube_actual),'') = '' or coalesce(trim(a.escalao),'') = '' then
    return jsonb_build_object('ok', false, 'motivo', 'perfil_incompleto');
  end if;

  v_prox := ((split_part(v_ref,'/',1))::int + 1)::text
            || '/' ||
            lpad(((split_part(v_ref,'/',2))::int + 1)::text, 2, '0');
  if length(split_part(v_ref,'/',1)) = 2 then
    v_prox := lpad(((split_part(v_ref,'/',1))::int + 1)::text, 2, '0') || '/' || lpad(((split_part(v_ref,'/',2))::int + 1)::text, 2, '0');
  end if;

  insert into public.atletas_360_historico
    (atleta_id, epoca, clube, escalao, divisao, classificacao_texto,
     golos, jogos, assistencias, minutos, golos_equipa, created_at)
  values
    (p_atleta, v_curta, left(trim(a.clube_actual),80), left(trim(a.escalao),20),
     nullif(trim(coalesce(a.divisao,'')),''), nullif(trim(coalesce(a.classificacao_equipa,'')),''),
     a.golos_epoca, a.jogos_epoca, a.assist_epoca, a.minutos_epoca, a.golos_equipa_epoca, now())
  on conflict (atleta_id, epoca) do update set
    divisao             = coalesce(atletas_360_historico.divisao, excluded.divisao),
    classificacao_texto = coalesce(atletas_360_historico.classificacao_texto, excluded.classificacao_texto),
    golos               = coalesce(excluded.golos, atletas_360_historico.golos),
    jogos               = coalesce(excluded.jogos, atletas_360_historico.jogos),
    assistencias        = coalesce(excluded.assistencias, atletas_360_historico.assistencias),
    minutos             = coalesce(excluded.minutos, atletas_360_historico.minutos),
    golos_equipa        = coalesce(excluded.golos_equipa, atletas_360_historico.golos_equipa);

  update public.atletas_360 set
    golos_epoca = null, jogos_epoca = null, assist_epoca = null, minutos_epoca = null,
    golos_equipa_epoca = null, classificacao_equipa = null,
    epoca_ref = v_prox
  where id = p_atleta;

  v_resumo := 'Época ' || v_curta || ' fechada'
    || case when a.golos_epoca is not null then ' · ' || a.golos_epoca || ' golo' || case when a.golos_epoca = 1 then '' else 's' end else '' end
    || case when a.jogos_epoca is not null then ' em ' || a.jogos_epoca || ' jogo' || case when a.jogos_epoca = 1 then '' else 's' end else '' end;

  insert into public.atleta_eventos (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, payload)
  values (p_atleta, 'epoca_fechada', 'marco', v_resumo, 'familia', 'declarado', 3,
          jsonb_build_object('epoca', v_curta, 'golos', a.golos_epoca, 'jogos', a.jogos_epoca,
                             'assist', a.assist_epoca, 'minutos', a.minutos_epoca, 'golos_equipa', a.golos_equipa_epoca,
                             'classificacao', a.classificacao_equipa, 'proxima', v_prox));

  return jsonb_build_object('ok', true, 'epoca', v_curta, 'proxima', v_prox);
end $function$;
