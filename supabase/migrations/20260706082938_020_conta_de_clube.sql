-- ============================================================================
-- MIGRAÇÃO 020 · M3 ACADEMIA — CONTA DE ORGANIZAÇÃO (CLUBE/ACADEMIA)
-- Reaproveita ao máximo o padrão do scout (migração 018): login próprio,
-- cria/gere só os seus atletas, nunca apaga (só arquiva), passaporte nasce
-- na criação. Uma conta = um login (perfis.papel='clube', já permitido pelo
-- schema desde a base). Novidades específicas do clube:
--  - clube_actual é SEMPRE o nome da própria organização (não é pedido ao
--    clube, vem de atletas_360_clubes_subscritores.responsavel_email);
--  - inscrição em lote (ytb_clube_atletas_lote) para registos em bloco
--    (ex.: campos de férias) — nunca cria duplicados em silêncio, mesma
--    regra do scout, mas sem UI de escolha por linha: marca 'duplicado_possivel'
--    e não cria, para o clube decidir individualmente depois;
--  - marca própria (logo_url + cor_primaria) em atletas_360_clubes_subscritores,
--    self-service via ytb_clube_atualizar_marca.
-- A ligação entre o login (perfis) e a identidade da organização (nome,
-- marca, plano) é feita por email (responsavel_email = perfis.email) — os
-- dois já existiam como conceitos separados; esta migração não junta as
-- tabelas, só faz a ponte.
-- Piloto: Golden Football Academy (Gondomar) — escolinha de futebol/campos
-- de férias, primeira organização real a usar isto.
-- Validado em dry-run (2026-07-06, 12 asserções): conta sem organização
-- associada é bloqueada; marca própria persiste; posição continua
-- obrigatória; clube_actual auto-preenchido com o nome da organização;
-- isolamento total entre clubes (um não vê nem abre o passaporte dos
-- atletas do outro); lote cria válidos, reporta erros por linha e nunca
-- duplica em silêncio; intruso sem papel 'clube' bloqueado em tudo.
-- ============================================================================

alter table public.atletas_360 drop constraint atletas_360_fonte_check;
alter table public.atletas_360 add constraint atletas_360_fonte_check
  check (fonte is null or fonte = any (array['pai','atleta','scout','treinador','admin','auto','clube']));

alter table public.atletas_360_clubes_subscritores add column if not exists logo_url text;
alter table public.atletas_360_clubes_subscritores add column if not exists cor_primaria text
  check (cor_primaria is null or cor_primaria ~ '^#[0-9A-Fa-f]{6}$');

create or replace function public._ytb_e_clube()
returns boolean language sql security definer set search_path = public as $$
  select exists (
    select 1 from public.perfis p
     where lower(p.email) = lower(coalesce(auth.jwt()->>'email',''))
       and p.papel = 'clube' and coalesce(p.estado,'aprovado') = 'aprovado')
$$;

create or replace function public._ytb_clube_conta(v_email text)
returns public.atletas_360_clubes_subscritores language sql security definer set search_path = public as $$
  select * from public.atletas_360_clubes_subscritores where lower(responsavel_email) = v_email limit 1
$$;

create or replace function public.ytb_clube_minha_conta()
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; c public.atletas_360_clubes_subscritores;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_clube() then return null; end if;
  c := public._ytb_clube_conta(v_email);
  if c.id is null then return jsonb_build_object('ok',false,'motivo','sem_conta_associada'); end if;
  return jsonb_build_object('ok',true,'id',c.id,'nome',c.clube_nome,'logo_url',c.logo_url,
    'cor_primaria',c.cor_primaria,'plano',c.plano,'estado_subscricao',c.estado_subscricao);
end $$;

create or replace function public.ytb_clube_atualizar_marca(p_logo_url text, p_cor text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public._ytb_e_clube() then return jsonb_build_object('ok',false,'motivo','sem_papel_clube'); end if;
  if p_logo_url is not null and trim(p_logo_url) <> '' and p_logo_url !~* '^https?://' then
    return jsonb_build_object('ok',false,'motivo','logo_url_invalido');
  end if;
  if p_cor is not null and trim(p_cor) <> '' and p_cor !~ '^#[0-9A-Fa-f]{6}$' then
    return jsonb_build_object('ok',false,'motivo','cor_invalida');
  end if;
  update public.atletas_360_clubes_subscritores
     set logo_url = nullif(trim(coalesce(p_logo_url,'')),''),
         cor_primaria = nullif(trim(coalesce(p_cor,'')),''),
         updated_at = now()
   where lower(responsavel_email) = v_email;
  if not found then return jsonb_build_object('ok',false,'motivo','sem_conta_associada'); end if;
  return jsonb_build_object('ok',true);
end $$;

create or replace function public.ytb_clube_atleta_criar(
  p_nome text, p_ano int, p_mes int default null, p_dia int default null,
  p_sexo text default null, p_nacionalidade text default null,
  p_escalao text default null, p_pos text default null, p_pe text default null,
  p_assoc text default null, p_esquema text default null,
  p_altura numeric default null, p_peso numeric default null,
  p_zz text default null, p_video text default null, p_email_enc text default null,
  p_confirmar_novo boolean default false, p_associar_a uuid default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_clube public.atletas_360_clubes_subscritores; v_id uuid; v_cand jsonb;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or public._ytb_e_clube()) then
    return jsonb_build_object('ok',false,'motivo','sem_papel_clube');
  end if;
  v_clube := public._ytb_clube_conta(v_email);
  if v_clube.id is null and not public.ytb_is_admin() then
    return jsonb_build_object('ok',false,'motivo','sem_conta_associada');
  end if;
  if coalesce(trim(p_nome),'') = '' then return jsonb_build_object('ok',false,'motivo','nome'); end if;
  if p_ano is null or p_ano < 1990 or p_ano > extract(year from now())::int then
    return jsonb_build_object('ok',false,'motivo','ano_invalido');
  end if;
  if p_pos is null or p_pos not in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then
    return jsonb_build_object('ok',false,'motivo','posicao_obrigatoria');
  end if;
  if p_dia is not null and p_dia not between 1 and 31 then return jsonb_build_object('ok',false,'motivo','dia_invalido'); end if;
  if p_mes is not null and p_mes not between 1 and 12 then return jsonb_build_object('ok',false,'motivo','mes_invalido'); end if;
  if p_sexo is not null and p_sexo not in ('M','F') then return jsonb_build_object('ok',false,'motivo','sexo_invalido'); end if;
  if p_zz is not null and trim(p_zz) <> '' and p_zz !~* 'zerozero\.pt/\S' then return jsonb_build_object('ok',false,'motivo','zerozero_invalido'); end if;
  if p_email_enc is not null and trim(p_email_enc) <> '' and position('@' in p_email_enc) = 0 then
    return jsonb_build_object('ok',false,'motivo','email_encarregado_invalido');
  end if;
  if p_altura is not null and p_altura not between 80 and 220 then return jsonb_build_object('ok',false,'motivo','altura_invalida'); end if;
  if p_peso is not null and p_peso not between 15 and 120 then return jsonb_build_object('ok',false,'motivo','peso_invalido'); end if;

  if p_associar_a is not null then
    if not exists (select 1 from public.atletas_360 where id = p_associar_a) then
      return jsonb_build_object('ok',false,'motivo','atleta_inexistente');
    end if;
    return jsonb_build_object('ok',true,'id',p_associar_a,'associado',true);
  end if;

  if not p_confirmar_novo then
    select jsonb_agg(jsonb_build_object('id',a.id,'nome',a.nome,'ano',a.ano_nascimento,'clube',a.clube_actual))
      into v_cand
      from (select * from public.atletas_360
             where (nome ilike '%'||trim(p_nome)||'%' or trim(p_nome) ilike '%'||nome||'%')
               and (ano_nascimento is null or ano_nascimento = p_ano)
               and coalesce(estado,'') <> 'arquivado'
             limit 5) a;
    if v_cand is not null then
      return jsonb_build_object('ok',false,'motivo','duplicado_possivel','candidatos',v_cand);
    end if;
  end if;

  insert into public.atletas_360
    (nome, primeiro_nome, ano_nascimento, mes_nascimento, dia_nascimento,
     sexo, nacionalidade, escalao, associacao, posicao_principal, pe_dominante,
     clube_actual, zerozero_url, video_path, esquema_tatico,
     estado, visivel_b2b, visivel_publico,
     fonte, fonte_nome, fonte_email, encarregado_email)
  values
    (trim(p_nome), split_part(trim(p_nome),' ',1), p_ano, p_mes, p_dia,
     p_sexo, nullif(trim(p_nacionalidade),''),
     public._ytb_escalao_de(p_escalao, p_ano),
     coalesce(nullif(trim(p_assoc),''), 'Não filiado'),
     p_pos, public._ytb_pe_norm(p_pe),
     coalesce(v_clube.clube_nome, 'Clube'), nullif(trim(p_zz),''), nullif(trim(p_video),''),
     nullif(trim(p_esquema),''),
     'aprovado', false, false,
     'clube', coalesce(v_clube.clube_nome, v_email), v_email,
     lower(nullif(trim(p_email_enc),'')))
  returning id into v_id;

  if p_altura is not null or p_peso is not null then
    insert into public.atleta_biometria (atleta_id, altura_cm, peso_kg, fonte)
    values (v_id, p_altura, p_peso, 'clube');
    update public.atletas_360
       set altura_cm = coalesce(p_altura::int, altura_cm),
           peso_kg   = coalesce(p_peso::int,  peso_kg)
     where id = v_id;
  end if;

  return jsonb_build_object('ok',true,'id',v_id);
end $$;

create or replace function public.ytb_clube_meus_atletas()
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or public._ytb_e_clube()) then return null; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id',a.id,'nome',a.nome,'ano',a.ano_nascimento,
             'clube',a.clube_actual,'escalao',a.escalao,'posicao',a.posicao_principal,
             'estado',a.estado,'criado_em',a.created_at)
           order by a.created_at desc)
      from public.atletas_360 a
     where a.fonte = 'clube' and lower(coalesce(a.fonte_email,'')) = v_email
  ), '[]'::jsonb);
end $$;

create or replace function public.ytb_clube_atleta_editar(p_id uuid, p jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or public._ytb_e_clube()) then
    return jsonb_build_object('ok',false,'motivo','sem_papel_clube');
  end if;
  if not exists (select 1 from public.atletas_360 a
                  where a.id = p_id
                    and (public.ytb_is_admin()
                         or (a.fonte = 'clube' and lower(coalesce(a.fonte_email,'')) = v_email))) then
    return jsonb_build_object('ok',false,'motivo','nao_autorizado');
  end if;

  update public.atletas_360 set
    nome              = case when p ? 'nome' and coalesce(trim(p->>'nome'),'') <> '' then p->>'nome' else nome end,
    primeiro_nome     = case when p ? 'nome' and coalesce(trim(p->>'nome'),'') <> '' then split_part(p->>'nome',' ',1) else primeiro_nome end,
    ano_nascimento    = case when p ? 'ano_nascimento' and public.ytb_num(p->>'ano_nascimento') is not null then (public.ytb_num(p->>'ano_nascimento'))::int else ano_nascimento end,
    mes_nascimento    = case when p ? 'mes_nascimento' then (public.ytb_num(p->>'mes_nascimento'))::int else mes_nascimento end,
    dia_nascimento    = case when p ? 'dia_nascimento' then (public.ytb_num(p->>'dia_nascimento'))::int else dia_nascimento end,
    sexo              = case when p ? 'sexo' and (p->>'sexo') in ('M','F') then p->>'sexo' else sexo end,
    nacionalidade     = case when p ? 'nacionalidade' then p->>'nacionalidade' else nacionalidade end,
    posicao_principal = case when p ? 'posicao_principal' and (p->>'posicao_principal') in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then p->>'posicao_principal' else posicao_principal end,
    pe_dominante      = case when p ? 'pe_dominante' and public._ytb_pe_norm(p->>'pe_dominante') is not null then public._ytb_pe_norm(p->>'pe_dominante') else pe_dominante end,
    equipa            = case when p ? 'equipa' then p->>'equipa' else equipa end,
    escalao           = case when p ? 'escalao' and coalesce(trim(p->>'escalao'),'') <> '' then p->>'escalao' else escalao end,
    associacao        = case when p ? 'associacao' and coalesce(trim(p->>'associacao'),'') <> '' then p->>'associacao' else associacao end,
    esquema_tatico    = case when p ? 'esquema_tatico' then p->>'esquema_tatico' else esquema_tatico end,
    zerozero_url      = case when p ? 'zerozero_url' then p->>'zerozero_url' else zerozero_url end,
    video_path        = case when p ? 'video_path' then p->>'video_path' else video_path end,
    encarregado_email = case when p ? 'encarregado_email' then lower(nullif(trim(p->>'encarregado_email'),'')) else encarregado_email end
  where id = p_id;

  insert into public.atleta_eventos (atleta_id, tipo, titulo, fonte, origem, relevancia, payload)
  values (p_id, 'atualizacao_clube', 'Ficha atualizada pelo clube', v_email, 'sistema', 1,
          jsonb_build_object('campos', (select jsonb_agg(k) from jsonb_object_keys(p) k)));
  return jsonb_build_object('ok',true);
end $$;

create or replace function public.ytb_clube_atleta_arquivar(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or public._ytb_e_clube()) then
    return jsonb_build_object('ok',false,'motivo','sem_papel_clube');
  end if;
  if not exists (select 1 from public.atletas_360 a
                  where a.id = p_id
                    and (public.ytb_is_admin()
                         or (a.fonte = 'clube' and lower(coalesce(a.fonte_email,'')) = v_email))) then
    return jsonb_build_object('ok',false,'motivo','nao_autorizado');
  end if;
  update public.atletas_360
     set estado = 'arquivado', visivel_b2b = false, visivel_publico = false
   where id = p_id;
  insert into public.atleta_eventos (atleta_id, tipo, titulo, fonte, origem, relevancia)
  values (p_id, 'estado_clube', 'Atleta arquivado pelo clube', v_email, 'sistema', 1);
  return jsonb_build_object('ok',true);
end $$;

create or replace function public.ytb_passaporte_clube(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if public.ytb_is_admin() then
    return public._ytb_passaporte_json(p_atleta);
  end if;
  if not public._ytb_e_clube() then return null; end if;
  if not exists (select 1 from public.atletas_360 a
                  where a.id = p_atleta and a.fonte = 'clube'
                    and lower(coalesce(a.fonte_email,'')) = v_email) then
    return null;
  end if;
  return public._ytb_passaporte_json(p_atleta);
end $$;

create or replace function public.ytb_clube_atletas_lote(p_lista jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_email text; v_clube public.atletas_360_clubes_subscritores;
  v_item jsonb; v_id uuid; v_dup jsonb; v_resultados jsonb := '[]'::jsonb;
  v_nome text; v_ano int; v_pos text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or public._ytb_e_clube()) then
    return jsonb_build_object('ok',false,'motivo','sem_papel_clube');
  end if;
  v_clube := public._ytb_clube_conta(v_email);
  if v_clube.id is null and not public.ytb_is_admin() then
    return jsonb_build_object('ok',false,'motivo','sem_conta_associada');
  end if;
  if jsonb_typeof(p_lista) <> 'array' then
    return jsonb_build_object('ok',false,'motivo','lista_invalida');
  end if;

  for v_item in select * from jsonb_array_elements(p_lista) loop
    v_nome := trim(coalesce(v_item->>'nome',''));
    v_ano  := public.ytb_num(v_item->>'ano');
    v_pos  := v_item->>'pos';
    v_id := null; v_dup := null;

    if v_nome = '' then
      v_resultados := v_resultados || jsonb_build_object('nome', coalesce(v_item->>'nome','—'), 'status','erro','motivo','nome');
    elsif v_ano is null or v_ano < 1990 or v_ano > extract(year from now())::int then
      v_resultados := v_resultados || jsonb_build_object('nome', v_nome, 'status','erro','motivo','ano_invalido');
    elsif v_pos is null or v_pos not in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then
      v_resultados := v_resultados || jsonb_build_object('nome', v_nome, 'status','erro','motivo','posicao_obrigatoria');
    else
      select jsonb_agg(jsonb_build_object('id',a.id,'nome',a.nome,'ano',a.ano_nascimento))
        into v_dup
        from (select * from public.atletas_360
               where (nome ilike '%'||v_nome||'%' or v_nome ilike '%'||nome||'%')
                 and (ano_nascimento is null or ano_nascimento = v_ano)
                 and coalesce(estado,'') <> 'arquivado'
               limit 3) a;
      if v_dup is not null then
        v_resultados := v_resultados || jsonb_build_object('nome', v_nome, 'status','duplicado_possivel', 'candidatos', v_dup);
      else
        insert into public.atletas_360
          (nome, primeiro_nome, ano_nascimento, mes_nascimento, dia_nascimento,
           sexo, escalao, associacao, posicao_principal, pe_dominante, clube_actual,
           estado, visivel_b2b, visivel_publico, fonte, fonte_nome, fonte_email)
        values
          (v_nome, split_part(v_nome,' ',1), v_ano,
           public.ytb_num(v_item->>'mes'), public.ytb_num(v_item->>'dia'),
           nullif(v_item->>'sexo',''),
           public._ytb_escalao_de(v_item->>'escalao', v_ano),
           coalesce(nullif(trim(v_item->>'assoc'),''), 'Não filiado'),
           v_pos, public._ytb_pe_norm(v_item->>'pe'),
           coalesce(v_clube.clube_nome, 'Clube'),
           'aprovado', false, false, 'clube', coalesce(v_clube.clube_nome, v_email), v_email)
        returning id into v_id;
        v_resultados := v_resultados || jsonb_build_object('nome', v_nome, 'status','criado', 'id', v_id);
      end if;
    end if;
  end loop;

  return jsonb_build_object('ok',true,'resultados',v_resultados);
end $$;

grant execute on function public.ytb_clube_minha_conta() to authenticated;
grant execute on function public.ytb_clube_atualizar_marca(text,text) to authenticated;
grant execute on function public.ytb_clube_atleta_criar(text,int,int,int,text,text,text,text,text,text,text,numeric,numeric,text,text,text,boolean,uuid) to authenticated;
grant execute on function public.ytb_clube_meus_atletas() to authenticated;
grant execute on function public.ytb_clube_atleta_editar(uuid,jsonb) to authenticated;
grant execute on function public.ytb_clube_atleta_arquivar(uuid) to authenticated;
grant execute on function public.ytb_passaporte_clube(uuid) to authenticated;
grant execute on function public.ytb_clube_atletas_lote(jsonb) to authenticated;
revoke execute on function public._ytb_clube_conta(text) from public, anon, authenticated;
