-- ============================================================================
-- MIGRAÇÃO 032 · AVISAR O ADMIN POR EMAIL A CADA PENDENTE NOVO
--
-- Pedido do fundador: "por cada inscrição, consigo receber aviso por email ou
-- whatsapp? para estar sempre a par". Decisão dele (2026-07-15, entre as 3
-- opções apresentadas: email / notificação da app / WhatsApp automático):
-- email, a enviar para geral@yourtalentbase.pt (o email trocado recentemente).
-- WhatsApp automático ficou de fora — exigiria WhatsApp Business API (só para
-- avisar uma pessoa não compensa o custo/complexidade); os links wa.me já
-- existentes no site são "clicar para conversar", não isto.
--
-- Cobre os 3 tipos que já formam a "fila de decisões" do admin360 (ZONAS.
-- decidir = pendentes/pedidos/treinadores) — não só "inscrição" à letra, para
-- não deixar o admin a par de 1 em 3 categorias:
--   - atletas_360 (insert, estado='pendente')            → nova inscrição
--   - registos_pendentes (insert)                        → novo treinador
--   - atletas_360_pedidos_contacto (insert)               → pedido de clube
--
-- Mecanismo: trigger AFTER INSERT em cada tabela → pg_net.http_post (async,
-- não bloqueia a escrita original) → Edge Function notificar-pendente →
-- Resend. _ytb_notificar_admin nunca deixa uma falha de rede impedir o
-- insert que a disparou (exception handler engole erros, só regista em log).
-- A function chama-se com o anon key (público, já exposto no cliente) como
-- Authorization — não há segredo nenhum embutido em SQL.
--
-- O que só o fundador pode fazer (não é ação que a Claude possa tomar por
-- ele — política de nunca inserir chaves/credenciais em serviços de
-- terceiros em nome do utilizador): criar conta em resend.com, gerar a API
-- key, e defini-la como secret da Edge Function (RESEND_API_KEY) — dashboard
-- Supabase → Edge Functions → notificar-pendente → Secrets, ou
-- `supabase secrets set RESEND_API_KEY=...` na CLI. Sem essa chave, a função
-- responde 200 sem enviar nada (falha silenciosa e visível nos logs, nunca
-- bloqueia inscrições) — nada finge que o email foi enviado se não foi.
--
-- Validado em dry-run (2026-07-15): triggers disparam nos 3 inserts; sem a
-- secret configurada a function devolve {ok:false, motivo:'sem_api_key'} e o
-- insert original continua a funcionar.
-- ============================================================================

create extension if not exists pg_net;

create or replace function public._ytb_notificar_admin(p_tipo text, p_nome text, p_detalhe text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform net.http_post(
    url := 'https://nhshnplaiolxwcfuijfo.supabase.co/functions/v1/notificar-pendente',
    body := jsonb_build_object('tipo', p_tipo, 'nome', p_nome, 'detalhe', p_detalhe),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oc2hucGxhaW9seHdjZnVpamZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NDQxNTAsImV4cCI6MjA4OTQyMDE1MH0.uyZiDun8495sjnHA6Wsk-Hou-3lubbNJfQqSYbMLSek'
    ),
    timeout_milliseconds := 5000
  );
exception when others then
  raise warning 'ytb_notificar_admin falhou (tipo=%, nome=%): %', p_tipo, p_nome, sqlerrm;
end $$;

create or replace function public._ytb_trig_notificar_inscricao()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.estado = 'pendente' then
    perform public._ytb_notificar_admin('inscricao', coalesce(new.nome,'—'), coalesce(new.clube_actual,new.escalao));
  end if;
  return new;
end $$;

drop trigger if exists trig_notificar_inscricao on public.atletas_360;
create trigger trig_notificar_inscricao
  after insert on public.atletas_360
  for each row execute function public._ytb_trig_notificar_inscricao();

create or replace function public._ytb_trig_notificar_registo_treinador()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public._ytb_notificar_admin('registo_treinador', coalesce(new.nome,'—'), coalesce(new.papel, null));
  return new;
end $$;

drop trigger if exists trig_notificar_registo_treinador on public.registos_pendentes;
create trigger trig_notificar_registo_treinador
  after insert on public.registos_pendentes
  for each row execute function public._ytb_trig_notificar_registo_treinador();

create or replace function public._ytb_trig_notificar_pedido_contacto()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_atleta_nome text;
begin
  select nome into v_atleta_nome from public.atletas_360 where id = new.atleta_id;
  perform public._ytb_notificar_admin('pedido_contacto', coalesce(new.clube_nome,'—'), 'sobre '||coalesce(v_atleta_nome,'atleta'));
  return new;
end $$;

drop trigger if exists trig_notificar_pedido_contacto on public.atletas_360_pedidos_contacto;
create trigger trig_notificar_pedido_contacto
  after insert on public.atletas_360_pedidos_contacto
  for each row execute function public._ytb_trig_notificar_pedido_contacto();
