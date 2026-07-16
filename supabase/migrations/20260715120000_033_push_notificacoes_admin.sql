-- ============================================================================
-- MIGRAÇÃO 033 · NOTIFICAÇÕES PUSH NO ADMIN (PWA)
--
-- Pedido do fundador: além do email (migração 032), avançar também com a
-- opção de notificação da app que tinha ficado em aberto — "avança com as
-- pwa com notificações". O admin360 passa a PWA instalável (mesmo padrão de
-- CoachBase/Pro Treinador/Família desta sessão) com Web Push: o fundador
-- ativa uma vez (botão "Ativar notificações"), o browser guarda uma
-- subscrição push, e a mesma _ytb_notificar_admin que já dispara o email
-- passa também a acordar essa subscrição — chega ao telemóvel/desktop mesmo
-- com o browser fechado, sem depender de WhatsApp Business API.
--
-- push_subscriptions: guarda o que o navegador devolve ao subscrever
-- (endpoint + chaves p256dh/auth do protocolo Web Push, RFC8291) — não são
-- segredos de conta, são específicas deste browser/dispositivo e inúteis
-- fora do par de chaves VAPID deste projeto.
-- RLS deny-by-default (como manda a Constituição); só admin escreve, só via
-- RPC security definer; a Edge Function lê com a service role key (já
-- injetada automaticamente pelo runtime da Supabase, não é segredo extra a
-- configurar) — nunca precisa de policy de leitura para o cliente.
--
-- Chave VAPID: gerada localmente (par EC P-256), nunca passou por este chat
-- em texto — só a pública (não é segredo, vai no cliente) foi partilhada. A
-- privada foi escrita direto num ficheiro local para o fundador copiar para
-- os secrets da Edge Function; a Claude nunca a leu nem a insere ela própria
-- (mesma política já aplicada à RESEND_API_KEY na migração 032).
--
-- Validado em dry-run (2026-07-15): RPC grava/atualiza subscrição por admin,
-- bloqueia não-admin; upsert por endpoint não duplica ao reativar a mesma
-- subscrição.
-- ============================================================================

create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  criado_por text,
  criado_em timestamptz not null default now(),
  ultima_falha_em timestamptz
);

alter table public.push_subscriptions enable row level security;
-- deny-by-default: nenhuma policy de select/insert/update/delete para roles de cliente;
-- escrita só via RPC security definer; leitura só pela Edge Function com service role.

create or replace function public.ytb_push_subscrever(p_endpoint text, p_p256dh text, p_auth text)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.ytb_is_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  insert into public.push_subscriptions (endpoint, p256dh, auth, criado_por)
  values (p_endpoint, p_p256dh, p_auth, lower(coalesce(auth.jwt()->>'email','')))
  on conflict (endpoint) do update set p256dh = excluded.p256dh, auth = excluded.auth, ultima_falha_em = null;
  return jsonb_build_object('ok', true);
end $$;

grant execute on function public.ytb_push_subscrever(text,text,text) to authenticated;

create or replace function public.ytb_push_cancelar(p_endpoint text)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.ytb_is_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  delete from public.push_subscriptions where endpoint = p_endpoint;
  return jsonb_build_object('ok', true);
end $$;

grant execute on function public.ytb_push_cancelar(text) to authenticated;
