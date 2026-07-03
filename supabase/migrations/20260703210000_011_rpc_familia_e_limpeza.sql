-- ============================================================================
-- MIGRAÇÃO 011 · RPC DA AUTOAVALIAÇÃO DA FAMÍLIA + LIMPEZA DE POLICIES ÓRFÃS
-- A 007 revogou a escrita direta em familia_avaliacoes com a nota "escrita
-- passa a ser só por RPC futura" — esta é a RPC. O frontend antigo tentava
-- inserir uma coluna inexistente (escalao); a RPC alinha com o esquema real.
-- Evento no livro: automático via trigger ytb_ev_familia_avaliacoes (000).
-- Limpeza: 3 policies órfãs do paradigma antigo em atletas_360 — perigosas ou
-- redundantes. Leituras vivas ficam em sel_admin / sel_treinador /
-- atletas360_encarregado_seu / atletas360_treinador_seus.
-- Validada em dry-run transacional (2026-07-03): escrita da família dona ✓,
-- intruso bloqueado ✓, sem sessão bloqueado ✓, evento emitido ✓.
-- ============================================================================

create or replace function public.ytb_familia_autoavaliar(
  p_atleta uuid, p_posicao text, p_score int, p_confianca int,
  p_respostas jsonb, p_debilidades jsonb, p_plano jsonb
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  insert into public.familia_avaliacoes
    (atleta_id, posicao, score, confianca, respostas, debilidades, plano)
  values
    (p_atleta, nullif(trim(p_posicao),''),
     case when p_score between 0 and 100 then p_score else null end,
     case when p_confianca between 0 and 100 then p_confianca else null end,
     p_respostas, p_debilidades, p_plano)
  returning id into v_id;
  return jsonb_build_object('ok', true, 'id', v_id);
end $$;

grant execute on function public.ytb_familia_autoavaliar(uuid,text,int,int,jsonb,jsonb,jsonb) to authenticated;

drop policy if exists a360_publico_leitura on public.atletas_360;
drop policy if exists atletas_admin_total on public.atletas_360;
drop policy if exists atletas_leitura_interna on public.atletas_360;
