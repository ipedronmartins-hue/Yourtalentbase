-- ============================================================================
-- MIGRAÇÃO 035a · REPARA A ESCRITA DO ELITE COACH (estava morta)
--
-- Descoberta na preparação da vaga "Objetivos, não treinos": a tabela
-- elite_coach_resultados tem 0 LINHAS DE SEMPRE em produção. O elite-coach.html
-- grava por POST direto ao PostgREST com anon key (ecGravar), mas:
--   - a policy pública de insert (ecr_insert_publico) foi removida na
--     migração 009 (advisor fixes) sem substituição;
--   - anon/authenticated nem sequer têm grant de INSERT na tabela.
-- Resultado: todas as decisões alguma vez tomadas nos Cenários caíram na fila
-- offline do localStorage de cada utilizador ('ec-fila') e nunca chegaram à
-- base. O bloco 'cognitivo' do passaporte lê uma tabela vazia desde sempre.
--
-- Correção pelo padrão constitucional (escrita só por RPC security definer):
-- ytb_ec_registar valida e insere; grant a anon + authenticated porque o
-- elite-coach.html não tem login (a exposição é a MESMA da antiga policy
-- pública desenhada de origem, mas com campos validados e comprimentos
-- limitados em vez de insert arbitrário; a chave real é o uuid do atleta,
-- não adivinhável). O frontend passa a chamar /rest/v1/rpc/ytb_ec_registar.
--
-- Colunas confirmadas por information_schema em produção (schema drift da
-- migração 000 já documentado na 023): id, atleta_id, cenario_id (not null),
-- correto (not null), opcao, consequencia, debilidade, posicao, created_at.
--
-- Validado em dry-run transacional (2026-07-16): insert com atleta real ✓,
-- atleta inexistente bloqueado ✓, cenario_id vazio bloqueado ✓, role anon
-- consegue executar ✓ (rollback no fim; produção intocada até apply).
-- ============================================================================

create or replace function public.ytb_ec_registar(
  p_atleta uuid,
  p_cenario_id text,
  p_correto boolean,
  p_opcao text default null,
  p_consequencia text default null,
  p_debilidade text default null,
  p_posicao text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if p_atleta is null or not exists (select 1 from public.atletas_360 a where a.id = p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'atleta_invalido');
  end if;
  if coalesce(trim(p_cenario_id),'') = '' or length(p_cenario_id) > 40 then
    return jsonb_build_object('ok', false, 'motivo', 'cenario_invalido');
  end if;
  if p_correto is null then
    return jsonb_build_object('ok', false, 'motivo', 'correto_obrigatorio');
  end if;

  insert into public.elite_coach_resultados
    (atleta_id, cenario_id, correto, opcao, consequencia, debilidade, posicao, created_at)
  values
    (p_atleta, trim(p_cenario_id), p_correto,
     left(nullif(trim(coalesce(p_opcao,'')),''), 10),
     left(nullif(trim(coalesce(p_consequencia,'')),''), 30),
     left(nullif(trim(coalesce(p_debilidade,'')),''), 80),
     left(nullif(trim(coalesce(p_posicao,'')),''), 40),
     now())
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end $$;

grant execute on function public.ytb_ec_registar(uuid,text,boolean,text,text,text,text) to anon, authenticated;
