-- ============================================================================
-- 038 · fechar a época — as estatísticas da época deixam de ser um snapshot
-- vivo e passam a arquivo de leitura no percurso
-- ----------------------------------------------------------------------------
-- Problema apontado pelo fundador (2026-07-18): o cartão "Estatísticas da
-- época" da família escreve em colunas únicas do perfil (golos_epoca,
-- jogos_epoca, ...) — quando a época nova começar (1 de agosto; a anterior
-- fecha a 30 de junho) e a família registar os primeiros números novos, os da
-- época terminada seriam sobrescritos. O livro-razão guarda os eventos
-- 'epoca_registada' (imutáveis), mas não havia ficha de leitura por época.
--
-- Solução: ytb_epoca_fechar(p_atleta) — copia os números vivos do perfil para
-- a linha da época em atletas_360_historico (que já tem colunas golos/jogos/
-- assistencias; ganha aqui golos_equipa), limpa o formulário vivo, avança
-- epoca_ref para a época seguinte (25/26 → 26/27) e emite o evento
-- 'epoca_fechada' (marco) na mesma transação. Nada se apaga do livro; o
-- snapshot vivo é que se arquiva antes de ser reutilizado.
-- Os leitores (ytb_carreira_lista e o bloco 'carreira' de
-- _ytb_passaporte_json) passam a devolver os números por época.
-- ============================================================================

alter table public.atletas_360_historico add column if not exists golos_equipa int;

create or replace function public.ytb_epoca_fechar(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  a record; v_ref text; v_curta text; v_prox text; v_resumo text;
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;

  select epoca_ref, divisao, golos_epoca, jogos_epoca, assist_epoca,
         golos_equipa_epoca, classificacao_equipa, clube_actual, escalao
    into a from public.atletas_360 where id = p_atleta;
  if not found then return jsonb_build_object('ok', false, 'motivo', 'atleta_invalido'); end if;

  -- o perfil usa o formato longo (2025/26, placeholder do formulário) e o
  -- percurso o curto (25/26) — aceitar ambos; a ficha arquiva no curto
  v_ref := trim(coalesce(a.epoca_ref,''));
  if not (v_ref ~ '^(\d{2}|\d{4})/\d{2}$') then
    return jsonb_build_object('ok', false, 'motivo', 'sem_epoca');
  end if;
  v_curta := right(split_part(v_ref,'/',1), 2) || '/' || split_part(v_ref,'/',2);

  if a.golos_epoca is null and a.jogos_epoca is null and a.assist_epoca is null
     and a.golos_equipa_epoca is null and a.classificacao_equipa is null then
    return jsonb_build_object('ok', false, 'motivo', 'sem_estatisticas'); -- nada para arquivar
  end if;
  if coalesce(trim(a.clube_actual),'') = '' or coalesce(trim(a.escalao),'') = '' then
    return jsonb_build_object('ok', false, 'motivo', 'perfil_incompleto'); -- clube/escalão necessários para a ficha da época
  end if;

  -- época seguinte no MESMO formato que estava no perfil (2025/26→2026/27; 25/26→26/27)
  v_prox := ((split_part(v_ref,'/',1))::int + 1)::text
            || '/' ||
            lpad(((split_part(v_ref,'/',2))::int + 1)::text, 2, '0');
  if length(split_part(v_ref,'/',1)) = 2 then
    v_prox := lpad(((split_part(v_ref,'/',1))::int + 1)::text, 2, '0') || '/' || lpad(((split_part(v_ref,'/',2))::int + 1)::text, 2, '0');
  end if;

  -- arquivo: os números vivos entram na ficha da época; o que a família já
  -- tenha registado no percurso (clube/escalão mais precisos) não se sobrepõe
  insert into public.atletas_360_historico
    (atleta_id, epoca, clube, escalao, divisao, classificacao_texto,
     golos, jogos, assistencias, golos_equipa, created_at)
  values
    (p_atleta, v_curta, left(trim(a.clube_actual),80), left(trim(a.escalao),20),
     nullif(trim(coalesce(a.divisao,'')),''), nullif(trim(coalesce(a.classificacao_equipa,'')),''),
     a.golos_epoca, a.jogos_epoca, a.assist_epoca, a.golos_equipa_epoca, now())
  on conflict (atleta_id, epoca) do update set
    divisao             = coalesce(atletas_360_historico.divisao, excluded.divisao),
    classificacao_texto = coalesce(atletas_360_historico.classificacao_texto, excluded.classificacao_texto),
    golos               = coalesce(excluded.golos, atletas_360_historico.golos),
    jogos               = coalesce(excluded.jogos, atletas_360_historico.jogos),
    assistencias        = coalesce(excluded.assistencias, atletas_360_historico.assistencias),
    golos_equipa        = coalesce(excluded.golos_equipa, atletas_360_historico.golos_equipa);

  -- o snapshot vivo limpa-se e aponta para a época nova
  update public.atletas_360 set
    golos_epoca = null, jogos_epoca = null, assist_epoca = null,
    golos_equipa_epoca = null, classificacao_equipa = null,
    epoca_ref = v_prox
  where id = p_atleta;

  v_resumo := 'Época ' || v_curta || ' fechada'
    || case when a.golos_epoca is not null then ' · ' || a.golos_epoca || ' golo' || case when a.golos_epoca = 1 then '' else 's' end else '' end
    || case when a.jogos_epoca is not null then ' em ' || a.jogos_epoca || ' jogo' || case when a.jogos_epoca = 1 then '' else 's' end else '' end;

  insert into public.atleta_eventos (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, payload)
  values (p_atleta, 'epoca_fechada', 'marco', v_resumo, 'familia', 'declarado', 3,
          jsonb_build_object('epoca', v_curta, 'golos', a.golos_epoca, 'jogos', a.jogos_epoca,
                             'assist', a.assist_epoca, 'golos_equipa', a.golos_equipa_epoca,
                             'classificacao', a.classificacao_equipa, 'proxima', v_prox));

  return jsonb_build_object('ok', true, 'epoca', v_curta, 'proxima', v_prox);
end $$;
grant execute on function public.ytb_epoca_fechar(uuid) to authenticated;

-- ── leitores: os números da época entram na ficha de carreira ──
create or replace function public.ytb_carreira_lista(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return null;
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'epoca', h.epoca, 'clube', h.clube, 'escalao', h.escalao, 'equipa', h.equipa,
      'divisao', h.divisao, 'classificacao', h.classificacao_texto,
      'golos', h.golos, 'jogos', h.jogos, 'assist', h.assistencias, 'golos_equipa', h.golos_equipa,
      'titulos', to_jsonb(coalesce(h.titulos, array[]::text[]))
    ) order by h.epoca desc)
    from public.atletas_360_historico h where h.atleta_id = p_atleta
  ), '[]'::jsonb);
end $$;

create or replace function public._ytb_passaporte_json(v_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare j jsonb;
begin
  select jsonb_build_object(
    'identidade', jsonb_build_object(
      'nome', a.nome, 'posicao', a.posicao_principal, 'clube', a.clube_actual,
      'escalao', a.escalao, 'associacao', a.associacao,
      'foto', (case when coalesce(a.foto_consentida,false) then a.foto_path else null end)),
    'indicadores', (select to_jsonb(p) - 'atleta_id'
                    from public.atleta_passaporte p where p.atleta_id = v_atleta),
    'densidade', jsonb_build_object(
      'eventos',      (select count(*) from public.atleta_eventos e where e.atleta_id = v_atleta),
      'avaliacoes',   (select count(*) from public.atleta_eventos e where e.atleta_id = v_atleta and e.tipo = 'avaliacao'),
      'observadores', (select count(distinct e.fonte) from public.atleta_eventos e where e.atleta_id = v_atleta and e.origem = 'observado'),
      'epocas',       (select count(distinct date_part('year', e.criado_em)) from public.atleta_eventos e where e.atleta_id = v_atleta),
      'interesses',   (select count(*) from public.atleta_eventos e where e.atleta_id = v_atleta and e.tipo = 'interesse_clube')),
    'evolucao_serie', (
      select coalesce(jsonb_agg(jsonb_build_object(
               't', av.created_at,
               'v', round(coalesce(public.ytb_num(av.rating), (coalesce(public.ytb_num(av.dim_treinabilidade),0)+coalesce(public.ytb_num(av.dim_compromisso),0))/2.0) * 20)
             ) order by av.created_at), '[]'::jsonb)
      from public.atletas_360_avaliacoes av where av.atleta_id = v_atleta),
    'marcos', (
      select coalesce(jsonb_agg(jsonb_build_object('titulo', e.titulo, 'em', e.criado_em)
                      order by e.criado_em desc), '[]'::jsonb)
      from public.atleta_eventos e
      where e.atleta_id = v_atleta and e.categoria = 'marco'
        and e.tipo not in ('atualizacao_admin','estado_admin')),
    'carreira', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'epoca', h.epoca, 'clube', h.clube, 'escalao', h.escalao,
               'divisao', h.divisao, 'classificacao', h.classificacao_texto,
               'golos', h.golos, 'jogos', h.jogos, 'assist', h.assistencias, 'golos_equipa', h.golos_equipa,
               'titulos', to_jsonb(coalesce(h.titulos, array[]::text[]))
             ) order by h.epoca desc), '[]'::jsonb)
      from public.atletas_360_historico h where h.atleta_id = v_atleta),
    'timeline', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select jsonb_build_object(
                 'categoria', e.categoria, 'origem', e.origem, 'titulo', e.titulo,
                 'fonte', e.fonte, 'em', e.criado_em, 'impacto', e.impacto) as t
        from public.atleta_eventos e where e.atleta_id = v_atleta
          and e.tipo not in ('atualizacao_admin','estado_admin')
        order by e.relevancia desc nulls last, e.criado_em desc
        limit 12) s),
    'atividade', jsonb_build_object(
      'prescritos', (select coalesce(sum(coalesce((t.plano->>'sessoes')::int,1)),0) from public.treinador_treinos t where t.atleta_id = v_atleta),
      'concluidos', (select count(*) from public.familia_treinos f where f.atleta_id = v_atleta and f.prescrito_id is not null),
      'execucoes',  (select count(*) from public.familia_treinos f where f.atleta_id = v_atleta),
      'ultima',     (select max(f.created_at) from public.familia_treinos f where f.atleta_id = v_atleta),
      'semanas_ativas', (select count(distinct date_trunc('week', f.created_at)) from public.familia_treinos f where f.atleta_id = v_atleta)),
    'cognitivo', jsonb_build_object(
      'total',      (select count(*) from public.elite_coach_resultados r where r.atleta_id = v_atleta),
      'acerto_pct', (select round(100.0*avg((r.correto)::int)) from public.elite_coach_resultados r where r.atleta_id = v_atleta),
      'por_tipo', (select coalesce(jsonb_agg(jsonb_build_object('cenario',t.cenario,'total',t.total,'acerto_pct',t.acerto) order by t.total desc),'[]'::jsonb)
                   from (select coalesce(cenario_id,'—') cenario, count(*) total, round(100.0*avg((correto)::int)) acerto
                         from public.elite_coach_resultados where atleta_id=v_atleta group by coalesce(cenario_id,'—')) t),
      'serie', (select coalesce(jsonb_agg(jsonb_build_object('t',m.mes,'v',m.acerto) order by m.mes),'[]'::jsonb)
                from (select date_trunc('month',created_at) mes, round(100.0*avg((correto)::int)) acerto
                      from public.elite_coach_resultados where atleta_id=v_atleta group by date_trunc('month',created_at)) m)),
    'relatorios', (
      select coalesce(jsonb_agg(jsonb_build_object('fonte', e.fonte, 'titulo', e.titulo, 'em', e.criado_em) order by e.criado_em desc), '[]'::jsonb)
      from public.atleta_eventos e where e.atleta_id = v_atleta and e.origem = 'observado' and e.tipo = 'scout_report'),
    'maturacao', public._ytb_maturacao(v_atleta),
    'dev_score', public._ytb_dev_score(v_atleta),
    'media', jsonb_build_object(
      'video',   (select case when coalesce(a2.video_consentido,false) then a2.video_path else null end from public.atletas_360 a2 where a2.id = v_atleta),
      'galeria', '[]'::jsonb)
  ) into j
  from public.atletas_360 a where a.id = v_atleta;
  return j;
end $$;
