-- ============================================================================
-- MIGRAÇÃO 002 · CONSENTIMENTO V2
-- Âmbitos separados, controlados PELA FAMÍLIA, com revogação real.
-- Sincroniza os flags operacionais existentes. Cada mudança emite evento.
-- ============================================================================

-- ── PRÉ-REQUISITO: constraints reais de produção precisam de 2 valores novos ──
alter table public.atletas_360 drop constraint if exists atletas_360_estado_check;
alter table public.atletas_360 add constraint atletas_360_estado_check
  check (estado = any (array['pendente'::text,'aprovado'::text,'rejeitado'::text,'arquivado'::text,'revogado'::text]));
alter table public.atletas_360 drop constraint if exists atletas_360_fonte_check;
alter table public.atletas_360 add constraint atletas_360_fonte_check
  check (fonte is null or fonte = any (array['pai'::text,'atleta'::text,'scout'::text,'treinador'::text,'admin'::text,'auto'::text]));

create table if not exists public.consentimentos (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atletas_360(id) on delete cascade,
  ambito text not null check (ambito in ('registo','visibilidade_b2b','montra_publica','foto','video')),
  autorizado boolean not null default false,
  versao text, decidido_por text, decidido_em timestamptz default now(),
  unique (atleta_id, ambito)
);

create or replace function public._ytb_e_encarregado(p_atleta uuid)
returns boolean language sql security definer set search_path = public as $$
  select exists (
    select 1 from public.atletas_360 a
    where a.id = p_atleta
      and lower(coalesce(a.encarregado_email,'')) = lower(coalesce(auth.jwt() ->> 'email',''))
      and coalesce(auth.jwt() ->> 'email','') <> ''
  )
$$;

create or replace function public.ytb_consentimentos(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public._ytb_e_encarregado(p_atleta) then return null; end if;
  return (
    select jsonb_build_object(
      'registo',          coalesce((select c.autorizado from consentimentos c where c.atleta_id=p_atleta and c.ambito='registo'), (select a.consentido_em is not null from atletas_360 a where a.id=p_atleta)),
      'visibilidade_b2b', coalesce((select autorizado from consentimentos where atleta_id=p_atleta and ambito='visibilidade_b2b'), (select coalesce(visivel_b2b,false) from atletas_360 where id=p_atleta)),
      'montra_publica',   coalesce((select autorizado from consentimentos where atleta_id=p_atleta and ambito='montra_publica'), (select coalesce(visivel_publico,false) from atletas_360 where id=p_atleta)),
      'foto',             coalesce((select autorizado from consentimentos where atleta_id=p_atleta and ambito='foto'), (select coalesce(foto_consentida,false) from atletas_360 where id=p_atleta)),
      'video',            coalesce((select autorizado from consentimentos where atleta_id=p_atleta and ambito='video'), (select coalesce(video_consentido,false) from atletas_360 where id=p_atleta)),
      'revogado',         (select coalesce(estado,'')='revogado' from atletas_360 where id=p_atleta)
    )
  );
end $$;

create or replace function public.ytb_consentir_ambito(p_atleta uuid, p_ambito text, p_autorizado boolean, p_versao text default 'v2')
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email',''));
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok',false,'motivo','nao_autorizado');
  end if;
  if p_ambito not in ('registo','visibilidade_b2b','montra_publica','foto','video') then
    return jsonb_build_object('ok',false,'motivo','ambito_invalido');
  end if;

  insert into public.consentimentos (atleta_id, ambito, autorizado, versao, decidido_por, decidido_em)
  values (p_atleta, p_ambito, p_autorizado, p_versao, v_email, now())
  on conflict (atleta_id, ambito)
  do update set autorizado = excluded.autorizado, versao = excluded.versao,
                decidido_por = excluded.decidido_por, decidido_em = now();

  if p_ambito = 'visibilidade_b2b' then
    update public.atletas_360 set visivel_b2b = p_autorizado where id = p_atleta;
  elsif p_ambito = 'montra_publica' then
    update public.atletas_360 set visivel_publico = p_autorizado where id = p_atleta;
  elsif p_ambito = 'foto' then
    update public.atletas_360 set foto_consentida = p_autorizado where id = p_atleta;
  elsif p_ambito = 'video' then
    update public.atletas_360 set video_consentido = p_autorizado where id = p_atleta;
  elsif p_ambito = 'registo' and p_autorizado = false then
    update public.atletas_360
       set estado = 'revogado', visivel_b2b=false, visivel_publico=false,
           oculto_pelo_responsavel = true
     where id = p_atleta;
    update public.consentimentos set autorizado=false, decidido_por=v_email, decidido_em=now()
     where atleta_id=p_atleta;
  elsif p_ambito = 'registo' and p_autorizado = true then
    update public.atletas_360
       set estado = case when coalesce(estado,'')='revogado' then 'aprovado' else estado end,
           oculto_pelo_responsavel = false,
           consentido_em = coalesce(consentido_em, now()),
           consentido_por = coalesce(consentido_por, v_email),
           versao_consentimento = p_versao
     where id = p_atleta;
  end if;

  insert into public.atleta_eventos
    (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, ref_tabela, ref_id, payload, criado_em)
  values
    (p_atleta, 'consentimento', 'marco',
     case when p_autorizado then 'Consentimento concedido: '||p_ambito
          else 'Consentimento retirado: '||p_ambito end,
     'encarregado', 'sistema', 5, null, null,
     jsonb_build_object('ambito',p_ambito,'autorizado',p_autorizado,'versao',p_versao,'por',v_email),
     now());

  return jsonb_build_object('ok',true,'ambito',p_ambito,'autorizado',p_autorizado);
end $$;

create or replace function public.ytb_revogar(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  return public.ytb_consentir_ambito(p_atleta, 'registo', false, 'v2');
end $$;

drop function if exists public.ytb_consentir_email(uuid, text);
create or replace function public.ytb_consentir_email(p_atleta uuid, p_versao text default 'v2', p_visivel_b2b boolean default true)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_nome text; v_ja boolean; v_email text; r jsonb;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email',''));
  if v_email = '' then return jsonb_build_object('ok',false,'motivo','sem_sessao'); end if;

  select a.id, a.nome, (a.consentido_em is not null)
    into v_id, v_nome, v_ja
    from public.atletas_360 a
   where a.id = p_atleta and lower(coalesce(a.encarregado_email,'')) = v_email
   limit 1;
  if v_id is null then return jsonb_build_object('ok',false,'motivo','nao_autorizado'); end if;

  if not v_ja then
    update public.atletas_360
       set consentido_em = now(), consentido_por = v_email,
           versao_consentimento = p_versao,
           estado = 'aprovado'
     where id = v_id;
    r := public.ytb_consentir_ambito(v_id, 'registo', true, p_versao);
    r := public.ytb_consentir_ambito(v_id, 'visibilidade_b2b', coalesce(p_visivel_b2b, true), p_versao);
  end if;

  return jsonb_build_object('ok',true,'id',v_id,'nome',v_nome,'ja_consentido',v_ja);
end $$;

create or replace function public.ytb_montra()
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'nome', a.nome, 'posicao', a.posicao_principal,
             'escalao', a.escalao, 'clube', a.clube_actual
           ) order by a.nome)
    from public.atletas_360 a
    where coalesce(a.visivel_publico,false) = true
      and a.consentido_em is not null
      and coalesce(a.oculto_pelo_responsavel,false) = false
      and coalesce(a.estado,'') <> 'revogado'
  ), '[]'::jsonb);
end $$;

grant execute on function public.ytb_consentimentos(uuid)                    to authenticated;
grant execute on function public.ytb_consentir_ambito(uuid, text, boolean, text) to authenticated;
grant execute on function public.ytb_revogar(uuid)                           to authenticated;
grant execute on function public.ytb_consentir_email(uuid, text, boolean)    to authenticated;
grant execute on function public.ytb_montra()                                to anon, authenticated;