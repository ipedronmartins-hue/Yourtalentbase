-- ============================================================================
-- MIGRAÇÃO 017 · ytb_scout_meus_relatorios devolve report_data
-- scouts.html reabre um relatório da lista (abrirReportGuardado) esperando
-- report_data no objeto — a 016 só devolvia o resumo. Sem isto, "ver
-- relatório completo" no histórico mostrava sempre "formato antigo".
-- Validada em dry-run transacional (2026-07-04): report_data presente e
-- com o conteúdo correto no item devolvido.
-- ============================================================================

create or replace function public.ytb_scout_meus_relatorios(p_limit int default 10)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_scout_nome text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  select nome into v_scout_nome from public.perfis where lower(email)=v_email;
  if v_scout_nome is null then return '[]'::jsonb; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', r.id, 'atleta', r.atleta, 'clube', r.clube, 'categoria', r.categoria,
             'posicao', r.posicao, 'epoca', r.epoca, 'media_geral', r.media_geral,
             'decisao', r.decisao, 'created_at', r.created_at, 'report_data', r.report_data)
           order by r.created_at desc)
    from (select * from public.relatorios where lower(scout)=lower(v_scout_nome)
          order by created_at desc limit greatest(p_limit,1)) r
  ), '[]'::jsonb);
end $$;
