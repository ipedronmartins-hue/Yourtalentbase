-- ============================================================================
-- MIGRAÇÃO 035d · CALENDÁRIO DE JOGOS DA FAMÍLIA
--
-- Pedido do fundador (2026-07-16): "podemos inserir um calendário que registe
-- eventos no família? assim marcava-se lá os jogos, e a app perguntava após o
-- jogo: como correu, se marcou golo, se fez assistência, quanto tempo jogou".
--
-- Fecha dois círculos de uma vez:
--   1. O check-in pós-jogo (035b) deixa de ser cego — em vez de perguntar
--      "houve jogo?" às escuras com throttle, pergunta sobre O jogo marcado,
--      pelo nome do adversário. O check-in cego fica como fallback para
--      famílias que não usam o calendário.
--   2. As estatísticas de época (jogos/golos/assist_epoca, migração 029, até
--      aqui atualizadas à mão) passam a acumular automaticamente a partir da
--      resposta a cada jogo — quem alimenta o sistema recebe valor.
--
-- Também alimenta o briefing de segunda do treinador (o digest já carrega
-- 'ultimo_checkin_jogo' desde a 035c) — o desenho do briefing queria contexto
-- de jogo e não o tinha porque não existia calendário em lado nenhum.
--
-- Desenho:
--   - atleta_jogos: RLS deny-by-default SEM policies de cliente (escrita e
--     leitura só por RPC security definer, padrão constitucional).
--   - Agendar NÃO emite evento (é intenção, não facto). RESPONDER emite
--     ('jogo_registado', origem declarado, fonte familia) — um jogo jogado
--     com golos/minutos é facto de percurso. O tipo NÃO está na whitelist
--     da montra pública (026) — nunca aparece a estranhos; vive no passaporte
--     autenticado e no retorno do treinador.
--   - Responder também insere familia_treinos (atividade='jogo') com o mesmo
--     formato do check-in 035b — o digest do treinador e o Development Score
--     continuam a funcionar sem mexer em mais nada.
--   - Responder é imutável: segunda resposta ao mesmo jogo → 'ja_respondido'
--     (correções são novos eventos, nunca updates — livro-razão).
--   - Jogo agendado e ainda sem resposta pode ser apagado (é um plano);
--     jogo respondido não se apaga.
--
-- Validado em dry-run transacional (2026-07-16): encarregado agenda/lista/
-- responde ✓; época incrementa ✓; evento emitido ✓; segunda resposta
-- bloqueada ✓; responder jogo futuro bloqueado ✓; intruso bloqueado em
-- todas ✓; apagar respondido bloqueado ✓.
-- ============================================================================

create table if not exists public.atleta_jogos (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atletas_360(id) on delete cascade,
  data_jogo timestamptz not null,
  adversario text,
  criado_em timestamptz not null default now(),
  respondido_em timestamptz,
  resultado jsonb
);
create index if not exists idx_atleta_jogos_atleta on public.atleta_jogos(atleta_id, data_jogo desc);
alter table public.atleta_jogos enable row level security;
-- deny-by-default: zero policies de cliente; tudo via RPC security definer.

create or replace function public.ytb_jogo_agendar(
  p_atleta uuid, p_data timestamptz, p_adversario text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_data is null or p_data > now() + interval '1 year' or p_data < now() - interval '60 days' then
    return jsonb_build_object('ok', false, 'motivo', 'data_invalida');
  end if;

  insert into public.atleta_jogos (atleta_id, data_jogo, adversario)
  values (p_atleta, p_data, left(nullif(trim(coalesce(p_adversario,'')),''), 60))
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end $$;
grant execute on function public.ytb_jogo_agendar(uuid,timestamptz,text) to authenticated;

create or replace function public.ytb_jogo_apagar(p_jogo uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_atleta uuid; v_respondido timestamptz;
begin
  select atleta_id, respondido_em into v_atleta, v_respondido from public.atleta_jogos where id = p_jogo;
  if v_atleta is null then return jsonb_build_object('ok', false, 'motivo', 'nao_encontrado'); end if;
  if not (public._ytb_e_encarregado(v_atleta) or public.ytb_is_admin()) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if v_respondido is not null then
    return jsonb_build_object('ok', false, 'motivo', 'ja_respondido'); -- facto não se apaga
  end if;
  delete from public.atleta_jogos where id = p_jogo;
  return jsonb_build_object('ok', true);
end $$;
grant execute on function public.ytb_jogo_apagar(uuid) to authenticated;

create or replace function public.ytb_jogos_lista(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return null;
  end if;
  return jsonb_build_object(
    'por_responder', (
      select coalesce(jsonb_agg(jsonb_build_object('id', j.id, 'data_jogo', j.data_jogo, 'adversario', j.adversario) order by j.data_jogo desc), '[]'::jsonb)
      from public.atleta_jogos j
      where j.atleta_id = p_atleta and j.respondido_em is null and j.data_jogo <= now()
        and j.data_jogo >= now() - interval '30 days'),
    'proximos', (
      select coalesce(jsonb_agg(jsonb_build_object('id', j.id, 'data_jogo', j.data_jogo, 'adversario', j.adversario) order by j.data_jogo asc), '[]'::jsonb)
      from public.atleta_jogos j
      where j.atleta_id = p_atleta and j.respondido_em is null and j.data_jogo > now()),
    'ultimos', (
      select coalesce(jsonb_agg(jsonb_build_object('id', j.id, 'data_jogo', j.data_jogo, 'adversario', j.adversario, 'resultado', j.resultado) order by j.data_jogo desc), '[]'::jsonb)
      from (select * from public.atleta_jogos
             where atleta_id = p_atleta and respondido_em is not null
             order by data_jogo desc limit 5) j)
  );
end $$;
grant execute on function public.ytb_jogos_lista(uuid) to authenticated;

create or replace function public.ytb_jogo_responder(
  p_jogo uuid, p_como_correu int, p_golos int default 0, p_assistencias int default 0,
  p_minutos int default null, p_dificuldade int default null, p_nota text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_j public.atleta_jogos; v_resultado jsonb; v_titulo text; v_nota text;
begin
  select * into v_j from public.atleta_jogos where id = p_jogo;
  if v_j.id is null then return jsonb_build_object('ok', false, 'motivo', 'nao_encontrado'); end if;
  if not public._ytb_e_encarregado(v_j.atleta_id) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if v_j.respondido_em is not null then
    return jsonb_build_object('ok', false, 'motivo', 'ja_respondido');
  end if;
  if v_j.data_jogo > now() then
    return jsonb_build_object('ok', false, 'motivo', 'jogo_no_futuro');
  end if;
  if p_como_correu is null or p_como_correu < 1 or p_como_correu > 5 then
    return jsonb_build_object('ok', false, 'motivo', 'como_correu_invalido');
  end if;
  if coalesce(p_golos,0) < 0 or coalesce(p_golos,0) > 20 then return jsonb_build_object('ok', false, 'motivo', 'golos_invalidos'); end if;
  if coalesce(p_assistencias,0) < 0 or coalesce(p_assistencias,0) > 20 then return jsonb_build_object('ok', false, 'motivo', 'assist_invalidas'); end if;
  if p_minutos is not null and (p_minutos < 0 or p_minutos > 120) then return jsonb_build_object('ok', false, 'motivo', 'minutos_invalidos'); end if;
  if p_dificuldade is not null and (p_dificuldade < 1 or p_dificuldade > 5) then return jsonb_build_object('ok', false, 'motivo', 'dificuldade_invalida'); end if;

  v_nota := left(nullif(trim(coalesce(p_nota,'')),''), 500);
  v_resultado := jsonb_build_object(
    'como_correu', p_como_correu, 'golos', coalesce(p_golos,0),
    'assistencias', coalesce(p_assistencias,0), 'minutos', p_minutos,
    'dificuldade', p_dificuldade);

  update public.atleta_jogos
     set respondido_em = now(), resultado = v_resultado || jsonb_build_object('nota', v_nota)
   where id = p_jogo;

  -- alimenta o retorno do treinador e o Development Score pelo canal já existente
  insert into public.familia_treinos
    (atleta_id, exercicio, atividade, resultado, tempo, confianca, feedback, tempo_fonte, created_at)
  values
    (v_j.atleta_id, 'Jogo' || coalesce(' vs '||v_j.adversario, ''), 'jogo',
     v_resultado, coalesce(p_minutos,0), null, v_nota, 'familia', now());

  -- estatísticas de época acumulam automaticamente (antes eram à mão, 029)
  update public.atletas_360 set
    jogos_epoca  = coalesce(jogos_epoca,0) + 1,
    golos_epoca  = coalesce(golos_epoca,0) + coalesce(p_golos,0),
    assist_epoca = coalesce(assist_epoca,0) + coalesce(p_assistencias,0)
  where id = v_j.atleta_id;

  -- facto de percurso no livro-razão (tipo fora da whitelist da montra pública)
  v_titulo := 'Jogo' || coalesce(' vs '||v_j.adversario, '')
    || case when coalesce(p_golos,0) > 0 then ' · '||p_golos||' golo'||case when p_golos=1 then '' else 's' end else '' end
    || case when coalesce(p_assistencias,0) > 0 then ' · '||p_assistencias||' assistência'||case when p_assistencias=1 then '' else 's' end else '' end
    || case when p_minutos is not null then ' · '||p_minutos||' min' else '' end;
  insert into public.atleta_eventos (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, payload)
  values (v_j.atleta_id, 'jogo_registado', 'treino', v_titulo, 'familia', 'declarado',
          case when coalesce(p_golos,0) > 0 or coalesce(p_assistencias,0) > 0 then 2 else 1 end,
          v_resultado || jsonb_build_object('jogo_id', p_jogo, 'data_jogo', v_j.data_jogo, 'adversario', v_j.adversario));

  return jsonb_build_object('ok', true);
end $$;
grant execute on function public.ytb_jogo_responder(uuid,int,int,int,int,int,text) to authenticated;
