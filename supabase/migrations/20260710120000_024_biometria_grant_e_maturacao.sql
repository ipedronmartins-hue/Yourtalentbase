-- ============================================================================
-- MIGRAÇÃO 024 · CORRIGE LEITURA DE BIOMETRIA (ADMIN) + MATURAÇÃO
--
-- BUG (reportado pelo fundador: "não consigo, nem como admin, dar entrada dos
-- dados de altura"): a migração 014 fez `revoke select on atleta_biometria
-- from anon` e criou as policies bd (bio_encarregado, bio_sel_admin) mas NUNCA
-- devolveu o `grant select ... to authenticated`. Sem o grant, uma leitura
-- direta (`supa.from('atleta_biometria')`, que é o que admin360.html faz para
-- mostrar o histórico) devolve zero linhas mesmo para o admin — a RLS
-- permitiria, mas falta o grant de tabela, e o Postgres exige os dois. A
-- família nunca deu por isto porque lê por RPC security definer
-- (ytb_biometria_historico), que ignora grants. Resultado: o admin registava
-- a medição (RPC de escrita funciona) mas nunca a via aparecer — parecia que
-- não guardava. Corrigido com o grant que faltava; a RLS continua a restringir
-- as linhas a encarregado (só os seus) + admin, exatamente como desenhado.
--
-- MATURAÇÃO (pedido do fundador: "ver nível de maturação, altura and so on"):
-- o modelo já tinha as colunas necessárias em atletas_360 (sexo, altura_pai,
-- altura_mae, data de nascimento completa) mas sem nenhum cálculo nem UI — a
-- secção "Morfologia & Maturação" do passaporte era um placeholder "Em breve".
-- Adicionado:
--   - _ytb_maturacao(atleta): estima a altura adulta prevista pelo método da
--     altura-alvo dos pais (Tanner: rapaz (pai+mãe+13)/2, rapariga
--     (pai+mãe−13)/2), a % dessa altura já atingida, quantos cm faltam, e a
--     velocidade de crescimento (cm/ano) a partir da série de medições. Tudo
--     rotulado como ESTIMATIVA, nunca diagnóstico (Constituição: nunca
--     prometer o que o sistema não faz; contexto antes de números). Devolve
--     também 'em_falta' com o que ainda precisa de ser preenchido.
--   - a maturação entra no passaporte via _ytb_passaporte_json (herda o
--     controlo de acesso de cada chamador — admin/scout/clube/família — e a
--     regra de que a morfologia nunca é pública).
--   - ytb_biometria_pais_registar(atleta, altura_pai, altura_mae): família ou
--     admin regista a altura dos pais (dado de referência estático, não é
--     facto longitudinal — não emite evento no livro-razão).
--
-- Validado em dry-run transacional (2026-07-10): grant repara leitura do admin;
-- maturação calcula com pais preenchidos e reporta em_falta sem; altura dos
-- pais gravada por encarregado e admin; intruso bloqueado.
-- ============================================================================

grant select on public.atleta_biometria to authenticated;

create or replace function public._ytb_maturacao(v_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  a public.atletas_360;
  v_altura_atual numeric; v_altura_em date;
  v_idade numeric; v_prevista numeric; v_pct numeric; v_faltam numeric;
  v_vel numeric; v_n int; v_primeira record; v_ultima record; v_dias numeric;
  v_falta text[] := array[]::text[];
begin
  select * into a from public.atletas_360 where id = v_atleta;
  if a.id is null then return null; end if;

  -- altura atual: medição mais recente; fallback para a ficha
  select altura_cm, medido_em into v_altura_atual, v_altura_em
    from public.atleta_biometria
   where atleta_id = v_atleta and altura_cm is not null
   order by medido_em desc limit 1;
  if v_altura_atual is null then v_altura_atual := a.altura_cm; end if;

  -- idade decimal (anos)
  if a.ano_nascimento is not null then
    v_idade := round(extract(epoch from age(current_date,
      make_date(a.ano_nascimento, coalesce(a.mes_nascimento,1), coalesce(a.dia_nascimento,1))
    )) / 31557600.0, 1);
  end if;

  -- altura adulta prevista (altura-alvo dos pais, método de Tanner)
  if a.sexo in ('M','F') and a.altura_pai is not null and a.altura_mae is not null then
    v_prevista := round(case a.sexo
      when 'M' then (a.altura_pai + a.altura_mae + 13) / 2.0
      else          (a.altura_pai + a.altura_mae - 13) / 2.0 end);
  end if;

  if v_prevista is not null and v_altura_atual is not null then
    v_pct := round(100.0 * v_altura_atual / v_prevista);
    v_faltam := round(v_prevista - v_altura_atual);
  end if;

  -- velocidade de crescimento (cm/ano) a partir da primeira e última medição,
  -- se houver pelo menos duas separadas por >= 60 dias
  select count(*) into v_n from public.atleta_biometria
   where atleta_id = v_atleta and altura_cm is not null;
  if v_n >= 2 then
    select altura_cm, medido_em into v_primeira
      from public.atleta_biometria where atleta_id = v_atleta and altura_cm is not null
      order by medido_em asc limit 1;
    select altura_cm, medido_em into v_ultima
      from public.atleta_biometria where atleta_id = v_atleta and altura_cm is not null
      order by medido_em desc limit 1;
    v_dias := v_ultima.medido_em - v_primeira.medido_em;
    if v_dias >= 60 then
      v_vel := round((v_ultima.altura_cm - v_primeira.altura_cm) / (v_dias / 365.25), 1);
    end if;
  end if;

  -- o que ainda falta preencher para a estimativa ficar completa
  if a.sexo is null or a.sexo not in ('M','F') then v_falta := array_append(v_falta, 'sexo'); end if;
  if a.altura_pai is null then v_falta := array_append(v_falta, 'altura_pai'); end if;
  if a.altura_mae is null then v_falta := array_append(v_falta, 'altura_mae'); end if;
  if v_altura_atual is null then v_falta := array_append(v_falta, 'altura_atual'); end if;

  return jsonb_build_object(
    'idade_anos', v_idade,
    'sexo', a.sexo,
    'altura_atual', v_altura_atual,
    'altura_atual_em', v_altura_em,
    'altura_pai', a.altura_pai,
    'altura_mae', a.altura_mae,
    'altura_prevista', v_prevista,
    'pct_atingida', v_pct,
    'faltam_cm', v_faltam,
    'velocidade_cm_ano', v_vel,
    'medicoes', v_n,
    'em_falta', to_jsonb(v_falta),
    'metodo', 'Altura-alvo dos pais (Tanner) · estimativa, não diagnóstico'
  );
end $$;

create or replace function public.ytb_biometria_pais_registar(
  p_atleta uuid, p_altura_pai numeric default null, p_altura_mae numeric default null
) returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not (public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin()) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_altura_pai is not null and (p_altura_pai < 120 or p_altura_pai > 230) then
    return jsonb_build_object('ok', false, 'motivo', 'altura_pai_invalida');
  end if;
  if p_altura_mae is not null and (p_altura_mae < 120 or p_altura_mae > 230) then
    return jsonb_build_object('ok', false, 'motivo', 'altura_mae_invalida');
  end if;
  update public.atletas_360
     set altura_pai = coalesce(p_altura_pai, altura_pai),
         altura_mae = coalesce(p_altura_mae, altura_mae)
   where id = p_atleta;
  return jsonb_build_object('ok', true, 'maturacao', public._ytb_maturacao(p_atleta));
end $$;

grant execute on function public.ytb_biometria_pais_registar(uuid,numeric,numeric) to authenticated;

-- _ytb_passaporte_json ganha a chave 'maturacao' (mantém tudo o resto da 022)
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
    'maturacao', public._ytb_maturacao(v_atleta),
    'media', jsonb_build_object(
      'video',   (select case when coalesce(a2.video_consentido,false) then a2.video_path else null end from public.atletas_360 a2 where a2.id = v_atleta),
      'galeria', '[]'::jsonb)
  ) into j
  from public.atletas_360 a where a.id = v_atleta;
  return j;
end $$;
