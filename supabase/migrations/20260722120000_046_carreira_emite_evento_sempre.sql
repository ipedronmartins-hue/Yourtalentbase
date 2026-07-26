-- 046: ytb_carreira_registar so emitia evento no livro-razao quando vinha titulo.
-- Constituicao, Regra Tecnica 1: "todo o facto longitudinalmente relevante emite
-- evento... sem excecoes." Uma epoca de carreira e claramente um facto relevante
-- mesmo sem titulo -- corrigido para emitir sempre.
CREATE OR REPLACE FUNCTION public.ytb_carreira_registar(
  p_atleta uuid, p_epoca text, p_clube text, p_escalao text, p_divisao text DEFAULT NULL::text,
  p_classificacao text DEFAULT NULL::text, p_titulo text DEFAULT NULL::text, p_equipa text DEFAULT NULL::text,
  p_golos integer DEFAULT NULL::integer, p_jogos integer DEFAULT NULL::integer, p_assistencias integer DEFAULT NULL::integer,
  p_minutos integer DEFAULT NULL::integer
) RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id uuid; v_titulos text[]; v_titulo text; v_novo boolean;
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if coalesce(trim(p_epoca),'') = '' or not (trim(p_epoca) ~ '^\d{2}/\d{2}$') then
    return jsonb_build_object('ok', false, 'motivo', 'epoca_invalida');
  end if;
  if coalesce(trim(p_clube),'') = '' or coalesce(trim(p_escalao),'') = '' then
    return jsonb_build_object('ok', false, 'motivo', 'clube_escalao_obrigatorios');
  end if;
  if p_minutos is not null and (p_minutos < 0 or p_minutos > 9000) then
    return jsonb_build_object('ok', false, 'motivo', 'minutos_invalidos');
  end if;

  v_titulo := left(nullif(trim(coalesce(p_titulo,'')),''), 80);
  v_novo := not exists(select 1 from public.atletas_360_historico where atleta_id=p_atleta and epoca=trim(p_epoca));

  insert into public.atletas_360_historico
    (atleta_id, epoca, clube, escalao, equipa, divisao, classificacao_texto, titulos,
     golos, jogos, assistencias, minutos, created_at)
  values
    (p_atleta, trim(p_epoca), left(trim(p_clube),80), left(trim(p_escalao),20),
     left(nullif(trim(coalesce(p_equipa,'')),''),60),
     left(nullif(trim(coalesce(p_divisao,'')),''),60),
     left(nullif(trim(coalesce(p_classificacao,'')),''),60),
     case when v_titulo is not null then array[v_titulo] else null end,
     greatest(coalesce(p_golos,0),0), greatest(coalesce(p_jogos,0),0), greatest(coalesce(p_assistencias,0),0),
     p_minutos, now())
  on conflict (atleta_id, epoca) do update set
    clube = excluded.clube,
    escalao = excluded.escalao,
    equipa = coalesce(excluded.equipa, atletas_360_historico.equipa),
    divisao = coalesce(excluded.divisao, atletas_360_historico.divisao),
    classificacao_texto = coalesce(excluded.classificacao_texto, atletas_360_historico.classificacao_texto),
    golos = excluded.golos, jogos = excluded.jogos, assistencias = excluded.assistencias,
    minutos = coalesce(excluded.minutos, atletas_360_historico.minutos),
    titulos = case
      when v_titulo is null then atletas_360_historico.titulos
      when atletas_360_historico.titulos is null then array[v_titulo]
      when v_titulo = any(atletas_360_historico.titulos) then atletas_360_historico.titulos
      else array_append(atletas_360_historico.titulos, v_titulo)
    end
  returning id, titulos into v_id, v_titulos;

  insert into public.atleta_eventos (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, payload)
  values (p_atleta, case when v_novo then 'carreira_epoca_registada' else 'carreira_epoca_atualizada' end, 'marco',
          'Época ' || trim(p_epoca) || ' · ' || trim(p_clube) || ' (' || trim(p_escalao) || ')'
            || case when p_golos is not null then ' · ' || p_golos || ' golo' || case when p_golos=1 then '' else 's' end else '' end
            || case when p_jogos is not null then ' em ' || p_jogos || ' jogo' || case when p_jogos=1 then '' else 's' end else '' end,
          'familia', 'declarado', 2,
          jsonb_build_object('epoca', trim(p_epoca), 'clube', trim(p_clube), 'escalao', trim(p_escalao),
                             'golos', p_golos, 'jogos', p_jogos, 'assist', p_assistencias, 'minutos', p_minutos));

  if v_titulo is not null and not exists (
    select 1 from public.atleta_eventos e
     where e.atleta_id = p_atleta and e.tipo = 'titulo_conquistado'
       and e.payload->>'epoca' = trim(p_epoca) and e.payload->>'titulo' = v_titulo
  ) then
    insert into public.atleta_eventos (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, payload)
    values (p_atleta, 'titulo_conquistado', 'marco',
            v_titulo || ' · ' || trim(p_escalao) || ' · época ' || trim(p_epoca),
            'familia', 'declarado', 4,
            jsonb_build_object('epoca', trim(p_epoca), 'titulo', v_titulo, 'clube', trim(p_clube), 'escalao', trim(p_escalao)));
  end if;

  return jsonb_build_object('ok', true, 'id', v_id);
end $function$;
