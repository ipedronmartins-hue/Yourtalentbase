-- ============================================================================
-- MIGRAÇÃO 012 · RPC DO REGISTO DE TREINO DA FAMÍLIA (reparação)
-- O frontend inseria colunas inexistentes (exercicio_id, completas, energia…)
-- em familia_treinos — a persistência nunca funcionou contra o esquema real e
-- caía em memória local com "✓" no ecrã. Esta RPC alinha com o esquema real:
-- exercicio (nome), resultado (payload rico em jsonb), tempo, confianca 0-100,
-- flags, e liga opcional ao plano prescrito (prescrito_id/semana/sessao).
-- Evento no livro: automático via trigger ytb_ev_familia_treinos (000).
-- Validada em dry-run transacional (2026-07-03): dona ✓, intruso ✗, evento ✓.
-- ============================================================================

create or replace function public.ytb_treino_registar(
  p_atleta uuid,
  p_exercicio text,
  p_resultado jsonb,
  p_tempo numeric,
  p_confianca int,
  p_flags jsonb default '[]'::jsonb,
  p_prescrito_id uuid default null,
  p_semana int default null,
  p_sessao int default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if coalesce(trim(p_exercicio),'') = '' then
    return jsonb_build_object('ok', false, 'motivo', 'exercicio');
  end if;
  insert into public.familia_treinos
    (atleta_id, exercicio, resultado, tempo, confianca, flags,
     prescrito_id, semana, sessao, tempo_fonte, created_at)
  values
    (p_atleta, trim(p_exercicio), coalesce(p_resultado,'{}'::jsonb),
     greatest(p_tempo, 0),
     case when p_confianca between 0 and 100 then p_confianca else null end,
     coalesce(p_flags,'[]'::jsonb),
     p_prescrito_id, p_semana, p_sessao, 'familia', now())
  returning id into v_id;
  return jsonb_build_object('ok', true, 'id', v_id);
end $$;

grant execute on function public.ytb_treino_registar(uuid,text,jsonb,numeric,int,jsonb,uuid,int,int) to authenticated;