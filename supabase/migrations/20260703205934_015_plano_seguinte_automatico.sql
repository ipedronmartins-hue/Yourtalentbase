-- ============================================================================
-- MIGRAÇÃO 015 · PLANO SEGUINTE AUTOMÁTICO
-- Quando o plano atual tem >=12 execuções da família, ytb_plano_proximo gera
-- o plano de continuação: herda a linhagem (treinador_id) e o conteúdo do
-- último plano, fonte='auto' marca a geração; evento 'treino_prescrito'
-- emitido pelo trigger existente. Idempotente por construção (a nova
-- prescrição zera a contagem). O treinador vê no digest e pode substituir —
-- a autoridade é dele; o miúdo nunca fica sem caminho seguinte.
-- ytb_o_que_mudou atualizada: distingue plano do treinador vs continuação.
-- Validada em dry-run transacional (2026-07-03): não gera <12 ✓, gera =12 ✓,
-- evento ✓, idempotente ✓, mensagem própria ✓, intruso bloqueado ✓.
-- (O dry-run apanhou: treinador_id NOT NULL em produção — herdado do plano
-- anterior, o baseline 000 dizia nullable.)
-- ============================================================================

create or replace function public.ytb_plano_proximo(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_ultimo record; v_exec int; v_novo uuid;
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  select id, plano, criado_em, treinador_id into v_ultimo
    from public.treinador_treinos
   where atleta_id = p_atleta
   order by criado_em desc limit 1;
  if v_ultimo.id is null then
    return jsonb_build_object('ok', false, 'motivo', 'sem_plano');
  end if;
  select count(*) into v_exec from public.familia_treinos
   where atleta_id = p_atleta and created_at > v_ultimo.criado_em;
  if v_exec < 12 then
    return jsonb_build_object('ok', false, 'motivo', 'plano_em_curso',
      'execucoes', v_exec, 'faltam', 12 - v_exec);
  end if;
  -- a continuação herda a linhagem do treinador; fonte='auto' marca a geração
  insert into public.treinador_treinos (atleta_id, treinador_id, plano, fonte)
  values (p_atleta, v_ultimo.treinador_id, v_ultimo.plano, 'auto')
  returning id into v_novo;
  return jsonb_build_object('ok', true, 'id', v_novo);
end $$;

grant execute on function public.ytb_plano_proximo(uuid) to authenticated;

create or replace function public.ytb_o_que_mudou(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_email text; v_desde timestamptz;
  v_novidades jsonb; v_pendencias jsonb := '[]'::jsonb;
  v_ultimo_treino timestamptz; v_meses_bio int;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_encarregado(p_atleta) then return null; end if;

  select visto_em into v_desde from public.atleta_vistos
   where email = v_email and atleta_id = p_atleta;

  select coalesce(jsonb_agg(jsonb_build_object(
           'em', e.criado_em,
           'tipo', e.tipo,
           'msg', case e.tipo
             when 'treino_prescrito' then
               case when coalesce(e.fonte,'') = 'auto'
                    then 'Plano de continuação pronto — o caminho não para 🎯'
                    else 'O treinador deixou um plano de treino novo 🎯' end
             when 'avaliacao_treinador'  then 'O treinador fez uma nova avaliação'
             when 'avaliacao'            then 'Um observador registou uma nova avaliação'
             when 'relatorio_jogo'       then 'Há um novo relatório de jogo'
             when 'relatorio_scout'      then 'Um scout observou o teu atleta'
             when 'estado_admin'         then coalesce(e.titulo,'O registo foi atualizado')
             when 'interesse_clube'      then 'Um clube mostrou interesse — a YTB contacta-te'
             else coalesce(e.titulo, 'Novidade no percurso')
           end) order by e.criado_em desc), '[]'::jsonb)
    into v_novidades
    from public.atleta_eventos e
   where e.atleta_id = p_atleta
     and (v_desde is null or e.criado_em > v_desde)
     and coalesce(e.fonte,'') not in ('familia','encarregado')
     and e.tipo <> 'consentimento';

  select max(e.criado_em) into v_ultimo_treino
    from public.atleta_eventos e
   where e.atleta_id = p_atleta and e.tipo = 'treino_executado';

  if v_ultimo_treino is not null
     and v_ultimo_treino between now() - interval '72 hours' and now() - interval '24 hours' then
    v_pendencias := v_pendencias || jsonb_build_object(
      'tipo','streak_risco','msg','A sequência está em risco — um treino hoje mantém a chama 🔥');
  end if;

  if exists (select 1 from public.treinador_treinos t
              where t.atleta_id = p_atleta
                and t.criado_em > coalesce(v_ultimo_treino, '-infinity'::timestamptz)) then
    v_pendencias := v_pendencias || jsonb_build_object(
      'tipo','plano_por_comecar','msg','Há um plano de treino à espera do primeiro treino');
  end if;

  if to_regclass('public.atleta_biometria') is not null then
    execute 'select (extract(epoch from now() - max(criado_em)) / 2592000)::int
               from public.atleta_biometria where atleta_id = $1'
      into v_meses_bio using p_atleta;
    if v_meses_bio is null or v_meses_bio >= 3 then
      v_pendencias := v_pendencias || jsonb_build_object(
        'tipo','biometria','msg', case when v_meses_bio is null
          then 'Regista a altura, o peso e o tamanho do pé — a trajetória começa na primeira medição'
          else 'Já passaram '||v_meses_bio||' meses desde a última medição — atualiza altura e peso' end);
    end if;
  end if;

  return jsonb_build_object(
    'desde', v_desde,
    'novidades', v_novidades,
    'nao_vistos', jsonb_array_length(v_novidades),
    'pendencias', v_pendencias);
end $$;