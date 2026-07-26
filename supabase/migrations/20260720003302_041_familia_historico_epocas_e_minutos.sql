-- 041: coluna minutos em atletas_360_historico + atletas_360.minutos_epoca.
-- NOTA HISTORICA: nesta migracao original tambem foram criados um indice unico
-- redundante (ja existia uq_historico_atleta_epoca) e uma funcao ytb_familia_historico_registar
-- que duplicava ytb_carreira_registar -- ambos corrigidos na migracao 042 seguinte.
-- Mantido aqui fielmente ao que foi aplicado em producao, para que o historico do
-- repositorio corresponda ao que a base de dados realmente passou.

ALTER TABLE public.atletas_360_historico ADD COLUMN IF NOT EXISTS minutos integer;
ALTER TABLE public.atletas_360_historico ADD CONSTRAINT atletas_360_historico_atleta_epoca_uniq UNIQUE (atleta_id, epoca);
ALTER TABLE public.atletas_360 ADD COLUMN IF NOT EXISTS minutos_epoca integer;

CREATE POLICY hist_leitura_encarregado ON public.atletas_360_historico
  FOR SELECT
  USING (sou_encarregado(atleta_id));

CREATE OR REPLACE FUNCTION public.ytb_familia_historico_registar(
  p_atleta uuid, p_epoca text, p_clube text, p_equipa text, p_escalao text,
  p_jogos integer, p_golos integer, p_assistencias integer, p_minutos integer,
  p_classificacao_texto text default null
) RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not (public._ytb_e_encarregado(p_atleta) or public._ytb_e_admin()) then
    return jsonb_build_object('ok', false, 'motivo', 'sem_permissao');
  end if;
  if coalesce(trim(p_epoca),'') = '' or coalesce(trim(p_clube),'') = '' or coalesce(trim(p_escalao),'') = '' then
    return jsonb_build_object('ok', false, 'motivo', 'epoca_clube_escalao_obrigatorios');
  end if;
  if p_golos is not null and (p_golos < 0 or p_golos > 200) then return jsonb_build_object('ok',false,'motivo','golos_invalidos'); end if;
  if p_jogos is not null and (p_jogos < 0 or p_jogos > 100) then return jsonb_build_object('ok',false,'motivo','jogos_invalidos'); end if;
  if p_assistencias is not null and (p_assistencias < 0 or p_assistencias > 200) then return jsonb_build_object('ok',false,'motivo','assist_invalidos'); end if;
  if p_minutos is not null and (p_minutos < 0 or p_minutos > 9000) then return jsonb_build_object('ok',false,'motivo','minutos_invalidos'); end if;

  insert into public.atletas_360_historico (atleta_id, epoca, clube, equipa, escalao, jogos, golos, assistencias, minutos, classificacao_texto)
  values (p_atleta, trim(p_epoca), trim(p_clube), p_equipa, trim(p_escalao), p_jogos, p_golos, p_assistencias, p_minutos, p_classificacao_texto)
  on conflict (atleta_id, epoca) do update set
    clube = excluded.clube, equipa = excluded.equipa, escalao = excluded.escalao,
    jogos = excluded.jogos, golos = excluded.golos, assistencias = excluded.assistencias,
    minutos = excluded.minutos,
    classificacao_texto = coalesce(excluded.classificacao_texto, atletas_360_historico.classificacao_texto);

  return jsonb_build_object('ok', true);
end $function$;

CREATE OR REPLACE FUNCTION public.ytb_familia_epoca_registar(
  p_atleta uuid, p_epoca_ref text DEFAULT NULL::text, p_divisao text DEFAULT NULL::text,
  p_golos_epoca integer DEFAULT NULL::integer, p_jogos_epoca integer DEFAULT NULL::integer,
  p_assist_epoca integer DEFAULT NULL::integer, p_golos_equipa_epoca integer DEFAULT NULL::integer,
  p_classificacao_equipa text DEFAULT NULL::text, p_minutos_epoca integer DEFAULT NULL::integer
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_golos_epoca is not null and (p_golos_epoca < 0 or p_golos_epoca > 200) then return jsonb_build_object('ok',false,'motivo','golos_invalidos'); end if;
  if p_jogos_epoca is not null and (p_jogos_epoca < 0 or p_jogos_epoca > 100) then return jsonb_build_object('ok',false,'motivo','jogos_invalidos'); end if;
  if p_assist_epoca is not null and (p_assist_epoca < 0 or p_assist_epoca > 200) then return jsonb_build_object('ok',false,'motivo','assist_invalidos'); end if;
  if p_minutos_epoca is not null and (p_minutos_epoca < 0 or p_minutos_epoca > 9000) then return jsonb_build_object('ok',false,'motivo','minutos_invalidos'); end if;

  update public.atletas_360 set
    epoca_ref             = case when p_epoca_ref is not null and trim(p_epoca_ref)<>'' then trim(p_epoca_ref) else epoca_ref end,
    divisao               = case when p_divisao is not null then nullif(trim(p_divisao),'') else divisao end,
    golos_epoca            = coalesce(p_golos_epoca, golos_epoca),
    jogos_epoca            = coalesce(p_jogos_epoca, jogos_epoca),
    assist_epoca           = coalesce(p_assist_epoca, assist_epoca),
    minutos_epoca           = coalesce(p_minutos_epoca, minutos_epoca),
    golos_equipa_epoca     = coalesce(p_golos_equipa_epoca, golos_equipa_epoca),
    classificacao_equipa  = case when p_classificacao_equipa is not null then nullif(trim(p_classificacao_equipa),'') else classificacao_equipa end
  where id = p_atleta;

  insert into public.atleta_eventos (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, payload)
  values (p_atleta, 'epoca_registada', 'marco',
          'Estatísticas da época registadas'
            || case when p_golos_epoca is not null then ' · ' || p_golos_epoca || ' golo' || case when p_golos_epoca=1 then '' else 's' end else '' end
            || case when p_jogos_epoca is not null then ' em ' || p_jogos_epoca || ' jogo' || case when p_jogos_epoca=1 then '' else 's' end else '' end,
          'familia', 'declarado', 2,
          jsonb_build_object('epoca_ref', p_epoca_ref, 'golos', p_golos_epoca, 'jogos', p_jogos_epoca, 'assist', p_assist_epoca, 'minutos', p_minutos_epoca));

  return jsonb_build_object('ok', true);
end $function$;
