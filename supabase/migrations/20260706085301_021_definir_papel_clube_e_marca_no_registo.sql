-- ============================================================================
-- MIGRAÇÃO 021 · M3 ACADEMIA — LIGAR A NAVEGAÇÃO REAL DA CONTA DE CLUBE
-- Duas correções na gestão de contas do admin (Contas → mudar papel;
-- Clubes → criar clube subscritor), necessárias para o admin conseguir
-- aprovar e configurar a conta da Golden Football Academy (piloto):
--
-- 1) ytb_definir_papel — a lista de papéis válidos não incluía 'clube'
--    (já era um valor aceite pelo schema desde a base, só não estava na
--    lista desta RPC). Aproveitado para corrigir um bug lateral encontrado
--    no dry-run: o ramo que cria um perfil novo (para um email ainda sem
--    linha em perfis) inseria sem 'id', e perfis.id é FK obrigatória a
--    auth.users — rebentava com erro de base de dados em vez de uma
--    mensagem clara. Nunca disparava pela UI (a lista de Contas só mostra
--    quem já tem perfil), mas era alcançável pela RPC direta. Agora procura
--    o id em auth.users pelo email; se a pessoa nunca fez login nenhuma
--    vez, devolve um motivo claro em vez de rebentar.
--
-- 2) ytb_admin_clube_registar — ganha p_logo_url/p_cor opcionais, para o
--    admin poder já configurar a marca própria (migração 020) no momento
--    em que cria o registo do clube, sem precisar de um segundo passo.
--
-- Validado em dry-run (2026-07-06): clube com marca registado com sucesso;
-- cor inválida bloqueada; papel 'clube' atribuído com sucesso a conta já
-- existente; conta nunca autenticada devolve erro claro (não rebenta);
-- não-admin bloqueado nas duas RPCs.
-- ============================================================================

create or replace function public.ytb_definir_papel(p_email text, p_papel text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_admin text; v_alvo text; v_papel text; v_uid uuid;
begin
  v_admin := auth.jwt() ->> 'email';
  if not exists (select 1 from public.perfis where lower(email) = lower(v_admin) and papel = 'admin') then
    return jsonb_build_object('status','negado','motivo','só o admin pode atribuir papéis');
  end if;

  v_papel := lower(trim(coalesce(p_papel,'')));
  if v_papel not in ('scout','treinador','familia','admin','clube') then
    return jsonb_build_object('status','erro','motivo','papel inválido (scout/treinador/familia/admin/clube)');
  end if;

  v_alvo := lower(trim(coalesce(p_email,'')));
  if v_alvo = '' or position('@' in v_alvo) = 0 then
    return jsonb_build_object('status','erro','motivo','email inválido');
  end if;

  if exists (select 1 from public.perfis where lower(email) = v_alvo) then
    update public.perfis set papel = v_papel where lower(email) = v_alvo;
  else
    select id into v_uid from auth.users where lower(email) = v_alvo limit 1;
    if v_uid is null then
      return jsonb_build_object('status','erro','motivo','esta conta ainda não entrou nenhuma vez — pede para entrar primeiro, depois atribui o papel');
    end if;
    insert into public.perfis(id, email, papel, estado) values (v_uid, v_alvo, v_papel, 'aprovado');
  end if;

  return jsonb_build_object('status','ok','email',v_alvo,'papel',v_papel);
end $$;

drop function if exists public.ytb_admin_clube_registar(text,text,text,text,text,text,numeric,text);

create or replace function public.ytb_admin_clube_registar(p_nome text, p_resp text, p_email text, p_tel text default null, p_cargo text default null, p_plano text default null, p_valor numeric default null, p_notas text default null, p_logo_url text default null, p_cor text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  if p_logo_url is not null and trim(p_logo_url) <> '' and p_logo_url !~* '^https?://' then
    return jsonb_build_object('ok',false,'motivo','logo_url_invalido');
  end if;
  if p_cor is not null and trim(p_cor) <> '' and p_cor !~ '^#[0-9A-Fa-f]{6}$' then
    return jsonb_build_object('ok',false,'motivo','cor_invalida');
  end if;
  insert into public.atletas_360_clubes_subscritores
    (clube_nome, responsavel_nome, responsavel_email, responsavel_telefone, responsavel_cargo,
     plano, valor_mensal, subscrito_em, estado_subscricao, notas_admin, logo_url, cor_primaria)
  values (p_nome, p_resp, lower(p_email), p_tel, p_cargo, p_plano, p_valor, now(), 'ativa', p_notas,
     nullif(trim(coalesce(p_logo_url,'')),''), nullif(trim(coalesce(p_cor,'')),''))
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;

grant execute on function public.ytb_admin_clube_registar(text,text,text,text,text,text,numeric,text,text,text) to authenticated;
