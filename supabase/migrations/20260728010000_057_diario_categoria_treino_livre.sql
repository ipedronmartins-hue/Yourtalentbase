-- ============================================================================
-- 057 · diário: que tipo de treino livre foi, não só "livre"
-- ----------------------------------------------------------------------------
-- Pedido do fundador: "livre" no diário não diz nada sobre o que o atleta fez
-- de facto — 60 minutos podem ser bola contra a parede ou corrida. Acrescenta
-- categoria opcional (mesmo vocabulário de 5 buckets já usado em toda a
-- plataforma: técnica/físico/decisão/tática/mental — ytb-objetivos.js), só
-- para dar contexto ao "livre"; jogo e clube já têm contexto próprio.
--
-- Assinatura muda (4 → 5 parâmetros), logo DROP + CREATE — mesmo motivo de
-- sempre: CREATE OR REPLACE com assinatura diferente cria sobrecarga
-- paralela e o PostgREST fica ambíguo sobre qual resolver.
-- ============================================================================

drop function if exists public.ytb_diario_registar(uuid, text, numeric, text);

create or replace function public.ytb_diario_registar(
  p_atleta uuid, p_atividade text, p_minutos numeric, p_nota text default null,
  p_categoria text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_s jsonb; v_label text; v_cat text;
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_atividade not in ('livre','jogo','clube') then
    return jsonb_build_object('ok', false, 'motivo', 'atividade_invalida');
  end if;
  if coalesce(p_minutos, 0) <= 0 or p_minutos > 600 then
    return jsonb_build_object('ok', false, 'motivo', 'minutos');
  end if;
  v_cat := nullif(trim(coalesce(p_categoria,'')), '');
  if v_cat is not null and v_cat not in ('tecnica','fisico','decisao','tatica','mental') then
    return jsonb_build_object('ok', false, 'motivo', 'categoria_invalida');
  end if;
  v_label := case p_atividade when 'livre' then 'Treino livre'
                              when 'jogo'  then 'Jogo' else 'Treino no clube' end;
  insert into public.familia_treinos
    (atleta_id, exercicio, atividade, resultado, tempo, feedback, tempo_fonte, created_at)
  values
    (p_atleta, v_label, p_atividade,
     jsonb_build_object('atividade', p_atividade, 'categoria', v_cat, 'submetido_por', 'familia'),
     p_minutos, nullif(trim(p_nota),''), 'familia', now())
  returning id into v_id;
  v_s := public._ytb_streak_marco(p_atleta);
  return jsonb_build_object('ok', true, 'id', v_id,
    'streak', v_s->'streak', 'marco', v_s->'marco');
end $$;
grant execute on function public.ytb_diario_registar(uuid,text,numeric,text,text) to authenticated;
