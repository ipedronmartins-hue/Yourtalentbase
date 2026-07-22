-- 039: permitir suspender o acesso de um atleta (pagamento em falta) sem apagar dados.
-- 'suspenso' é reversível e distinto de 'arquivado'/'revogado'. Bloqueia leitura E escrita
-- da família (RLS + RPCs), preserva acesso total ao admin.

ALTER TABLE public.atletas_360 DROP CONSTRAINT atletas_360_estado_check;
ALTER TABLE public.atletas_360 ADD CONSTRAINT atletas_360_estado_check
  CHECK (estado = ANY (ARRAY['pendente'::text,'aprovado'::text,'rejeitado'::text,'arquivado'::text,'revogado'::text,'suspenso'::text]));

CREATE OR REPLACE FUNCTION public.sou_encarregado(p_atleta uuid)
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.atletas_360 a
      where a.id = p_atleta
            and lower(a.encarregado_email) = lower((select email from public.perfis where id = auth.uid()))
            and coalesce(a.estado,'') <> 'suspenso'
  );
$function$;

CREATE OR REPLACE FUNCTION public._ytb_e_encarregado(p_atleta uuid)
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.atletas_360 a
    where a.id = p_atleta
      and lower(coalesce(a.encarregado_email,'')) = lower(coalesce(auth.jwt() ->> 'email',''))
      and coalesce(auth.jwt() ->> 'email','') <> ''
      and coalesce(a.estado,'') <> 'suspenso'
  )
$function$;

CREATE OR REPLACE FUNCTION public.ytb_meus_atletas()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return '[]'::jsonb; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', a.id, 'nome', a.nome, 'escalao', a.escalao,
             'clube', a.clube_actual, 'consentido', (a.consentido_em is not null),
             'suspenso', (a.estado = 'suspenso')
           ) order by a.nome)
    from public.atletas_360 a
    where lower(coalesce(a.encarregado_email,'')) = v_email
  ), '[]'::jsonb);
end $function$;

CREATE OR REPLACE FUNCTION public.ytb_passaporte_email(p_atleta uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_atleta uuid; v_email text;
begin
  if p_atleta is null then return null; end if;
  if public._ytb_e_admin() then return public._ytb_passaporte_json(p_atleta); end if;
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  if v_email = '' then return null; end if;
  select a.id into v_atleta
    from public.atletas_360 a
   where a.id = p_atleta
     and lower(coalesce(a.encarregado_email,'')) = v_email
     and coalesce(a.estado,'') <> 'suspenso'
   limit 1;
  if v_atleta is null then return null; end if;
  return public._ytb_passaporte_json(v_atleta);
end $function$;
