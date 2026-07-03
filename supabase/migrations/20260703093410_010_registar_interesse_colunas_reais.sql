-- ============================================================================
-- MIGRAÇÃO 010 · ytb_registar_interesse alinhada com o esquema REAL
-- registos_pendentes usa telemovel + notas (não telefone + mensagem).
-- A versão da 009 falharia em runtime; corrigida aqui.
-- ============================================================================
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
  if exists (select 1 from public.registos_pendentes
              where lower(email)=lower(trim(p_email)) and estado='pendente') then
    return jsonb_build_object('ok',true,'ja_existia',true);
  end if;
  insert into public.registos_pendentes (nome, email, telemovel, papel, notas, estado)
  values (trim(p_nome), lower(trim(p_email)), nullif(trim(p_telefone),''),
          nullif(trim(p_papel),''), nullif(trim(p_mensagem),''), 'pendente')
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;
grant execute on function public.ytb_registar_interesse(text,text,text,text,text) to anon, authenticated;