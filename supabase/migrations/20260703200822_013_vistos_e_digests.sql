-- ============================================================================
-- MIGRAÇÃO 013 · VISTOS + OS DOIS DIGESTS
-- O livro-razão É a fonte das notificações: "o que mudou" = eventos desde a
-- última visita (atleta_vistos é o único estado novo). Pendências calculadas
-- na hora (pull no login) — sem cron, sem tabela de notificações.
-- ytb_o_que_mudou fala linguagem de pai (sem jargão, sem notas).
-- ytb_treinador_digest fecha o círculo do treinador: retorno por atleta.
-- Validada em dry-run transacional (2026-07-03): família lê ✓, visto zera ✓,
-- intruso bloqueado (leitura+escrita) ✓, digest array ✓, família sem digest ✓.
-- ============================================================================

create table if not exists public.atleta_vistos (
  email     text not null,
  atleta_id uuid not null references public.atletas_360(id) on delete cascade,
  visto_em  timestamptz not null default now(),
  primary key (email, atleta_id)
);
alter table public.atleta_vistos enable row level security;
revoke insert, update, delete on public.atleta_vistos from anon, authenticated;
revoke select on public.atleta_vistos from anon;
drop policy if exists vistos_dono on public.atleta_vistos;
create policy vistos_dono on public.atleta_vistos for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt()->>'email','')));

create or replace function public.ytb_marcar_visto(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  insert into public.atleta_vistos (email, atleta_id, visto_em)
  values (v_email, p_atleta, now())
  on conflict (email, atleta_id) do update set visto_em = now();
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.ytb_o_que_mudou(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_email text; v_desde timestamptz;
  v_novidades jsonb; v_pendencias jsonb := '[]'::jsonb;
  v_ultimo_treino timestamptz; v_meses_bio int;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_encarregado(p_atleta) then return null; end if;

  select visto_em into v_desde from public.atleta_vistos
   where email = v_email and atleta_id = p_atleta;

  -- novidades: o que OUTROS registaram desde a última visita (linguagem de pai)
  select coalesce(jsonb_agg(jsonb_build_object(
           'em', e.criado_em,
           'tipo', e.tipo,
           'msg', case e.tipo
             when 'treino_prescrito'     then 'O treinador deixou um plano de treino novo 🎯'
             when 'avaliacao_treinador'  then 'O treinador fez uma nova avaliação'
             when 'avaliacao'            then 'Um observador registou uma nova avaliação'
             when 'relatorio_jogo'       then 'Há um novo relatório de jogo'
             when 'relatorio_scout'      then 'Um scout observou o teu atleta'
             when 'estado_admin'         then coalesce(e.titulo,'O registo foi atualizado')
             when 'interesse_clube'      then 'Um clube mostrou interesse — a YTB contacta-te'
             else coalesce(e.titulo, 'Novidade no percurso')
           end) order by e.criado_em desc), '[]'::jsonb)
    into v_novidades
    from public.atleta_eventos e
   where e.atleta_id = p_atleta
     and (v_desde is null or e.criado_em > v_desde)
     and coalesce(e.fonte,'') not in ('familia','encarregado')
     and e.tipo <> 'consentimento';

  -- pendências inteligentes (calculadas na hora, sem tabela de notificações)
  select max(e.criado_em) into v_ultimo_treino
    from public.atleta_eventos e
   where e.atleta_id = p_atleta and e.tipo = 'treino_executado';

  if v_ultimo_treino is not null
     and v_ultimo_treino between now() - interval '72 hours' and now() - interval '24 hours' then
    v_pendencias := v_pendencias || jsonb_build_object(
      'tipo','streak_risco','msg','A sequência está em risco — um treino hoje mantém a chama 🔥');
  end if;

  if exists (select 1 from public.treinador_treinos t
              where t.atleta_id = p_atleta
                and t.criado_em > coalesce(v_ultimo_treino, '-infinity'::timestamptz)) then
    v_pendencias := v_pendencias || jsonb_build_object(
      'tipo','plano_por_comecar','msg','Há um plano de treino à espera do primeiro treino');
  end if;

  if to_regclass('public.atleta_biometria') is not null then
    execute 'select (extract(epoch from now() - max(criado_em)) / 2592000)::int
               from public.atleta_biometria where atleta_id = $1'
      into v_meses_bio using p_atleta;
    if v_meses_bio is null or v_meses_bio >= 3 then
      v_pendencias := v_pendencias || jsonb_build_object(
        'tipo','biometria','msg', case when v_meses_bio is null
          then 'Regista a altura, o peso e o tamanho do pé — a trajetória começa na primeira medição'
          else 'Já passaram '||v_meses_bio||' meses desde a última medição — atualiza altura e peso' end);
    end if;
  end if;

  return jsonb_build_object(
    'desde', v_desde,
    'novidades', v_novidades,
    'nao_vistos', jsonb_array_length(v_novidades),
    'pendencias', v_pendencias);
end $$;

create or replace function public.ytb_treinador_digest()
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; j jsonb;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public.ytb_is_treinador() then return null; end if;

  select coalesce(jsonb_agg(linha order by (linha->>'ultima_atividade') desc nulls last), '[]'::jsonb)
    into j
  from (
    select jsonb_build_object(
      'atleta_id', a.id,
      'nome', a.nome,
      'escalao', a.escalao,
      'dias_desde_avaliacao',
        (select (now()::date - max(av.criado_em)::date)
           from public.treinador_avaliacoes av
          where av.atleta_id = a.id and lower(coalesce(av.treinador_email,'')) = v_email),
      'plano_prescrito_em',
        (select max(t.criado_em) from public.treinador_treinos t where t.atleta_id = a.id),
      'execucoes_desde_plano',
        (select count(*) from public.familia_treinos f
          where f.atleta_id = a.id
            and f.created_at > coalesce((select max(t.criado_em) from public.treinador_treinos t
                                          where t.atleta_id = a.id), '-infinity'::timestamptz)),
      'execucoes_total',
        (select count(*) from public.familia_treinos f where f.atleta_id = a.id),
      'confianca_media',
        (select round(avg(f.confianca)) from (
           select confianca from public.familia_treinos
            where atleta_id = a.id and confianca is not null
            order by created_at desc limit 10) f),
      'ultimo_feedback',
        (select f.feedback from public.familia_treinos f
          where f.atleta_id = a.id and coalesce(trim(f.feedback),'') <> ''
          order by f.created_at desc limit 1),
      'ultima_atividade',
        (select max(f.created_at) from public.familia_treinos f where f.atleta_id = a.id)
    ) as linha
    from public.atletas_360 a
    where lower(coalesce(a.fonte_email,'')) = v_email
       or exists (select 1 from public.treinador_avaliacoes av
                   where av.atleta_id = a.id and lower(coalesce(av.treinador_email,'')) = v_email)
  ) s;

  return j;
end $$;

grant execute on function public.ytb_marcar_visto(uuid)     to authenticated;
grant execute on function public.ytb_o_que_mudou(uuid)      to authenticated;
grant execute on function public.ytb_treinador_digest()     to authenticated;