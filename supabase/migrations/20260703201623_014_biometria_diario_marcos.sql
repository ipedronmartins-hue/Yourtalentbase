-- ============================================================================
-- MIGRAÇÃO 014 · BIOMETRIA LONGITUDINAL + DIÁRIO LIVRE + MARCOS DE SEQUÊNCIA
-- Biometria é série temporal (trajetória, não instante); a ficha atletas_360
-- recebe apenas o valor mais recente por conveniência. Diário livre reutiliza
-- familia_treinos (atividade: plano/livre/jogo/clube) — entra direto no
-- passaporte via trigger existente. Sequência calculada server-side; marcos
-- de 7/14/30 dias emitem evento 'marco_sequencia' imutável e idempotente
-- (dedupe por ref_tabela/ref_id). ytb_treino_registar passa a devolver a
-- sequência também — qualquer treino alimenta a mesma chama.
-- Validada em dry-run transacional (2026-07-03): registos ✓, validações ✓,
-- eventos ✓, marco 7 idempotente ✓, intruso bloqueado ✓.
-- ============================================================================

create table if not exists public.atleta_biometria (
  id         uuid primary key default gen_random_uuid(),
  atleta_id  uuid not null references public.atletas_360(id) on delete cascade,
  altura_cm  numeric check (altura_cm is null or altura_cm between 80 and 220),
  peso_kg    numeric check (peso_kg   is null or peso_kg   between 15 and 120),
  pe_eu      numeric check (pe_eu     is null or pe_eu     between 20 and 50),
  medido_em  date not null default current_date,
  fonte      text not null default 'familia',
  criado_em  timestamptz not null default now()
);
create index if not exists atleta_biometria_atleta_idx
  on public.atleta_biometria (atleta_id, medido_em desc);
alter table public.atleta_biometria enable row level security;
revoke insert, update, delete on public.atleta_biometria from anon, authenticated;
revoke select on public.atleta_biometria from anon;
drop policy if exists bio_encarregado on public.atleta_biometria;
create policy bio_encarregado on public.atleta_biometria for select to authenticated
  using (public._ytb_e_encarregado(atleta_id));
drop policy if exists bio_sel_admin on public.atleta_biometria;
create policy bio_sel_admin on public.atleta_biometria for select to authenticated
  using (public.ytb_is_admin());

drop trigger if exists ytb_ev_atleta_biometria on public.atleta_biometria;
create trigger ytb_ev_atleta_biometria after insert on public.atleta_biometria
  for each row execute function public.ytb_emitir_evento(
    'biometria','familia','Medição registada','declarado','atleta_id','historico','2');

create or replace function public.ytb_biometria_registar(
  p_atleta uuid, p_altura_cm numeric, p_peso_kg numeric, p_pe_eu numeric,
  p_medido_em date default current_date
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_altura_cm is null and p_peso_kg is null and p_pe_eu is null then
    return jsonb_build_object('ok', false, 'motivo', 'sem_valores');
  end if;
  insert into public.atleta_biometria (atleta_id, altura_cm, peso_kg, pe_eu, medido_em)
  values (p_atleta, p_altura_cm, p_peso_kg, p_pe_eu, coalesce(p_medido_em, current_date))
  returning id into v_id;
  update public.atletas_360
     set altura_cm = coalesce(p_altura_cm::int, altura_cm),
         peso_kg   = coalesce(p_peso_kg::int,   peso_kg)
   where id = p_atleta;
  return jsonb_build_object('ok', true, 'id', v_id);
end $$;

create or replace function public.ytb_biometria_historico(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public._ytb_e_encarregado(p_atleta) then return null; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'medido_em', b.medido_em, 'altura_cm', b.altura_cm,
             'peso_kg', b.peso_kg, 'pe_eu', b.pe_eu) order by b.medido_em)
      from public.atleta_biometria b where b.atleta_id = p_atleta
  ), '[]'::jsonb);
end $$;

alter table public.familia_treinos add column if not exists atividade text;
alter table public.familia_treinos drop constraint if exists familia_treinos_atividade_chk;
alter table public.familia_treinos add constraint familia_treinos_atividade_chk
  check (atividade is null or atividade in ('plano','livre','jogo','clube'));

create or replace function public._ytb_streak_marco(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_streak int; v_marco int := null;
begin
  select count(*) into v_streak
  from (
    select d, row_number() over (order by d desc) as rn
    from (select distinct created_at::date as d
            from public.familia_treinos where atleta_id = p_atleta) x
  ) y
  where d = current_date - (rn - 1)::int;

  if v_streak in (7, 14, 30) then
    insert into public.atleta_eventos
      (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia,
       ref_tabela, ref_id, payload)
    values
      (p_atleta, 'marco_sequencia', 'marco',
       'Sequência de '||v_streak||' dias de treino 🔥',
       'familia', 'sistema', 3,
       'streak', p_atleta::text || ':' || v_streak,
       jsonb_build_object('dias', v_streak))
    on conflict (ref_tabela, ref_id) where ref_id is not null do nothing;
    if found then v_marco := v_streak; end if;
  end if;

  return jsonb_build_object('streak', v_streak, 'marco', v_marco);
end $$;

create or replace function public.ytb_diario_registar(
  p_atleta uuid, p_atividade text, p_minutos numeric, p_nota text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_s jsonb; v_label text;
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_atividade not in ('livre','jogo','clube') then
    return jsonb_build_object('ok', false, 'motivo', 'atividade_invalida');
  end if;
  if coalesce(p_minutos, 0) <= 0 or p_minutos > 600 then
    return jsonb_build_object('ok', false, 'motivo', 'minutos');
  end if;
  v_label := case p_atividade when 'livre' then 'Treino livre'
                              when 'jogo'  then 'Jogo' else 'Treino no clube' end;
  insert into public.familia_treinos
    (atleta_id, exercicio, atividade, resultado, tempo, feedback, tempo_fonte, created_at)
  values
    (p_atleta, v_label, p_atividade,
     jsonb_build_object('atividade', p_atividade, 'submetido_por', 'familia'),
     p_minutos, nullif(trim(p_nota),''), 'familia', now())
  returning id into v_id;
  v_s := public._ytb_streak_marco(p_atleta);
  return jsonb_build_object('ok', true, 'id', v_id,
    'streak', v_s->'streak', 'marco', v_s->'marco');
end $$;

create or replace function public.ytb_treino_registar(
  p_atleta uuid,
  p_exercicio text,
  p_resultado jsonb,
  p_tempo numeric,
  p_confianca int,
  p_flags jsonb default '[]'::jsonb,
  p_prescrito_id uuid default null,
  p_semana int default null,
  p_sessao int default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_s jsonb;
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if coalesce(trim(p_exercicio),'') = '' then
    return jsonb_build_object('ok', false, 'motivo', 'exercicio');
  end if;
  insert into public.familia_treinos
    (atleta_id, exercicio, atividade, resultado, tempo, confianca, flags,
     prescrito_id, semana, sessao, tempo_fonte, created_at)
  values
    (p_atleta, trim(p_exercicio), 'plano', coalesce(p_resultado,'{}'::jsonb),
     greatest(p_tempo, 0),
     case when p_confianca between 0 and 100 then p_confianca else null end,
     coalesce(p_flags,'[]'::jsonb),
     p_prescrito_id, p_semana, p_sessao, 'familia', now())
  returning id into v_id;
  v_s := public._ytb_streak_marco(p_atleta);
  return jsonb_build_object('ok', true, 'id', v_id,
    'streak', v_s->'streak', 'marco', v_s->'marco');
end $$;

grant execute on function public.ytb_biometria_registar(uuid,numeric,numeric,numeric,date) to authenticated;
grant execute on function public.ytb_biometria_historico(uuid) to authenticated;
grant execute on function public.ytb_diario_registar(uuid,text,numeric,text) to authenticated;
grant execute on function public.ytb_treino_registar(uuid,text,jsonb,numeric,int,jsonb,uuid,int,int) to authenticated;