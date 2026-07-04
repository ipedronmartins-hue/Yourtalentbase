-- ============================================================================
-- MIGRAÇÃO 016 · CAMPOS COMUNS DO ATLETA + CORREÇÃO DA ESCRITA DO SCOUT REPORT
-- Descoberta durante levantamento de campos: scouts.html gravava relatórios
-- com supa.from('relatorios').insert() DIRETO (Nunca 6) e o grant de escrita
-- foi revogado na blindagem — nenhum relatório salva desde 2026-07-02.
-- As leituras (histórico próprio, comparação com anterior) também dependiam
-- de RLS sem policy aplicável a scouts não-admin. Fecha-se com RPCs, no
-- mesmo padrão de todas as reparações do Mandato 2. O evento no livro é
-- automático via ytb_ev_relatorios (000, tipo 'relatorio_jogo') — não se
-- duplica aqui.
-- Também: esquema_tatico (nova coluna) e associação/data completa de
-- nascimento (colunas já existentes, mes_nascimento/dia_nascimento nunca
-- usadas) passam a ser aceites por ytb_treinador_inscrever e
-- ytb_inscrever_livre, como parâmetros opcionais (compatível com chamadas
-- existentes por nome).
-- Validada em dry-run transacional (2026-07-04): 12 asserções — campos
-- gravados corretamente, validação de dia/mês, intruso bloqueado em
-- escrita e leitura (RPC, não RLS — a sessão de teste liga como postgres
-- com rolbypassrls=true, tornando testes de RLS pura não fiáveis neste
-- ambiente), evento automático emitido, leitura própria e comparação
-- cross-scout funcionais.
-- ============================================================================

alter table public.atletas_360 add column if not exists esquema_tatico text;

create or replace function public.ytb_treinador_inscrever(
  p_nome text, p_ano int, p_assoc text, p_pos text,
  p_clube text, p_zz text, p_email_enc text,
  p_dia_nasc int default null, p_mes_nasc int default null, p_esquema text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not public.ytb_is_treinador() then
    return jsonb_build_object('ok',false,'motivo','sem_papel_treinador');
  end if;
  if coalesce(p_nome,'')='' or p_ano is null then
    return jsonb_build_object('ok',false,'motivo','dados_incompletos');
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

  insert into public.atletas_360
    (nome, primeiro_nome, ano_nascimento, mes_nascimento, dia_nascimento, escalao, associacao,
     posicao_principal, clube_actual, zerozero_url, esquema_tatico,
     estado, visivel_b2b, fonte, fonte_nome, fonte_email, encarregado_email)
  values
    (p_nome, split_part(p_nome,' ',1), p_ano, p_mes_nasc, p_dia_nasc,
     'Sub-'||(date_part('year', now())::int - p_ano),
     p_assoc,
     case when p_pos in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then p_pos else null end,
     p_clube, p_zz, nullif(trim(p_esquema),''),
     'pendente', false, 'treinador',
     coalesce((select nome from public.perfis where lower(email)=v_email), v_email),
     v_email, lower(trim(p_email_enc)))
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id);
end $$;

create or replace function public.ytb_inscrever_livre(
  p_nome text, p_ano int, p_posicao text, p_clube text,
  p_associacao text, p_zerozero text, p_contacto text,
  p_dia_nasc int default null, p_mes_nasc int default null, p_esquema text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if coalesce(trim(p_nome),'')='' then
    return jsonb_build_object('ok',false,'motivo','nome');
  end if;
  if p_zerozero is null or p_zerozero !~* 'zerozero\.pt/\S' then
    return jsonb_build_object('ok',false,'motivo','zerozero');
  end if;
  if p_dia_nasc is not null and p_dia_nasc not between 1 and 31 then
    return jsonb_build_object('ok',false,'motivo','dia_invalido');
  end if;
  if p_mes_nasc is not null and p_mes_nasc not between 1 and 12 then
    return jsonb_build_object('ok',false,'motivo','mes_invalido');
  end if;

  insert into public.atletas_360 (
    id, nome, primeiro_nome, ano_nascimento, mes_nascimento, dia_nascimento, escalao,
    associacao, posicao_principal, clube_actual, zerozero_url, esquema_tatico,
    estado, visivel_b2b, visivel_publico,
    fonte, fonte_nome, fonte_email, encarregado_email
  ) values (
    gen_random_uuid(), trim(p_nome), split_part(trim(p_nome),' ',1),
    p_ano, p_mes_nasc, p_dia_nasc,
    case when p_ano is not null and p_ano > 2000
         then 'Sub-'||(extract(year from now())::int - p_ano) else null end,
    nullif(trim(p_associacao),''), nullif(trim(p_posicao),''),
    nullif(trim(p_clube),''), trim(p_zerozero), nullif(trim(p_esquema),''),
    'pendente', false, false,
    'auto', 'Auto-inscrição',
    lower(nullif(trim(p_contacto),'')), lower(nullif(trim(p_contacto),''))
  ) returning id into v_id;

  return jsonb_build_object('ok',true,'id',v_id);
end $$;

grant execute on function public.ytb_treinador_inscrever(text,int,text,text,text,text,text,int,int,text) to authenticated;
grant execute on function public.ytb_inscrever_livre(text,int,text,text,text,text,text,int,int,text) to anon, authenticated;

create or replace function public.ytb_scout_relatorio_criar(
  p_atleta_id uuid, p_atleta_nome text, p_clube text, p_categoria text,
  p_posicao text, p_epoca text, p_scores jsonb, p_dados jsonb,
  p_relatorio_texto text, p_decisao text, p_rendimento text,
  p_prazo text, p_media_geral numeric
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_id uuid; v_scout_nome text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or exists (
       select 1 from public.perfis p
        where lower(p.email)=v_email and p.papel='scout' and coalesce(p.estado,'aprovado')='aprovado'
     )) then
    return jsonb_build_object('ok',false,'motivo','sem_papel_scout');
  end if;
  if coalesce(trim(p_atleta_nome),'')='' then
    return jsonb_build_object('ok',false,'motivo','nome');
  end if;
  select coalesce(nome, v_email) into v_scout_nome from public.perfis where lower(email)=v_email;

  insert into public.relatorios
    (scout, atleta, atleta_id, clube, categoria, posicao, epoca,
     scores, dados, report_data, relatorio_texto, decisao, rendimento, prazo, media_geral)
  values
    (coalesce(v_scout_nome, v_email), trim(p_atleta_nome), p_atleta_id, p_clube, p_categoria, p_posicao,
     coalesce(p_epoca,'2025/2026'), p_scores, p_dados, p_dados,
     p_relatorio_texto, p_decisao, p_rendimento, p_prazo, p_media_geral)
  returning id into v_id;

  return jsonb_build_object('ok',true,'id',v_id);
end $$;

grant execute on function public.ytb_scout_relatorio_criar(uuid,text,text,text,text,text,jsonb,jsonb,text,text,text,text,numeric) to authenticated;

create or replace function public.ytb_scout_meus_relatorios(p_limit int default 10)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text; v_scout_nome text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  select nome into v_scout_nome from public.perfis where lower(email)=v_email;
  if v_scout_nome is null then return '[]'::jsonb; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', r.id, 'atleta', r.atleta, 'clube', r.clube, 'categoria', r.categoria,
             'posicao', r.posicao, 'epoca', r.epoca, 'media_geral', r.media_geral,
             'decisao', r.decisao, 'created_at', r.created_at)
           order by r.created_at desc)
    from (select * from public.relatorios where lower(scout)=lower(v_scout_nome)
          order by created_at desc limit greatest(p_limit,1)) r
  ), '[]'::jsonb);
end $$;

create or replace function public.ytb_scout_relatorio_anterior(p_atleta_id uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_email text;
begin
  v_email := lower(coalesce(auth.jwt()->>'email',''));
  if not (public.ytb_is_admin() or exists (
       select 1 from public.perfis p where lower(p.email)=v_email and p.papel='scout' and coalesce(p.estado,'aprovado')='aprovado'
     )) then
    return null;
  end if;
  return (
    select jsonb_build_object('scores', r.scores, 'media_geral', r.media_geral, 'decisao', r.decisao, 'criado_em', r.created_at, 'epoca', r.epoca)
    from public.relatorios r where r.atleta_id = p_atleta_id
    order by r.created_at desc limit 1
  );
end $$;

grant execute on function public.ytb_scout_meus_relatorios(int) to authenticated;
grant execute on function public.ytb_scout_relatorio_anterior(uuid) to authenticated;
