-- ============================================================================
-- MIGRAÇÃO 019 · CORRIGE "RELATORIOS" NO PASSAPORTE (scout report nunca aparecia)
-- Bug: o filtro de 'relatorios' em _ytb_passaporte_json (e nas cópias duplicadas
-- em ytb_passaporte_admin e ytb_passaporte_email) procurava tipo='avaliacao',
-- um valor que nunca existiu na tabela (os reais são 'avaliacao_treinador',
-- 'autoavaliacao_familia', 'scout_report', ...). Corrigido para tipo='scout_report'
-- (o que fn_evento_report emite quando um scout report é criado em 'relatorios').
-- Aproveitado para eliminar duplicação: ytb_passaporte_admin e
-- ytb_passaporte_email tinham cada uma a sua própria cópia integral do mesmo
-- jsonb_build_object gigante (idêntica a _ytb_passaporte_json); passam a
-- delegar na função partilhada, mantendo só a guarda de acesso própria.
-- ytb_passaporte_scout já delegava — sem alterações, herda a correção.
-- Validado em dry-run (2026-07-06): scout report real → evento 'scout_report' →
-- aparece em 'relatorios' nas 3 RPCs quando autorizado (família dona, admin,
-- scout dono); continua null para intruso em cada uma das 3.
-- ============================================================================

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
      'epocas',       (select count(distinct date_part('year', e.criado_em)) from public.atleta_eventos e where e.atleta_id = v_atleta)),
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

create or replace function public.ytb_passaporte_admin(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_atleta uuid := p_atleta; v_email text;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email not in ('ipedronmartins@gmail.com', 'yourtalentbase@gmail.com')
     and not exists (
       select 1 from public.perfis p
        where lower(p.email) = v_email and p.papel = 'admin' and p.estado = 'aprovado')
  then
    return null;
  end if;
  if v_atleta is null then
    return null;
  end if;
  return public._ytb_passaporte_json(v_atleta);
end $$;

create or replace function public.ytb_passaporte_email(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_atleta uuid; v_email text;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return null; end if;
  select a.id into v_atleta
    from public.atletas_360 a
   where a.id = p_atleta and lower(coalesce(a.encarregado_email,'')) = v_email
   limit 1;
  if v_atleta is null then
    return null;
  end if;
  return public._ytb_passaporte_json(v_atleta);
end $$;
