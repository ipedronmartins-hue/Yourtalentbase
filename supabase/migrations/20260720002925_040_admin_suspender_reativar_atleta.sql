-- 040: ytb_admin_atleta_estado ganha as acoes suspender/reativar (par de 039).
CREATE OR REPLACE FUNCTION public.ytb_admin_atleta_estado(p_id uuid, p_acao text, p_motivo text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.ytb_is_admin() then return jsonb_build_object('ok',false,'motivo','nao_admin'); end if;
  if p_acao = 'aprovar' then
    update public.atletas_360
       set estado='aprovado', aprovado_por='Admin YTB', aprovado_em=now(), estado_motivo=null
     where id=p_id;
  elsif p_acao = 'rejeitar' then
    update public.atletas_360
       set estado='rejeitado', estado_motivo=p_motivo, visivel_b2b=false, visivel_publico=false
     where id=p_id;
  elsif p_acao = 'suspender' then
    update public.atletas_360
       set estado='suspenso', estado_motivo=coalesce(p_motivo,'pagamento em falta')
     where id=p_id;
  elsif p_acao = 'reativar' then
    update public.atletas_360
       set estado='aprovado', aprovado_por='Admin YTB', aprovado_em=now(), estado_motivo=null
     where id=p_id;
  else
    return jsonb_build_object('ok',false,'motivo','acao_invalida');
  end if;
  insert into public.atleta_eventos (atleta_id,tipo,categoria,titulo,fonte,origem,relevancia,payload)
  values (p_id,'estado_admin','marco',
          case p_acao
            when 'aprovar' then 'Atleta aprovado'
            when 'rejeitar' then 'Atleta rejeitado'
            when 'suspender' then 'Acesso suspenso'
            when 'reativar' then 'Acesso reativado'
          end,
          'admin','sistema',2, jsonb_build_object('acao',p_acao,'motivo',p_motivo));
  return jsonb_build_object('ok',true);
end $function$;
