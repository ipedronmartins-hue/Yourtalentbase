-- ============================================================================
-- MIGRAÇÃO 035b · FAMÍLIA: OBJETIVO NO PLANO + CHECK-IN PÓS-JOGO
--
-- Vaga "Objetivos, não treinos" (decisão do fundador 2026-07-16): o atleta
-- deixa de ver "planos de treino" e passa a ver UM objetivo derivado das
-- debilidades detetadas pelo treinador, com missões curtas ao serviço dele.
--
-- 1) ytb_plano_atual passa a devolver também:
--    - 'debilidades' (da avaliação ligada ao plano; fallback para a avaliação
--      mais recente do atleta) — é daqui que o frontend deriva o Objetivo
--      via YTBObjetivos.objetivoDoPlano(). Sem isto a família não tinha
--      acesso ao bucket (só o treinador via as debilidades).
--    - 'ultimo_checkin_jogo' (max created_at de familia_treinos com
--      atividade='jogo') — para o card do check-in se esconder durante 4
--      dias depois de respondido (throttle no cliente, dado no servidor).
--    Tudo o resto mantém-se — nada que já lia parte.
--
-- 2) ytb_jogo_checkin(p_atleta, p_dificuldade 1-5, p_nota): a família
--    responde a UMA pergunta depois do jogo ("Sentiste dificuldade em
--    <verbo do objetivo>?"). Insere familia_treinos com atividade='jogo'
--    (o CHECK da coluna já o permitia desde a 000b; nunca tinha sido usado),
--    resultado={dificuldade}, feedback=p_nota — o texto aparece de borla no
--    'ultimo_feedback' do digest do treinador, sem mexer no digest.
--    'confianca' fica NULL de propósito: a coluna já mistura duas escalas
--    (0-100 do registar, 1-5 do feedback) e não se junta uma terceira à
--    média cega do digest. A dificuldade vive em resultado jsonb.
--    Evento no livro-razão: automático — familia_treinos já tem o trigger
--    genérico (tipo='treino_executado').
--
-- Validado em dry-run transacional (2026-07-16): encarregado real grava
-- check-in ✓, intruso bloqueado ✓, dificuldade fora de 1-5 bloqueada ✓,
-- plano_atual devolve debilidades reais e ultimo_checkin_jogo ✓.
-- ============================================================================

create or replace function public.ytb_plano_atual(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_id uuid; v_plano jsonb; v_em timestamptz; v_treinador text; v_debs jsonb;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return null; end if;
  if not exists (
    select 1 from public.atletas_360 a
     where a.id = p_atleta and lower(coalesce(a.encarregado_email,'')) = v_email
  ) then return null; end if;

  select t.id, t.plano, t.criado_em into v_id, v_plano, v_em
    from public.treinador_treinos t
   where t.atleta_id = p_atleta
   order by t.criado_em desc limit 1;

  if v_id is null then return jsonb_build_object('tem', false); end if;

  select coalesce(pf.nome, av.treinador_email), av.debilidades into v_treinador, v_debs
    from public.treinador_treinos t
    left join public.treinador_avaliacoes av on av.id = t.avaliacao_id
    left join public.perfis pf on lower(pf.email) = lower(coalesce(av.treinador_email,''))
   where t.id = v_id;
  if v_treinador is null or v_debs is null then
    select coalesce(v_treinador, coalesce(pf.nome, av.treinador_email)),
           coalesce(v_debs, av.debilidades)
      into v_treinador, v_debs
      from public.treinador_avaliacoes av
      left join public.perfis pf on lower(pf.email) = lower(coalesce(av.treinador_email,''))
     where av.atleta_id = p_atleta
     order by av.criado_em desc limit 1;
  end if;

  return jsonb_build_object(
    'tem', true, 'prescrito_id', v_id, 'criado_em', v_em, 'plano', v_plano,
    'treinador_nome', coalesce(v_treinador, 'O teu treinador'),
    'debilidades', coalesce(v_debs, '[]'::jsonb),
    'ultimo_checkin_jogo', (
      select max(f.created_at) from public.familia_treinos f
      where f.atleta_id = p_atleta and f.atividade = 'jogo'
    ),
    'feitas', (
      select coalesce(jsonb_agg(distinct jsonb_build_object('semana', f.semana, 'sessao', f.sessao)), '[]'::jsonb)
      from public.familia_treinos f
      where f.atleta_id = p_atleta and f.prescrito_id = v_id and f.semana is not null
    ));
end $$;

create or replace function public.ytb_jogo_checkin(
  p_atleta uuid, p_dificuldade int, p_nota text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_dificuldade is null or p_dificuldade < 1 or p_dificuldade > 5 then
    return jsonb_build_object('ok', false, 'motivo', 'dificuldade_invalida');
  end if;

  insert into public.familia_treinos
    (atleta_id, exercicio, atividade, resultado, tempo, confianca, feedback, tempo_fonte, created_at)
  values
    (p_atleta, 'Check-in de jogo', 'jogo',
     jsonb_build_object('dificuldade', p_dificuldade),
     0, null,
     left(nullif(trim(coalesce(p_nota,'')),''), 500),
     'familia', now())
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end $$;

grant execute on function public.ytb_jogo_checkin(uuid,int,text) to authenticated;
