-- 042: corrige a duplicacao introduzida em 041 (indice unico repetido e RPC a mais
-- que fazia o mesmo que ytb_carreira_registar) e estende a funcao real (a que o
-- passaporte.html usa) com minutos.
ALTER TABLE public.atletas_360_historico DROP CONSTRAINT atletas_360_historico_atleta_epoca_uniq;
DROP FUNCTION IF EXISTS public.ytb_familia_historico_registar(uuid,text,text,text,text,integer,integer,integer,integer,text);

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
  v_id uuid; v_titulos text[]; v_titulo text;
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

CREATE OR REPLACE FUNCTION public.ytb_carreira_lista(p_atleta uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return null;
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'epoca', h.epoca, 'clube', h.clube, 'escalao', h.escalao, 'equipa', h.equipa,
      'divisao', h.divisao, 'classificacao', h.classificacao_texto,
      'golos', h.golos, 'jogos', h.jogos, 'assist', h.assistencias, 'minutos', h.minutos,
      'golos_equipa', h.golos_equipa,
      'titulos', to_jsonb(coalesce(h.titulos, array[]::text[]))
    ) order by h.epoca desc)
    from public.atletas_360_historico h where h.atleta_id = p_atleta
  ), '[]'::jsonb);
end $function$;
