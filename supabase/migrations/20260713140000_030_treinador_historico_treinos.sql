-- ============================================================================
-- MIGRAÇÃO 030 · HISTÓRICO DE TREINOS PRESCRITOS (Pro Treinador)
-- Pedido do fundador (2026-07-13): "os treinos prescritos podiam ficar
-- guardados também, resumidos mas guardados". Investigação antes de mexer:
-- o plano JÁ fica gravado desde sempre (ytb_treinador_avaliar insere em
-- treinador_treinos.plano a cada avaliação — confirmado com dados reais em
-- produção, ex.: Nuno Teles e Vasco Coutinho Martins já têm várias
-- prescrições guardadas). O problema não é a gravação, é que NÃO EXISTE
-- NENHUMA LEITURA no frontend — o treinador nunca vê o que já prescreveu
-- antes, cada avaliação parece isolada. Esta migração só acrescenta leitura.
--
-- Duas RPCs, deliberadamente separadas ("resumidos mas guardados"):
-- - ytb_treinador_treinos_historico: lista leve (sem o plano completo) —
--   data, nº de semanas, nomes dos ciclos, debilidades, nota recalculada
--   a partir dos critérios guardados (não há coluna de nota histórica).
-- - ytb_treinador_treino_ver: plano completo de UMA entrada, só quando o
--   treinador pede para expandir ("ver plano completo").
--
-- Guarda: só o próprio treinador que criou a prescrição (treinador_id =
-- auth.jwt() sub) ou admin — mesmo padrão de posse usado no resto da app.
--
-- Validado em dry-run (2026-07-13): histórico devolve as entradas reais já
-- existentes para o atleta de teste, plano completo só sai para quem é
-- dono, intruso (outro treinador) bloqueado nas duas funções.
-- ============================================================================

create or replace function public.ytb_treinador_treinos_historico(p_atleta uuid, p_limit int default 15)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_uid uuid;
begin
  if not public.ytb_is_treinador() then return '[]'::jsonb; end if;
  v_uid := nullif(auth.jwt()->>'sub','')::uuid;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', tt.id,
      'criado_em', tt.criado_em,
      'n_semanas', jsonb_array_length(coalesce(tt.plano,'[]'::jsonb)),
      'ciclos', (select jsonb_agg(s->'ciclo'->>'nome') from jsonb_array_elements(coalesce(tt.plano,'[]'::jsonb)) s),
      'debilidades', coalesce(ta.debilidades,'[]'::jsonb),
      'nota', (select round(avg(v.val),1) from (select public.ytb_num(value) as val from jsonb_each_text(coalesce(ta.criterios,'{}'::jsonb))) v where v.val is not null)
    ) order by tt.criado_em desc)
    from public.treinador_treinos tt
    left join public.treinador_avaliacoes ta on ta.id = tt.avaliacao_id
    where tt.atleta_id = p_atleta
      and (tt.treinador_id = v_uid or public.ytb_is_admin())
    limit greatest(1,least(p_limit,50))
  ), '[]'::jsonb);
end $$;
grant execute on function public.ytb_treinador_treinos_historico(uuid,int) to authenticated;

create or replace function public.ytb_treinador_treino_ver(p_treino_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_uid uuid; v_row record;
begin
  if not public.ytb_is_treinador() then return jsonb_build_object('ok',false,'motivo','sem_papel_treinador'); end if;
  v_uid := nullif(auth.jwt()->>'sub','')::uuid;
  select tt.plano, tt.criado_em into v_row
  from public.treinador_treinos tt
  where tt.id = p_treino_id and (tt.treinador_id = v_uid or public.ytb_is_admin());
  if v_row is null then return jsonb_build_object('ok',false,'motivo','nao_encontrado_ou_nao_autorizado'); end if;
  return jsonb_build_object('ok',true,'plano',v_row.plano,'criado_em',v_row.criado_em);
end $$;
grant execute on function public.ytb_treinador_treino_ver(uuid) to authenticated;
