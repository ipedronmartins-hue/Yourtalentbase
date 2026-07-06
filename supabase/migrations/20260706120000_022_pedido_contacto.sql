-- ============================================================================
-- MIGRAÇÃO 022 · M5 DIFERENCIAÇÃO — FECHAR O CICLO "PEDIDO DE CONTACTO"
-- A tabela atletas_360_pedidos_contacto (esquema REAL de produção, diferente
-- do que a migração 000 local descrevia — verificado por information_schema
-- antes de escrever esta migração, não à mão), o trigger que emite
-- 'interesse_clube' em atleta_eventos, a cópia em ytb_o_que_mudou ("Um clube
-- mostrou interesse — a YTB contacta-te") e a RPC ytb_admin_pedido_contacto
-- já existiam desde muito cedo — ninguém tinha construído a ponta que os
-- alimenta. admin360.html já tinha a tab "Pedidos" completa (incl. templates
-- de WhatsApp) a ler as colunas reais corretamente; só faltava algo a
-- escrever lá. Esta migração acrescenta só isso:
--
--  ytb_pedido_contacto_criar — o clube (ou admin) regista interesse num
--  atleta que já vê no Scouting360, com a MESMA condição de visibilidade da
--  ytb_scouting360 (visivel_b2b + consentido + aprovado + não oculto).
--  Restrito a papel 'clube'/admin (não scout): o esquema real já tem
--  clube_id/clube_nome/responsavel_nome/responsavel_email desenhados à volta
--  de uma organização subscritora, não de um scout individual — forçar o
--  scout a caber aqui obrigaria a inventar semântica que não existe no
--  desenho original. Scout mantém o seu próprio caminho (scout reports).
--  Nunca cria duplicado em silêncio: se já existe um pedido por resolver do
--  mesmo responsável para o mesmo atleta, devolve ja_existia.
--
-- Deliberadamente FORA desta fase: atletas_360_clubes_subscritores já tem
-- consultas_mes_limite/consultas_mes_atual/pedidos_contacto_mes_limite/
-- pedidos_contacto_mes_atual (quota mensal por clube) — mas ZERO RPCs em
-- produção alguma vez leem ou escrevem estas colunas, e não existe nenhuma
-- lógica de reset mensal para copiar (sem cron neste projeto). Com zero
-- clubes reais em produção hoje (tabela vazia — M3 Fase 7 ainda por fazer),
-- inventar a semântica de reset agora arriscava bloquear o próprio piloto
-- (GFA) por um limite adivinhado. Fica por wire quando houver um caso real
-- para validar contra.
--
-- Também nesta migração: _ytb_passaporte_json ganha 'interesses' em
-- 'densidade' (conta de eventos tipo='interesse_clube'), para a jornada do
-- passaporte deixar de ter "Oportunidades" sempre a false. ytb_o_que_mudou
-- NÃO foi tocada — a copy original já estava correta para clube-only.
-- ============================================================================

create or replace function public.ytb_pedido_contacto_criar(p_atleta_id uuid, p_motivo text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_email text; v_clube public.atletas_360_clubes_subscritores;
  v_existente uuid; v_id uuid;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));

  if not (public.ytb_is_admin() or public._ytb_e_clube()) then
    return jsonb_build_object('ok',false,'motivo','sem_permissao');
  end if;

  if not exists (
    select 1 from public.atletas_360 a
     where a.id = p_atleta_id
       and a.visivel_b2b = true and a.consentido_em is not null
       and a.estado = 'aprovado' and coalesce(a.oculto_pelo_responsavel,false) = false
  ) then
    return jsonb_build_object('ok',false,'motivo','atleta_nao_visivel');
  end if;

  if public._ytb_e_clube() then
    v_clube := public._ytb_clube_conta(v_email);
  end if;
  if v_clube.id is null and not public.ytb_is_admin() then
    return jsonb_build_object('ok',false,'motivo','sem_conta_associada');
  end if;

  select id into v_existente from public.atletas_360_pedidos_contacto
   where atleta_id = p_atleta_id and lower(responsavel_email) = v_email
     and estado in ('pendente','admin_em_curso','encarregado_notificado')
   limit 1;
  if v_existente is not null then
    return jsonb_build_object('ok',true,'ja_existia',true,'id',v_existente);
  end if;

  insert into public.atletas_360_pedidos_contacto
    (atleta_id, clube_id, clube_nome, responsavel_nome, responsavel_email, motivo)
  values (
    p_atleta_id, v_clube.id,
    coalesce(v_clube.clube_nome, 'Admin YTB'),
    coalesce(v_clube.responsavel_nome, v_email),
    coalesce(v_clube.responsavel_email, v_email),
    nullif(trim(coalesce(p_motivo,'')),'')
  )
  returning id into v_id;

  return jsonb_build_object('ok',true,'id',v_id);
end $$;

grant execute on function public.ytb_pedido_contacto_criar(uuid,text) to authenticated;

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
      from public.atleta_eventos e where e.atleta_id = v_atleta and e.categoria = 'marco'),
    'carreira', (
      select coalesce(jsonb_agg(jsonb_build_object('epoca', h.epoca) order by h.created_at desc), '[]'::jsonb)
      from public.atletas_360_historico h where h.atleta_id = v_atleta),
    'timeline', (
      select coalesce(jsonb_agg(t), '[]'::jsonb) from (
        select jsonb_build_object(
                 'categoria', e.categoria, 'origem', e.origem, 'titulo', e.titulo,
                 'fonte', e.fonte, 'em', e.criado_em, 'impacto', e.impacto) as t
        from public.atleta_eventos e where e.atleta_id = v_atleta
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
    'media', jsonb_build_object(
      'video',   (select case when coalesce(a2.video_consentido,false) then a2.video_path else null end from public.atletas_360 a2 where a2.id = v_atleta),
      'galeria', '[]'::jsonb)
  ) into j
  from public.atletas_360 a where a.id = v_atleta;
  return j;
end $$;
