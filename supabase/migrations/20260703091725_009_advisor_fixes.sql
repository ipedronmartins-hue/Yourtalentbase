-- ============================================================================
-- MIGRAÇÃO 009 · CORREÇÕES DO SECURITY ADVISOR (pós-blindagem)
-- Fecho dos achados reais do linter nativo; o ruído (deny-all sem policies,
-- RPCs definer intencionais com porta interna) fica documentado no relatório.
-- ============================================================================

-- (1) Policies INSERT/true que escaparam à 006 (caçava ALL/true)
drop policy if exists ecr_insert_publico on public.elite_coach_resultados;
drop policy if exists reg_pend_insert on public.registos_pendentes;

-- (2) Caminho limpo para registos públicos de profissionais (Constituição:
--     escrita só por RPC). Se existir alguma página de registo no site,
--     troca .from('registos_pendentes').insert(x) por .rpc('ytb_registar_interesse', x).
create or replace function public.ytb_registar_interesse(
  p_nome text, p_email text, p_telefone text default null,
  p_papel text default null, p_mensagem text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if coalesce(trim(p_nome),'') = '' then
    return jsonb_build_object('ok',false,'motivo','nome');
  end if;
  if p_email is null or position('@' in p_email) = 0 then
    return jsonb_build_object('ok',false,'motivo','email');
  end if;
  -- trava-spam mínima: 1 registo pendente por email
  if exists (select 1 from public.registos_pendentes
              where lower(email)=lower(trim(p_email)) and estado='pendente') then
    return jsonb_build_object('ok',true,'ja_existia',true);
  end if;
  insert into public.registos_pendentes (nome, email, telefone, papel, mensagem, estado)
  values (trim(p_nome), lower(trim(p_email)), nullif(trim(p_telefone),''),
          nullif(trim(p_papel),''), nullif(trim(p_mensagem),''), 'pendente')
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;
grant execute on function public.ytb_registar_interesse(text,text,text,text,text) to anon, authenticated;

-- (3) Funções legadas gated (papel_actual='admin') usadas pelo admin360:
--     ficam para authenticated, saem do alcance anon
do $$
declare r record;
begin
  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid=p.pronamespace
           where n.nspname='public'
             and p.proname in ('admin_dar_creditos','admin_registar_pagamento','admin_registar_comissao')
  loop
    execute format('revoke execute on function %s from anon', r.fn);
  end loop;
end $$;

-- (4) Funções mortas (zero páginas vivas) e funções de trigger/helper:
--     execute revogado a clientes. Triggers correm como dono da tabela e
--     definer→definer mantém-se — nada disto afeta o funcionamento interno.
do $$
declare r record;
begin
  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid=p.pronamespace
           where n.nspname='public'
             and p.proname in (
               'sou_encarregado','meu_email','papel_actual','pode_usar_ia','registar_uso_ia',
               'scout_creditos_restantes','scout_gastar_credito','admin_aprovar_perfil',
               'minhas_comissoes_mes','fn_calcular_rating_atleta','ytb_gerar_id_publico',
               'fn_dashboard_treinador',
               'criar_perfil_no_signup','handle_new_user','handle_updated_at',
               'update_atletas360_updated_at','trg_aval_rating_numeric',
               'fn_evento_aprovacao','fn_evento_avaliacao','fn_evento_report',
               'fn_notif_nova_inscricao','fn_pagamento_confirmado',
               'fn_pode_usar','fn_letra_para_numero','fn_numero_para_letra','fn_nome_norm',
               'ytb_emitir_evento'
             )
  loop
    execute format('revoke execute on function %s from anon, authenticated', r.fn);
  end loop;
end $$;

-- (5) search_path fixo nas 14 funções sinalizadas (inclui a minha ytb_num)
do $$
declare r record;
begin
  for r in select p.oid::regprocedure as fn
           from pg_proc p join pg_namespace n on n.oid=p.pronamespace
           where n.nspname='public'
             and p.proname in (
               'handle_new_user','handle_updated_at','update_atletas360_updated_at',
               'rating_to_int','trg_aval_rating_numeric','fn_notif_nova_inscricao',
               'fn_pagamento_confirmado','fn_dashboard_treinador','fn_pode_usar',
               'fn_letra_para_numero','fn_numero_para_letra','fn_nome_norm',
               'ytb_gerar_id_publico','ytb_num'
             )
  loop
    execute format('alter function %s set search_path = public', r.fn);
  end loop;
end $$;

-- (6) Bucket público de fotos de menores deixa de ser LISTÁVEL.
--     URLs públicas de objetos individuais continuam a funcionar.
drop policy if exists "Fotos atletas públicas" on storage.objects;