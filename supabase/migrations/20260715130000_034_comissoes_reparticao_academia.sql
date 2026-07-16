-- ============================================================================
-- MIGRAÇÃO 034 · REATIVA COMISSÕES COM REPARTIÇÃO A 3 (treinador/YTB/academia)
--
-- Pedido do fundador (2026-07-15): reverter a decisão de "comissões
-- descontinuadas" (admin360.html tinha isto hardcoded desde cedo) — o
-- treinador é quem traz e mantém os atletas na plataforma, sem incentivo não
-- há quem preencha avaliações. Fecha-se o preçário completo:
--   - Avaliação avulso (39,90€): 19,90€ treinador, resto YTB.
--   - Mensalidade avulso (9,90€): 4,90€ treinador, resto YTB.
--   - CoachBase avulso (9,90€) e Scout Report (39,90€): 100% YTB, sem comissão.
--   - Escolinha/Academia (19,90€ por atleta/mês, CoachBase incluído sem custo
--     extra): 30% treinador, 30% YTB, 40% academia — treinador precisa de
--     motivação para implementar, academia fica com a maior fatia porque é
--     quem traz o volume.
--
-- A tabela `comissoes` já existia (migração 000, nunca usada — 0 linhas em
-- produção, confirmado antes de mexer). Em vez de a recriar, estende-se: fica
-- 'academia' (valor + destinatário) ao lado do que já existia para
-- 'treinador'. Nada aqui automatiza pagamento real — não há Stripe/MB Way
-- ligado, os pagamentos continuam a acontecer fora da plataforma (WhatsApp +
-- transferência, como já é hoje: "o acesso é ativado assim que confirmarmos o
-- pagamento"). Isto é só o livro de registo: o admin lança o que recebeu, o
-- sistema calcula a repartição correta (nunca à mão, nunca inconsistente
-- entre lançamentos), e o admin marca quando já pagou a cada parte.
--
-- ytb_admin_registar_cobranca: admin lança o valor total recebido + o tipo;
-- a função calcula treinador/academia/YTB de acordo com a tabela acima —
-- nunca deixa o admin escrever a comissão à mão (evita erro/inconsistência).
-- ytb_admin_marcar_pago: marca a fatia do treinador OU da academia como paga
-- (são pagamentos distintos, em alturas distintas).
--
-- Validado em dry-run (2026-07-15): admin consegue lançar e marcar pago;
-- não-admin bloqueado; split de academia_atleta bate certo para 50/100
-- atletas (298,50/298,50/398,00 e 597,00/597,00/796,00, conferido à mão).
-- ============================================================================

alter table public.comissoes
  add column if not exists valor_academia numeric not null default 0,
  add column if not exists clube_id uuid references public.atletas_360_clubes_subscritores(id),
  add column if not exists pago_academia boolean not null default false;

create or replace function public.ytb_admin_registar_cobranca(
  p_tipo text, p_atleta_nome text, p_treinador_email text, p_valor_pago numeric,
  p_clube_id uuid default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_comissao numeric := 0; v_academia numeric := 0; v_id uuid;
begin
  if not public.ytb_is_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_valor_pago is null or p_valor_pago <= 0 then
    return jsonb_build_object('ok', false, 'motivo', 'valor_invalido');
  end if;

  if p_tipo = 'avaliacao' then v_comissao := 19.90;
  elsif p_tipo = 'mensalidade' then v_comissao := 4.90;
  elsif p_tipo = 'academia_atleta' then
    v_comissao := round(p_valor_pago * 0.30, 2);
    v_academia := round(p_valor_pago * 0.40, 2);
  elsif p_tipo in ('coachbase', 'scout') then
    v_comissao := 0; v_academia := 0;
  else
    return jsonb_build_object('ok', false, 'motivo', 'tipo_desconhecido');
  end if;

  insert into public.comissoes (treinador_email, atleta_nome, tipo, valor_pago, comissao, valor_academia, clube_id, mes, pago_ao_treinador)
  values (lower(p_treinador_email), p_atleta_nome, p_tipo, p_valor_pago, v_comissao, v_academia, p_clube_id, to_char(now(), 'YYYY-MM'), false)
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id, 'comissao', v_comissao, 'valor_academia', v_academia);
end $$;

grant execute on function public.ytb_admin_registar_cobranca(text,text,text,numeric,uuid) to authenticated;

create or replace function public.ytb_admin_marcar_pago(p_id uuid, p_alvo text)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.ytb_is_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_alvo = 'treinador' then
    update public.comissoes set pago_ao_treinador = true where id = p_id;
  elsif p_alvo = 'academia' then
    update public.comissoes set pago_academia = true where id = p_id;
  else
    return jsonb_build_object('ok', false, 'motivo', 'alvo_invalido');
  end if;
  return jsonb_build_object('ok', true);
end $$;

grant execute on function public.ytb_admin_marcar_pago(uuid,text) to authenticated;
