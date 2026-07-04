-- ============================================================================
-- MIGRAÇÃO 002 · ESCRITAS POR RPC
-- ----------------------------------------------------------------------------
-- O cliente deixa de escrever diretamente em tabelas (Constituição · nunca 6).
-- Este ficheiro cria as RPCs que substituem TODAS as escritas diretas
-- encontradas na auditoria (pro-treinador: 4; admin360: 16 call-sites).
-- Comissões: DESCONTINUADO — nenhuma RPC criada (contradiz a visão aprovada).
-- Passwords de clubes: campo deixa de ser escrito (legado inseguro).
-- ============================================================================

-- ── helpers de papel ─────────────────────────────────────────────────────────
create or replace function public.ytb_is_admin()
returns boolean language sql security definer set search_path = public as $$
  select coalesce(
    lower(coalesce(auth.jwt() ->> 'email','')) in ('ipedronmartins@gmail.com','yourtalentbase@gmail.com')
    or exists (select 1 from public.perfis p
               where lower(p.email)=lower(coalesce(auth.jwt() ->> 'email',''))
                 and p.papel='admin' and coalesce(p.estado,'aprovado')='aprovado'),
    false)
$$;

create or replace function public.ytb_is_treinador()
returns boolean language sql security definer set search_path = public as $$
  select public.ytb_is_admin() or exists (
    select 1 from public.perfis p
    where lower(p.email)=lower(coalesce(auth.jwt() ->> 'email',''))
      and p.papel in ('treinador','scout')
      and coalesce(p.estado,'aprovado')='aprovado')
$$;

-- ════════════════════════ TREINADOR ════════════════════════

-- inscrição de atleta (substitui insert direto em atletas_360)
create or replace function public.ytb_treinador_inscrever(
  p_nome text, p_ano int, p_assoc text, p_pos text,
  p_clube text, p_zz text, p_email_enc text
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_email text;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email',''));
  if not public.ytb_is_treinador() then
    return jsonb_build_object('ok',false,'motivo','sem_papel_treinador');
  end if;
  if coalesce(p_nome,'')='' or p_ano is null then
    return jsonb_build_object('ok',false,'motivo','dados_incompletos');
  end if;
  if p_zz is null or p_zz !~* 'zerozero\.pt/\S' then
    return jsonb_build_object('ok',false,'motivo','zerozero_invalido');
  end if;
  if p_email_enc is null or position('@' in p_email_enc)=0 then
    return jsonb_build_object('ok',false,'motivo','email_encarregado_invalido');
  end if;

  insert into public.atletas_360
    (nome, primeiro_nome, ano_nascimento, escalao, associacao,
     posicao_principal, clube_actual, zerozero_url,
     estado, visivel_b2b, fonte, fonte_nome, fonte_email, encarregado_email)
  values
    (p_nome, split_part(p_nome,' ',1), p_ano,
     'Sub-'||(date_part('year', now())::int - p_ano),
     p_assoc,
     case when p_pos in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then p_pos else null end,
     p_clube, p_zz,
     'pendente', false, 'treinador',
     coalesce((select nome from public.perfis where lower(email)=v_email), v_email),
     v_email, lower(trim(p_email_enc)))
  returning id into v_id;
  -- evento 'inscricao' emitido pelo trigger da tabela (ciclo1)
  return jsonb_build_object('ok',true,'id',v_id);
end $$;

-- avaliação + prescrição + rating, numa transação (substitui 3 escritas diretas)
create or replace function public.ytb_treinador_avaliar(
  p_atleta uuid, p_criterios jsonb, p_debilidades jsonb, p_plano jsonb
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_av uuid; v_media numeric; v_nota text;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email',''));
  if not public.ytb_is_treinador() then
    return jsonb_build_object('ok',false,'motivo','sem_papel_treinador');
  end if;
  if not exists (select 1 from public.atletas_360 where id=p_atleta) then
    return jsonb_build_object('ok',false,'motivo','atleta_inexistente');
  end if;

  insert into public.treinador_avaliacoes (atleta_id, treinador_id, treinador_email, criterios, debilidades)
  values (p_atleta, nullif(auth.jwt() ->> 'sub','')::uuid, v_email, p_criterios, p_debilidades)
  returning id into v_av;

  if p_plano is not null then
    insert into public.treinador_treinos (atleta_id, treinador_id, avaliacao_id, plano, fonte)
    values (p_atleta, nullif(auth.jwt() ->> 'sub','')::uuid, v_av, p_plano, 'avaliacao');
  end if;

  -- nota calculada NO SERVIDOR a partir dos critérios (não se confia no cliente)
  select avg(v.val) into v_media
  from (select public.ytb_num(value) as val from jsonb_each_text(coalesce(p_criterios,'{}'::jsonb))) v
  where v.val is not null;
  if v_media is not null then
    v_nota := case when v_media>=4.7 then 'A+' when v_media>=4.3 then 'A'
                   when v_media>=3.8 then 'B+' when v_media>=3.3 then 'B'
                   when v_media>=2.8 then 'C+' when v_media>=2.3 then 'C' else 'D' end;
    update public.atletas_360
       set rating_geral = v_nota, stats_actualizadas_em = now()
     where id = p_atleta;
  end if;
  -- eventos 'avaliacao_treinador' e 'treino_prescrito' emitidos pelos triggers
  return jsonb_build_object('ok',true,'avaliacao_id',v_av,'nota',v_nota);
end $$;

-- ════════════════════════ ADMIN ════════════════════════

create or replace function public.ytb_admin_atleta_estado(p_id uuid, p_acao text, p_motivo text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  if p_acao = 'aprovar' then
    -- v2: aprovar decide o ESTADO; a exposição (b2b/montra) é decisão da FAMÍLIA
    update public.atletas_360
       set estado='aprovado', aprovado_por='Admin YTB', aprovado_em=now(), estado_motivo=null
     where id=p_id;
  elsif p_acao = 'rejeitar' then
    update public.atletas_360
       set estado='rejeitado', estado_motivo=p_motivo, visivel_b2b=false, visivel_publico=false
     where id=p_id;
  else
    return jsonb_build_object('ok',false,'motivo','acao_invalida');
  end if;
  insert into public.atleta_eventos (atleta_id,tipo,categoria,titulo,fonte,origem,relevancia,payload)
  values (p_id,'estado_admin','marco',
          case when p_acao='aprovar' then 'Atleta aprovado' else 'Atleta rejeitado' end,
          'admin','sistema',2, jsonb_build_object('acao',p_acao,'motivo',p_motivo));
  return jsonb_build_object('ok',true);
end $$;

-- edição de campos (whitelist explícita; visibilidades só podem DESLIGAR-se aqui)
create or replace function public.ytb_admin_atleta_guardar(p_id uuid, p jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  update public.atletas_360 set
    nome                 = case when p ? 'nome' then p->>'nome' else nome end,
    primeiro_nome        = case when p ? 'nome' then split_part(p->>'nome',' ',1) else primeiro_nome end,
    ano_nascimento       = case when p ? 'ano_nascimento' then (public.ytb_num(p->>'ano_nascimento'))::int else ano_nascimento end,
    posicao_principal    = case when p ? 'posicao_principal' then p->>'posicao_principal' else posicao_principal end,
    clube_actual         = case when p ? 'clube_actual' then p->>'clube_actual' else clube_actual end,
    equipa               = case when p ? 'equipa' then p->>'equipa' else equipa end,
    escalao              = case when p ? 'escalao' then p->>'escalao' else escalao end,
    associacao           = case when p ? 'associacao' then p->>'associacao' else associacao end,
    zerozero_url         = case when p ? 'zerozero_url' then p->>'zerozero_url' else zerozero_url end,
    joga_plus_url        = case when p ? 'joga_plus_url' then p->>'joga_plus_url' else joga_plus_url end,
    rating_geral         = case when p ? 'rating_geral' then p->>'rating_geral' else rating_geral end,
    badge_estado         = case when p ? 'badge_estado' then p->>'badge_estado' else badge_estado end,
    area_excelencia_1    = case when p ? 'area_excelencia_1' then p->>'area_excelencia_1' else area_excelencia_1 end,
    area_excelencia_2    = case when p ? 'area_excelencia_2' then p->>'area_excelencia_2' else area_excelencia_2 end,
    area_excelencia_3    = case when p ? 'area_excelencia_3' then p->>'area_excelencia_3' else area_excelencia_3 end,
    encarregado_nome     = case when p ? 'encarregado_nome' then p->>'encarregado_nome' else encarregado_nome end,
    encarregado_telefone = case when p ? 'encarregado_telefone' then p->>'encarregado_telefone' else encarregado_telefone end,
    epoca_ref            = case when p ? 'epoca_ref' then p->>'epoca_ref' else epoca_ref end,
    divisao              = case when p ? 'divisao' then p->>'divisao' else divisao end,
    golos_epoca          = case when p ? 'golos_epoca' then (public.ytb_num(p->>'golos_epoca'))::int else golos_epoca end,
    jogos_epoca          = case when p ? 'jogos_epoca' then (public.ytb_num(p->>'jogos_epoca'))::int else jogos_epoca end,
    assist_epoca         = case when p ? 'assist_epoca' then (public.ytb_num(p->>'assist_epoca'))::int else assist_epoca end,
    golos_equipa_epoca   = case when p ? 'golos_equipa_epoca' then (public.ytb_num(p->>'golos_equipa_epoca'))::int else golos_equipa_epoca end,
    classificacao_equipa = case when p ? 'classificacao_equipa' then p->>'classificacao_equipa' else classificacao_equipa end,
    estado               = case when p ? 'estado' and (p->>'estado') in ('pendente','aprovado','rejeitado') then p->>'estado' else estado end,
    visivel_b2b          = case when p ? 'visivel_b2b' and (p->>'visivel_b2b')='false' then false else visivel_b2b end,
    visivel_publico      = case when p ? 'visivel_publico' and (p->>'visivel_publico')='false' then false else visivel_publico end,
    notas_admin          = case when p ? 'notas_admin' then p->>'notas_admin' else notas_admin end
  where id = p_id;
  insert into public.atleta_eventos (atleta_id,tipo,categoria,titulo,fonte,origem,relevancia,payload)
  values (p_id,'atualizacao_admin','marco','Ficha atualizada pelo admin','admin','sistema',1,
          jsonb_build_object('campos', (select jsonb_agg(k) from jsonb_object_keys(p) k)));
  return jsonb_build_object('ok',true);
end $$;

-- apagamento RGPD: remoção completa em cascata, com contagens devolvidas
create or replace function public.ytb_admin_atleta_apagar(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare n_ev int; n_av int; n_tr int; n_ft int;
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  select count(*) into n_ev from public.atleta_eventos where atleta_id=p_id;
  select count(*) into n_av from public.treinador_avaliacoes where atleta_id=p_id;
  select count(*) into n_tr from public.treinador_treinos where atleta_id=p_id;
  select count(*) into n_ft from public.familia_treinos where atleta_id=p_id;
  delete from public.atletas_360 where id=p_id;  -- FKs on delete cascade limpam o resto
  return jsonb_build_object('ok',true,'eventos',n_ev,'avaliacoes',n_av,'planos',n_tr,'treinos_familia',n_ft);
end $$;

create or replace function public.ytb_admin_whatsapp(p_id uuid, p_enviado boolean)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  update public.atletas_360
     set whatsapp_enviado=p_enviado,
         whatsapp_enviado_em = case when p_enviado then now() else null end,
         whatsapp_enviado_por = case when p_enviado then 'Admin YTB' else null end
   where id=p_id;
  return jsonb_build_object('ok',true);
end $$;

create or replace function public.ytb_admin_registo_decidir(p_id uuid, p_acao text, p_papel text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_nome text; v_email text; v_linhas int;
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  if p_acao = 'contactado' then
    update public.registos_pendentes set estado='contactado' where id=p_id;
  elsif p_acao = 'rejeitado' then
    update public.registos_pendentes set estado='rejeitado' where id=p_id;
  elsif p_acao = 'aprovado' then
    select nome, email into v_nome, v_email from public.registos_pendentes where id=p_id;
    if v_email is null then return jsonb_build_object('ok',false,'motivo','registo_inexistente'); end if;
    update public.registos_pendentes set estado='aprovado' where id=p_id;
    -- perfis.id é FK obrigatória para auth.users (nasce sozinho no 1º login, via trigger
    -- on_auth_user_created -> criar_perfil_no_signup). Nunca inserimos aqui: só há linha
    -- para atualizar se a pessoa já entrou pelo menos uma vez.
    update public.perfis set papel=coalesce(p_papel,'treinador'), estado='aprovado'
      where lower(email)=lower(v_email);
    get diagnostics v_linhas = row_count;
    return jsonb_build_object('ok',true, 'perfil_ja_existia', v_linhas>0,
      'aviso', case when v_linhas=0
        then 'Aprovado. A pessoa ainda não entrou pela 1ª vez — o papel aplica-se automaticamente quando ela entrar pelo link mágico.'
        else null end);
  else
    return jsonb_build_object('ok',false,'motivo','acao_invalida');
  end if;
  return jsonb_build_object('ok',true);
end $$;

create or replace function public.ytb_admin_pedido_contacto(p_id uuid, p_estado text, p_notificado boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  if p_notificado then
    update public.atletas_360_pedidos_contacto
       set estado='encarregado_notificado', whatsapp_enviado_em=now() where id=p_id;
  else
    update public.atletas_360_pedidos_contacto
       set estado=p_estado, resolvido_em=now(), resposta_em=now() where id=p_id;
  end if;
  return jsonb_build_object('ok',true);
end $$;

-- registo de clube interessado — SEM password (acesso real: ytb_definir_papel + magic link)
create or replace function public.ytb_admin_clube_registar(
  p_nome text, p_resp text, p_email text, p_tel text default null,
  p_cargo text default null, p_plano text default null, p_valor numeric default null,
  p_notas text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  insert into public.atletas_360_clubes_subscritores
    (clube_nome, responsavel_nome, responsavel_email, responsavel_telefone, responsavel_cargo,
     plano, valor_mensal, subscrito_em, estado_subscricao, notas_admin)
  values (p_nome, p_resp, lower(p_email), p_tel, p_cargo, p_plano, p_valor, now(), 'ativa', p_notas)
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;

create or replace function public.ytb_admin_clube_remover(p_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  delete from public.atletas_360_clubes_subscritores where id=p_id;
  return jsonb_build_object('ok',true);
end $$;

create or replace function public.ytb_admin_aval_contextual(p_atleta uuid, p_texto text, p_snapshot jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  insert into public.avaliacoes_contextuais (atleta_id, texto_ia, snapshot, gerado_por, modelo)
  values (p_atleta, p_texto, p_snapshot, lower(coalesce(auth.jwt() ->> 'email','admin')), 'claude')
  returning id into v_id;
  -- evento emitido pelo trigger da tabela
  return jsonb_build_object('ok',true,'id',v_id);
end $$;

create or replace function public.ytb_admin_perfil_estado(p_email text, p_estado text)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  update public.perfis set estado=p_estado where lower(email)=lower(p_email);
  return jsonb_build_object('ok',true);
end $$;

grant execute on function public.ytb_is_admin()                                         to authenticated;
grant execute on function public.ytb_is_treinador()                                     to authenticated;
grant execute on function public.ytb_treinador_inscrever(text,int,text,text,text,text,text) to authenticated;
grant execute on function public.ytb_treinador_avaliar(uuid,jsonb,jsonb,jsonb)          to authenticated;
grant execute on function public.ytb_admin_atleta_estado(uuid,text,text)                to authenticated;
grant execute on function public.ytb_admin_atleta_guardar(uuid,jsonb)                   to authenticated;
grant execute on function public.ytb_admin_atleta_apagar(uuid)                          to authenticated;
grant execute on function public.ytb_admin_whatsapp(uuid,boolean)                       to authenticated;
grant execute on function public.ytb_admin_registo_decidir(uuid,text,text)              to authenticated;
grant execute on function public.ytb_admin_pedido_contacto(uuid,text,boolean)           to authenticated;
grant execute on function public.ytb_admin_clube_registar(text,text,text,text,text,text,numeric,text) to authenticated;
grant execute on function public.ytb_admin_clube_remover(uuid)                          to authenticated;
grant execute on function public.ytb_admin_aval_contextual(uuid,text,jsonb)             to authenticated;
grant execute on function public.ytb_admin_perfil_estado(text,text)                     to authenticated;
