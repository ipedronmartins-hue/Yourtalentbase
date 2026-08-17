-- 093: a relacao academia<->atleta passa a existir de facto.
--
-- Antes: uma academia "tinha" um atleta se e so se fonte='clube' AND
-- fonte_email=responsavel_email -- ou seja, inferida por QUEM O CRIOU.
-- Consequencia real encontrada em producao: a unica academia do piloto
-- via ZERO atletas no painel dela, porque os atletas foram inscritos por
-- treinadores e pelo fundador (a academia estava com falta de pessoal),
-- nao pela conta da academia. A mesma classe de falha (posse por email em
-- vez de modelada) ja tinha causado a 079 (RLS de treinador sem filtro de
-- posse) e a 075 (reatribuicao).
--
-- Agora: academia_id em perfis (que treinador pertence a que academia) e
-- em atletas_360 (que atleta pertence a que academia). Relacao declarada,
-- nao adivinhada -- e cada mudanca emite evento no livro-razao.
--
-- SEM backfill automatico: nao ha sinal fiavel de onde derivar. Nota
-- importante para quem ler isto depois: clube_actual NAO e a academia --
-- e o clube federado onde o atleta joga (um miudo joga num clube e treina
-- numa academia; sao eixos diferentes e misturar partia o passaporte).
--
-- SEGURANCA: a ligacao e ADMIN-ONLY de proposito. A versao anterior deste
-- desenho deixava a academia passar o email de qualquer treinador e ficar
-- com os atletas dele -- e portanto com acesso aos passaportes dessas
-- criancas. Uma academia podia reclamar o treinador de uma rival. O
-- self-service correto exige convite-e-aceitacao (academia convida,
-- treinador aceita); fica para a migracao seguinte.
--
-- Testado em dry-run com sessoes reais: academia bloqueada (so_admin),
-- treinador bloqueado (so_admin), admin liga -> 10 atletas + 10 eventos,
-- academia passa a ver 10, desligar reverte e emite eventos de correcao.

alter table public.perfis add column if not exists academia_id uuid
  references public.atletas_360_clubes_subscritores(id) on delete set null;
alter table public.atletas_360 add column if not exists academia_id uuid
  references public.atletas_360_clubes_subscritores(id) on delete set null;
create index if not exists perfis_academia_idx on public.perfis(academia_id) where academia_id is not null;
create index if not exists atletas_360_academia_idx on public.atletas_360(academia_id) where academia_id is not null;

create or replace function public._ytb_minha_academia()
returns uuid language sql stable security definer set search_path=public as $fn$
  select c.id from public.atletas_360_clubes_subscritores c
   where lower(c.responsavel_email)=lower(coalesce(auth.jwt()->>'email','')) limit 1;
$fn$;

create or replace function public.ytb_admin_academia_treinador(p_academia_email text, p_treinador_email text, p_ligar boolean default true)
returns jsonb language plpgsql security definer set search_path=public as $fn$
declare v_ac uuid; v_t text; v_n int:=0; v_nome text;
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','so_admin'); end if;
  select id into v_ac from public.atletas_360_clubes_subscritores
   where lower(responsavel_email)=lower(trim(coalesce(p_academia_email,''))) limit 1;
  if v_ac is null then return jsonb_build_object('ok',false,'motivo','academia_nao_encontrada'); end if;
  v_t := lower(trim(coalesce(p_treinador_email,'')));
  select nome into v_nome from public.perfis where lower(email)=v_t;
  if v_nome is null then return jsonb_build_object('ok',false,'motivo','perfil_nao_encontrado'); end if;
  if p_ligar then
    update public.perfis set academia_id=v_ac where lower(email)=v_t;
    with mudou as (
      update public.atletas_360 a set academia_id=v_ac
       where lower(coalesce(a.treinador_email,''))=v_t and a.academia_id is null
      returning a.id)
    insert into public.atleta_eventos (atleta_id,tipo,titulo,fonte,origem,relevancia,categoria,payload)
    select m.id,'academia_associada','Passou a ser acompanhado por uma academia','academia','sistema',2,'marco',
           jsonb_build_object('academia_id',v_ac,'via_treinador',v_t) from mudou m;
    get diagnostics v_n = row_count;
  else
    update public.perfis set academia_id=null where lower(email)=v_t and academia_id=v_ac;
    with mudou as (
      update public.atletas_360 a set academia_id=null
       where lower(coalesce(a.treinador_email,''))=v_t and a.academia_id=v_ac
      returning a.id)
    insert into public.atleta_eventos (atleta_id,tipo,titulo,fonte,origem,relevancia,categoria,payload)
    select m.id,'academia_dissociada','Deixou de ser acompanhado por esta academia','academia','sistema',2,'marco',
           jsonb_build_object('academia_id',v_ac,'via_treinador',v_t) from mudou m;
    get diagnostics v_n = row_count;
  end if;
  return jsonb_build_object('ok',true,'atletas_afetados',v_n,'perfil',v_nome);
end $fn$;

create or replace function public.ytb_admin_academia_atleta(p_atleta uuid, p_academia_email text, p_ligar boolean default true)
returns jsonb language plpgsql security definer set search_path=public as $fn$
declare v_ac uuid;
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','so_admin'); end if;
  if p_ligar then
    select id into v_ac from public.atletas_360_clubes_subscritores
     where lower(responsavel_email)=lower(trim(coalesce(p_academia_email,''))) limit 1;
    if v_ac is null then return jsonb_build_object('ok',false,'motivo','academia_nao_encontrada'); end if;
  end if;
  update public.atletas_360 set academia_id=v_ac where id=p_atleta;
  if not found then return jsonb_build_object('ok',false,'motivo','atleta_nao_encontrado'); end if;
  insert into public.atleta_eventos (atleta_id,tipo,titulo,fonte,origem,relevancia,categoria,payload)
  values (p_atleta, case when p_ligar then 'academia_associada' else 'academia_dissociada' end,
          case when p_ligar then 'Passou a ser acompanhado por uma academia' else 'Deixou de ser acompanhado por esta academia' end,
          'academia','sistema',2,'marco', jsonb_build_object('academia_id',v_ac,'via','admin'));
  return jsonb_build_object('ok',true);
end $fn$;

create or replace function public._ytb_trig_atleta_herda_academia()
returns trigger language plpgsql security definer set search_path=public as $fn$
declare v_ac uuid;
begin
  if new.academia_id is not null then return new; end if;
  select p.academia_id into v_ac from public.perfis p
   where p.academia_id is not null
     and lower(p.email) in (lower(coalesce(new.treinador_email,'')), lower(coalesce(new.fonte_email,'')))
   limit 1;
  new.academia_id := v_ac;
  return new;
end $fn$;
drop trigger if exists atleta_herda_academia on public.atletas_360;
create trigger atleta_herda_academia before insert on public.atletas_360
for each row execute function public._ytb_trig_atleta_herda_academia();

create or replace function public.ytb_clube_meus_atletas()
returns jsonb language plpgsql security definer set search_path=public as $fn$
declare v_email text; v_ac uuid;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or public._ytb_e_clube()) then return null; end if;
  v_ac := public._ytb_minha_academia();
  return coalesce((
    select jsonb_agg(jsonb_build_object('id',a.id,'nome',a.nome,'ano',a.ano_nascimento,
             'clube',a.clube_actual,'escalao',a.escalao,'posicao',a.posicao_principal,
             'estado',a.estado,'criado_em',a.created_at) order by a.created_at desc)
      from public.atletas_360 a
     where (v_ac is not null and a.academia_id = v_ac)
        or (a.fonte='clube' and lower(coalesce(a.fonte_email,''))=v_email)
  ), '[]'::jsonb);
end $fn$;

revoke all on function public._ytb_minha_academia() from public, anon, authenticated;
revoke all on function public._ytb_trig_atleta_herda_academia() from public, anon, authenticated;
revoke all on function public.ytb_admin_academia_treinador(text,text,boolean) from public, anon;
revoke all on function public.ytb_admin_academia_atleta(uuid,text,boolean) from public, anon;
grant execute on function public.ytb_admin_academia_treinador(text,text,boolean) to authenticated;
grant execute on function public.ytb_admin_academia_atleta(uuid,text,boolean) to authenticated;
