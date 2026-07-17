-- ============================================================================
-- 037 · o fundador tem sempre acesso a qualquer passaporte, mesmo pela porta
-- da família — não só pela ?admin=
-- ----------------------------------------------------------------------------
-- ytb_passaporte_admin já tinha um bypass por email fixo do fundador + perfis
-- papel=admin aprovado; ytb_passaporte_email exigia sempre
-- encarregado_email = email autenticado, sem exceção — correto para qualquer
-- família real (isolamento entre famílias é a garantia central do produto),
-- mas bloqueava o fundador ao testar atletas que não são filhos dele pela via
-- ?atleta=, obrigando-o a saber de cor que tinha de trocar para ?admin=.
-- Extrai-se o bypass para uma função partilhada (_ytb_e_admin) para as duas
-- RPCs nunca poderem divergir, e aplica-se também em ytb_passaporte_email.
-- Isolamento entre famílias reais não muda: só contas em perfis.papel='admin'
-- aprovadas (ou o email fixo do fundador) ganham este atalho; qualquer outra
-- continua limitada ao seu próprio encarregado_email.
--
-- Bónus de robustez encontrado ao mexer nos grants destas RPCs: _ytb_dev_score
-- (035c) está documentada como "interna, SEM grant a nenhum role" mas o grant
-- por omissão do Postgres a PUBLIC nunca foi revogado — qualquer conta
-- autenticada conseguia chamar _ytb_dev_score(uuid) directamente por RPC e ler
-- o Development Score de QUALQUER atleta, sem passar pelos wrappers que
-- verificam acesso (_ytb_passaporte_json, ytb_treinador_digest). Revoga-se
-- agora para a intenção documentada passar a ser real; os wrappers continuam
-- a conseguir chamá-la (chamada interna função-a-função, não precisa de grant
-- ao role autenticado).
--
-- Validado em dry-run (2026-07-17) antes de aplicar, com atletas e contas
-- reais do piloto:
--   - fundador via ?atleta= abre atletas próprios (já abria) E atletas que
--     não são filhos dele (antes bloqueava, agora abre via bypass);
--   - um encarregado real (não-admin) continua a NÃO ver atletas que não são
--     seus, nem por ?atleta= nem por ?admin=, nem consegue chamar
--     _ytb_dev_score de um atleta que não é seu;
--   - sessão sem email/anon continua bloqueada em ambas as RPCs.
-- ============================================================================

create or replace function public._ytb_e_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select lower(coalesce(auth.jwt() ->> 'email','')) in ('ipedronmartins@gmail.com','yourtalentbase@gmail.com')
      or exists (
           select 1 from public.perfis p
            where lower(p.email) = lower(coalesce(auth.jwt() ->> 'email',''))
              and p.papel = 'admin' and p.estado = 'aprovado');
$$;
revoke all on function public._ytb_e_admin() from public, anon, authenticated;

create or replace function public.ytb_passaporte_admin(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public._ytb_e_admin() or p_atleta is null then
    return null;
  end if;
  return public._ytb_passaporte_json(p_atleta);
end $$;

create or replace function public.ytb_passaporte_email(p_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_atleta uuid; v_email text;
begin
  if p_atleta is null then
    return null;
  end if;
  if public._ytb_e_admin() then
    return public._ytb_passaporte_json(p_atleta);
  end if;
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return null; end if;
  select a.id into v_atleta
    from public.atletas_360 a
   where a.id = p_atleta and lower(coalesce(a.encarregado_email,'')) = v_email
   limit 1;
  if v_atleta is null then
    return null;
  end if;
  return public._ytb_passaporte_json(v_atleta);
end $$;

revoke all on function public._ytb_dev_score(uuid) from public, anon, authenticated;
