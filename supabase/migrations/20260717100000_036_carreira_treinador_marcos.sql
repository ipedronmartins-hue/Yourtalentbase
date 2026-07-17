-- ============================================================================
-- MIGRAÇÃO 036 · QA PRÉ-PILOTO: CARREIRA REAL, PASSAPORTE DO TREINADOR,
--                MARCOS SEM BUROCRACIA
--
-- Reporte do fundador a usar a app a sério (2026-07-17): "o passaporte
-- continua com dados inventados e não dá para alterar" + família sem acesso
-- às ferramentas. Diagnóstico:
--   - Os "dados inventados" são o bloco DEMO (Coutinho/Dragon Force) — em
--     produção a carreira real estava VAZIA (atletas_360_historico: 0 linhas
--     para os atletas reais; a tabela sempre teve o schema certo — época,
--     clube, escalão, divisão, classificação, títulos[] — mas NUNCA teve um
--     caminho de escrita).
--   - Os "Marcos da Carreira" reais mostravam burocracia: "Ficha atualizada
--     pelo admin" ×6 como marco (tipos atualizacao_admin/estado_admin com
--     categoria='marco' desde a 000). Eventos são imutáveis — não se mexe no
--     passado; filtra-se na LEITURA e corrige-se o futuro.
--   - O treinador não tinha NENHUM modo de passaporte (admin/scout/clube/
--     família existiam; treinador não) — o "Passaporte →" do briefing
--     apontava para um hash que caía no DEMO.
--
-- 1) ytb_carreira_registar / ytb_carreira_lista — a família (ou admin)
--    regista época a época o percurso: clube, escalão, divisão, classificação
--    e título. Upsert por (atleta, época) — corrigir uma época é atualizar a
--    linha dessa época (o histórico de carreira é ficha, não livro-razão; o
--    livro regista os MOMENTOS: título novo emite evento marco
--    'titulo_conquistado', e o insert de época emite 'epoca_registada' pelo
--    trigger genérico da 000, categoria 'historico', que não polui marcos).
-- 2) ytb_passaporte_treinador — o treinador abre o passaporte dos SEUS
--    atletas (mesma regra do digest: fonte_email dele OU tem avaliação dele).
-- 3) _ytb_passaporte_json: 'carreira' enriquecida (clube/escalão/divisão/
--    classificação/títulos — antes só devolvia a época) e 'marcos' filtrados
--    (excluir atualizacao_admin/estado_admin).
-- 4) O filtro é na LEITURA (marcos + timeline): cobre os eventos passados
--    (imutáveis) e os futuros de uma vez. Os tipos atualizacao_admin/
--    estado_admin nascem de RPCs do admin, não do trigger genérico da 000
--    (que é um DO block inline, não uma tabela de config) — mudar a origem
--    fica fora desta migração; o filtro de leitura já os tira de todas as
--    superfícies.
--
-- Validado em dry-run transacional (2026-07-17): encarregado regista época ✓,
-- upsert corrige sem duplicar ✓, título novo emite marco ✓, intruso
-- bloqueado ✓, treinador real abre passaporte do seu atleta ✓, treinador
-- alheio bloqueado ✓, marcos sem burocracia ✓.
-- ============================================================================

create unique index if not exists uq_historico_atleta_epoca
  on public.atletas_360_historico(atleta_id, epoca);

create or replace function public.ytb_carreira_registar(
  p_atleta uuid, p_epoca text, p_clube text, p_escalao text,
  p_divisao text default null, p_classificacao text default null,
  p_titulo text default null, p_equipa text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_id uuid; v_titulos text[]; v_titulo text;
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if coalesce(trim(p_epoca),'') = '' or not (trim(p_epoca) ~ '^\d{2}/\d{2}$') then
    return jsonb_build_object('ok', false, 'motivo', 'epoca_invalida'); -- formato 24/25
  end if;
  if coalesce(trim(p_clube),'') = '' or coalesce(trim(p_escalao),'') = '' then
    return jsonb_build_object('ok', false, 'motivo', 'clube_escalao_obrigatorios');
  end if;

  v_titulo := left(nullif(trim(coalesce(p_titulo,'')),''), 80);

  insert into public.atletas_360_historico
    (atleta_id, epoca, clube, escalao, equipa, divisao, classificacao_texto, titulos, created_at)
  values
    (p_atleta, trim(p_epoca), left(trim(p_clube),80), left(trim(p_escalao),20),
     left(nullif(trim(coalesce(p_equipa,'')),''),60),
     left(nullif(trim(coalesce(p_divisao,'')),''),60),
     left(nullif(trim(coalesce(p_classificacao,'')),''),60),
     case when v_titulo is not null then array[v_titulo] else null end,
     now())
  on conflict (atleta_id, epoca) do update set
    clube = excluded.clube,
    escalao = excluded.escalao,
    equipa = coalesce(excluded.equipa, atletas_360_historico.equipa),
    divisao = coalesce(excluded.divisao, atletas_360_historico.divisao),
    classificacao_texto = coalesce(excluded.classificacao_texto, atletas_360_historico.classificacao_texto),
    titulos = case
      when v_titulo is null then atletas_360_historico.titulos
      when atletas_360_historico.titulos is null then array[v_titulo]
      when v_titulo = any(atletas_360_historico.titulos) then atletas_360_historico.titulos
      else array_append(atletas_360_historico.titulos, v_titulo)
    end
  returning id, titulos into v_id, v_titulos;

  -- título novo = momento de orgulho → marco no livro-razão (uma vez por título/época)
  if v_titulo is not null and not exists (
    select 1 from public.atleta_eventos e
     where e.atleta_id = p_atleta and e.tipo = 'titulo_conquistado'
       and e.payload->>'epoca' = trim(p_epoca) and e.payload->>'titulo' = v_titulo
  ) then
    insert into public.atleta_eventos (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, payload)
    values (p_atleta, 'titulo_conquistado', 'marco',
            v_titulo || ' · ' || trim(p_escalao) || ' · época ' || trim(p_epoca),
            'familia', 'declarado', 4,
            jsonb_build_object('epoca', trim(p_epoca), 'titulo', v_titulo, 'clube', trim(p_clube), 'escalao', trim(p_escalao)));
  end if;

  return jsonb_build_object('ok', true, 'id', v_id);
end $$;
grant execute on function public.ytb_carreira_registar(uuid,text,text,text,text,text,text,text) to authenticated;

create or replace function public.ytb_carreira_lista(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return null;
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'epoca', h.epoca, 'clube', h.clube, 'escalao', h.escalao, 'equipa', h.equipa,
      'divisao', h.divisao, 'classificacao', h.classificacao_texto, 'titulos', to_jsonb(coalesce(h.titulos, array[]::text[]))
    ) order by h.epoca desc)
    from public.atletas_360_historico h where h.atleta_id = p_atleta
  ), '[]'::jsonb);
end $$;
grant execute on function public.ytb_carreira_lista(uuid) to authenticated;

-- ── o treinador abre o passaporte dos SEUS atletas (mesma regra do digest) ──
create or replace function public.ytb_passaporte_treinador(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if v_email = '' or not public.ytb_is_treinador() then return null; end if;
  if not exists (
    select 1 from public.atletas_360 a
     where a.id = p_atleta
       and (lower(coalesce(a.fonte_email,'')) = v_email
            or exists (select 1 from public.treinador_avaliacoes av
                        where av.atleta_id = a.id and lower(coalesce(av.treinador_email,'')) = v_email))
  ) then return null; end if;
  return public._ytb_passaporte_json(p_atleta);
end $$;
grant execute on function public.ytb_passaporte_treinador(uuid) to authenticated;

-- ── passaporte: carreira rica + marcos sem burocracia ──
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
