-- ============================================================================
-- MIGRAÇÃO 025 · TETO DE PENDENTES POR TREINADOR + ELIMINAR CONTA (2 NÍVEIS)
--
-- 1) ytb_treinador_inscrever ganha um teto de atletas PENDENTES por treinador.
--    Antes não havia limite nenhum — um treinador podia criar dezenas de
--    atletas em estado 'pendente' sem qualquer pagamento associado (o
--    pagamento entra só quando o admin confirma). Teto fixo de 20 pendentes
--    em simultâneo; ao aprovar/confirmar, o contador liberta. Mensagem clara.
--    (Fixo por agora; tornar configurável por treinador é decisão futura.)
--
-- 2) ytb_admin_perfil_eliminar — o "eliminar definitivamente" que faltava.
--    Já existia só o bloquear/reativar (ytb_admin_perfil_estado, reversível).
--    IMPORTANTE — porque NÃO apagamos auth.users: verificou-se que
--    treinador_avaliacoes.treinador_id e treinador_treinos.treinador_id são
--    FK ON DELETE CASCADE para auth.users. Apagar o login de um treinador
--    arrastaria as avaliações e os planos que ele criou — que são dados do
--    PASSAPORTE da criança (Constituição: o registo pertence à criança, nunca
--    se apaga para trás). Por isso o "eliminar definitivo" NÃO toca em
--    auth.users; em vez disso anonimiza a identidade da pessoa e bloqueia o
--    acesso de forma permanente (estado='eliminado', distinto do 'bloqueado'
--    reversível), preservando intactos os passaportes das crianças. Os
--    atletas que a conta inscreveu ficam com a fonte anonimizada (o passaporte
--    continua, só perde o nome de quem o registou). As duas contas-mestre
--    nunca são elimináveis. A erasure total do registo de auth (se algum dia
--    for legalmente exigida) tem de re-parentar primeiro essas avaliações —
--    fica fora desta RPC de propósito.
--
-- Validado em dry-run transacional (2026-07-10): teto bloqueia ao 20º
-- pendente e deixa passar abaixo disso; eliminar anonimiza a fonte dos
-- atletas e mantém-nos, marca o perfil 'eliminado', protege as contas-mestre,
-- e é negado a não-admins.
-- ============================================================================

create or replace function public.ytb_treinador_inscrever(
  p_nome text, p_ano integer, p_assoc text, p_pos text, p_clube text, p_zz text,
  p_email_enc text, p_dia_nasc integer default null, p_mes_nasc integer default null,
  p_esquema text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_email text; v_pendentes int;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public.ytb_is_treinador() then
    return jsonb_build_object('ok',false,'motivo','sem_papel_treinador');
  end if;
  if coalesce(p_nome,'')='' or p_ano is null then
    return jsonb_build_object('ok',false,'motivo','dados_incompletos');
  end if;
  if p_pos is null or p_pos not in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then
    return jsonb_build_object('ok',false,'motivo','posicao_obrigatoria');
  end if;
  if coalesce(trim(p_clube),'') = '' then
    return jsonb_build_object('ok',false,'motivo','clube_obrigatorio');
  end if;
  if p_zz is null or p_zz !~* 'zerozero\.pt/\S' then
    return jsonb_build_object('ok',false,'motivo','zerozero_invalido');
  end if;
  if p_email_enc is null or position('@' in p_email_enc)=0 then
    return jsonb_build_object('ok',false,'motivo','email_encarregado_invalido');
  end if;
  if p_dia_nasc is not null and p_dia_nasc not between 1 and 31 then
    return jsonb_build_object('ok',false,'motivo','dia_invalido');
  end if;
  if p_mes_nasc is not null and p_mes_nasc not between 1 and 12 then
    return jsonb_build_object('ok',false,'motivo','mes_invalido');
  end if;

  -- teto de pendentes por treinador (evita fila infinita sem pagamento)
  select count(*) into v_pendentes from public.atletas_360
   where fonte='treinador' and lower(coalesce(fonte_email,''))=v_email and estado='pendente';
  if v_pendentes >= 20 then
    return jsonb_build_object('ok',false,'motivo','teto_pendentes',
      'detalhe','Tens 20 atletas à espera de aprovação. Aguarda que o admin confirme os que já inscreveste antes de adicionar mais.');
  end if;

  insert into public.atletas_360
    (nome, primeiro_nome, ano_nascimento, mes_nascimento, dia_nascimento, escalao, associacao,
     posicao_principal, clube_actual, zerozero_url, esquema_tatico,
     estado, visivel_b2b, fonte, fonte_nome, fonte_email, encarregado_email)
  values
    (p_nome, split_part(p_nome,' ',1), p_ano, p_mes_nasc, p_dia_nasc,
     public._ytb_escalao_de(null, p_ano),
     coalesce(nullif(trim(p_assoc),''), 'Não filiado'),
     p_pos,
     trim(p_clube),
     p_zz, nullif(trim(p_esquema),''),
     'pendente', false, 'treinador',
     coalesce((select nome from public.perfis where lower(email)=v_email), v_email),
     v_email, lower(trim(p_email_enc)))
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;

-- o CHECK de perfis.estado só permitia pendente/aprovado/rejeitado; passa a
-- aceitar também 'bloqueado' (bloqueio reversível, já referido em auth.html) e
-- 'eliminado' (o novo estado terminal permanente). Sem afetar dados existentes.
alter table public.perfis drop constraint if exists perfis_estado_check;
alter table public.perfis add constraint perfis_estado_check
  check (estado = any (array['pendente','aprovado','rejeitado','bloqueado','eliminado']));

create or replace function public.ytb_admin_perfil_eliminar(p_email text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_alvo text; v_atletas int;
begin
  if not public.ytb_is_admin() then
    return jsonb_build_object('ok',false,'motivo','nao_admin');
  end if;
  v_alvo := lower(trim(coalesce(p_email,'')));
  if v_alvo = '' or position('@' in v_alvo) = 0 then
    return jsonb_build_object('ok',false,'motivo','email_invalido');
  end if;
  if v_alvo in ('ipedronmartins@gmail.com','yourtalentbase@gmail.com') then
    return jsonb_build_object('ok',false,'motivo','conta_mestre_protegida');
  end if;

  -- anonimizar os atletas que esta conta inscreveu (o passaporte fica; perde só
  -- o nome de quem registou — pertence à criança, não a quem a inseriu).
  -- fonte_nome e fonte_email são NOT NULL, por isso usa-se um sentinela em vez
  -- de null; nenhum login real corresponde a '(conta eliminada)', logo o
  -- atleta deixa de estar ligado a quem quer que seja.
  update public.atletas_360
     set fonte_nome = '(conta eliminada)', fonte_email = '(conta eliminada)'
   where lower(coalesce(fonte_email,'')) = v_alvo;
  get diagnostics v_atletas = row_count;

  -- marcar o perfil como eliminado (permanente, distinto do bloqueado
  -- reversível) e apagar a identidade pessoal. NÃO se toca em auth.users nem
  -- nas avaliações/planos (dados do passaporte) — ver cabeçalho.
  update public.perfis
     set estado = 'eliminado', nome = '(conta eliminada)'
   where lower(email) = v_alvo;

  return jsonb_build_object('ok',true,'atletas_anonimizados',v_atletas);
end $$;

grant execute on function public.ytb_admin_perfil_eliminar(text) to authenticated;
