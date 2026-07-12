-- ============================================================================
-- MIGRAÇÃO 028 · BALNEÁRIO — comunidade privada de treinadores (CoachBase)
-- Pedido do fundador: "algo como uma rede social ou tipo reddit onde os
-- treinadores trocassem ideias, taticas, o que for". Decisões do fundador
-- (2026-07-12): nome "Balneário", PRIVADO — só treinadores aprovados leem
-- e escrevem (conversa franca, valor da subscrição, zero exposição pública).
-- Posts podem anexar uma jogada da prancheta (jsonb) que outros treinadores
-- abrem na prancheta deles. Sem dados de menores: regra da casa na UI; a
-- comunidade fala de táticas, nunca de miúdos identificáveis.
-- Nota: posts NÃO emitem atleta_eventos — o livro-razão é do atleta e isto
-- não é um facto de atleta. Escrita só por RPC; RLS deny-by-default com
-- leitura gated pela guarda estrita (que para isso ganha EXECUTE de
-- authenticated — devolve um boolean sobre o próprio, nada vaza).
-- Validado em dry-run (2026-07-12): publicar, votar (toggle vota/retira),
-- comentar, feed com ja_votei/n_comentarios/e_meu, apagar pelo autor, e
-- guarda: scout real (+jonas) bloqueado — nota: o 1º teste de intruso usou
-- +miro que afinal É treinador em produção; teste corrigido.
-- ============================================================================

grant execute on function public._ytb_e_treinador_estrito() to authenticated;

create table if not exists public.coach_posts (
  id uuid primary key default gen_random_uuid(),
  autor_email text not null,
  autor_nome text,
  titulo text not null check (char_length(titulo) between 3 and 140),
  corpo text check (char_length(corpo) <= 4000),
  jogada jsonb,
  tag text,
  votos int not null default 0,
  criado_em timestamptz not null default now()
);
create index if not exists coach_posts_recentes_idx on public.coach_posts (criado_em desc);
alter table public.coach_posts enable row level security;
revoke insert, update, delete on public.coach_posts from anon, authenticated;
revoke select on public.coach_posts from anon;
drop policy if exists bp_treinadores on public.coach_posts;
create policy bp_treinadores on public.coach_posts for select to authenticated
  using (public._ytb_e_treinador_estrito());

create table if not exists public.coach_post_votos (
  post_id uuid not null references public.coach_posts(id) on delete cascade,
  votante_email text not null,
  criado_em timestamptz not null default now(),
  primary key (post_id, votante_email)
);
alter table public.coach_post_votos enable row level security;
revoke insert, update, delete, select on public.coach_post_votos from anon, authenticated;

create table if not exists public.coach_comentarios (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.coach_posts(id) on delete cascade,
  autor_email text not null,
  autor_nome text,
  corpo text not null check (char_length(corpo) between 1 and 1000),
  criado_em timestamptz not null default now()
);
create index if not exists coach_comentarios_post_idx on public.coach_comentarios (post_id, criado_em);
alter table public.coach_comentarios enable row level security;
revoke insert, update, delete on public.coach_comentarios from anon, authenticated;
revoke select on public.coach_comentarios from anon;
drop policy if exists bc_treinadores on public.coach_comentarios;
create policy bc_treinadores on public.coach_comentarios for select to authenticated
  using (public._ytb_e_treinador_estrito());

create or replace function public.ytb_balneario_publicar(p_titulo text, p_corpo text, p_jogada jsonb, p_tag text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_nome text; v_id uuid;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_treinador_estrito() then return jsonb_build_object('ok',false,'motivo','sem_papel_treinador'); end if;
  if coalesce(trim(p_titulo),'') = '' or char_length(trim(p_titulo)) < 3 then
    return jsonb_build_object('ok',false,'motivo','titulo_curto');
  end if;
  select nome into v_nome from public.perfis where lower(email)=v_email;
  insert into public.coach_posts (autor_email, autor_nome, titulo, corpo, jogada, tag)
  values (v_email, coalesce(v_nome,'Treinador'), trim(p_titulo), nullif(trim(coalesce(p_corpo,'')),''), p_jogada, nullif(trim(coalesce(p_tag,'')),''))
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;
grant execute on function public.ytb_balneario_publicar(text,text,jsonb,text) to authenticated;

-- voto em toggle: primeiro clique vota, segundo retira
create or replace function public.ytb_balneario_votar(p_post uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_del int;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_treinador_estrito() then return jsonb_build_object('ok',false,'motivo','sem_papel_treinador'); end if;
  delete from public.coach_post_votos where post_id=p_post and votante_email=v_email;
  get diagnostics v_del = row_count;
  if v_del = 0 then
    insert into public.coach_post_votos (post_id, votante_email) values (p_post, v_email);
  end if;
  update public.coach_posts set votos = (select count(*) from public.coach_post_votos where post_id=p_post) where id=p_post;
  return jsonb_build_object('ok',true,'votou', v_del = 0,
    'votos',(select votos from public.coach_posts where id=p_post));
end $$;
grant execute on function public.ytb_balneario_votar(uuid) to authenticated;

create or replace function public.ytb_balneario_comentar(p_post uuid, p_corpo text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_nome text; v_id uuid;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_treinador_estrito() then return jsonb_build_object('ok',false,'motivo','sem_papel_treinador'); end if;
  if coalesce(trim(p_corpo),'') = '' then return jsonb_build_object('ok',false,'motivo','comentario_vazio'); end if;
  if not exists (select 1 from public.coach_posts where id=p_post) then return jsonb_build_object('ok',false,'motivo','post_inexistente'); end if;
  select nome into v_nome from public.perfis where lower(email)=v_email;
  insert into public.coach_comentarios (post_id, autor_email, autor_nome, corpo)
  values (p_post, v_email, coalesce(v_nome,'Treinador'), trim(p_corpo))
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;
grant execute on function public.ytb_balneario_comentar(uuid,text) to authenticated;

create or replace function public.ytb_balneario_feed(p_ordem text default 'recentes', p_limit int default 30)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_treinador_estrito() then return '[]'::jsonb; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
      'id', p.id, 'autor_nome', p.autor_nome, 'titulo', p.titulo, 'corpo', p.corpo,
      'jogada', p.jogada, 'tag', p.tag, 'votos', p.votos, 'criado_em', p.criado_em,
      'e_meu', (p.autor_email = v_email),
      'ja_votei', exists (select 1 from public.coach_post_votos v where v.post_id=p.id and v.votante_email=v_email),
      'n_comentarios', (select count(*) from public.coach_comentarios c where c.post_id=p.id)
    ) order by case when p_ordem='top' then p.votos end desc nulls last, p.criado_em desc)
    from (select * from public.coach_posts
          order by case when p_ordem='top' then votos end desc nulls last, criado_em desc
          limit greatest(1,least(p_limit,100))) p), '[]'::jsonb);
end $$;
grant execute on function public.ytb_balneario_feed(text,int) to authenticated;

create or replace function public.ytb_balneario_comentarios(p_post uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public._ytb_e_treinador_estrito() then return '[]'::jsonb; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
      'autor_nome', c.autor_nome, 'corpo', c.corpo, 'criado_em', c.criado_em) order by c.criado_em)
    from public.coach_comentarios c where c.post_id = p_post), '[]'::jsonb);
end $$;
grant execute on function public.ytb_balneario_comentarios(uuid) to authenticated;

-- apagar: autor do post ou admin (moderação)
create or replace function public.ytb_balneario_apagar(p_post uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_n int;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  delete from public.coach_posts
  where id = p_post and (autor_email = v_email or public.ytb_is_admin());
  get diagnostics v_n = row_count;
  if v_n = 0 then return jsonb_build_object('ok',false,'motivo','nao_autorizado_ou_inexistente'); end if;
  return jsonb_build_object('ok',true);
end $$;
grant execute on function public.ytb_balneario_apagar(uuid) to authenticated;
