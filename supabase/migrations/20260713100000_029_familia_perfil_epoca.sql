-- ============================================================================
-- MIGRAÇÃO 029 · PERFIL E ÉPOCA DA FAMÍLIA (self-service)
-- Achado do fundador (2026-07-13): "o admin tem um monte de funcionalidades
-- e dados a preencher que deveriam estar do lado do pai ou atleta". Correto —
-- clube atual, escalão, posição, pé, links e sobretudo as ESTATÍSTICAS DA
-- ÉPOCA (golos/jogos/assistências) só tinham escrita via admin, obrigando
-- o admin a digitar à mão factos que só a família sabe. Continua a ser
-- possível a Regra de Ouro: quem alimenta o sistema recebe valor — e aqui
-- é a própria família a ganhar orgulho ao registar a época do filho.
--
-- O que NÃO passa para a família (fica deliberadamente só no admin):
-- rating_geral/badge/áreas de excelência (curadoria, não facto — se a
-- família se autoavaliasse não valeria nada), estado/visibilidade/notas
-- admin (moderação), e encarregado_email (é a chave que liga a sessão ao
-- atleta — mudá-la é uma operação de identidade, fica atrás de suporte
-- humano, não self-service).
--
-- Guarda: _ytb_e_encarregado(p_atleta) — a mesma já usada por
-- ytb_biometria_registar/ytb_diario_registar/ytb_biometria_pais_registar.
--
-- Eventos: mudança de clube/escalão e registo de época emitem evento
-- (origem='declarado', fonte='familia') — são marcos de percurso reais.
-- Correções de contacto/posição/links NÃO emitem evento, mesmo padrão já
-- usado em ytb_biometria_pais_registar (metadado, não "momento").
-- 'epoca_registada' já estava na whitelist pública da montra (migração
-- 026) à espera de ser implementado — fica implementado agora.
--
-- Validado em dry-run (2026-07-13): leitura autorizada/negada, atualização
-- de perfil com evento só quando clube/escalão mudam de facto (não em
-- correções triviais), registo de época com evento sempre, intruso
-- (email diferente do encarregado) bloqueado em todas as 3 funções.
-- ============================================================================

create or replace function public.ytb_familia_perfil_atual(p_atleta uuid)
returns jsonb language sql security definer set search_path = public as $$
  select case when public._ytb_e_encarregado(p_atleta) or public.ytb_is_admin() then
    (select jsonb_build_object(
      'clube_actual', clube_actual, 'equipa', equipa, 'escalao', escalao, 'associacao', associacao,
      'posicao_principal', posicao_principal, 'pe_dominante', pe_dominante,
      'zerozero_url', zerozero_url, 'joga_plus_url', joga_plus_url,
      'encarregado_nome', encarregado_nome, 'encarregado_telefone', encarregado_telefone,
      'epoca_ref', epoca_ref, 'divisao', divisao, 'golos_epoca', golos_epoca, 'jogos_epoca', jogos_epoca,
      'assist_epoca', assist_epoca, 'golos_equipa_epoca', golos_equipa_epoca, 'classificacao_equipa', classificacao_equipa
    ) from public.atletas_360 where id = p_atleta)
  else null end
$$;
grant execute on function public.ytb_familia_perfil_atual(uuid) to authenticated;

create or replace function public.ytb_familia_perfil_atualizar(
  p_atleta uuid, p_clube_actual text default null, p_equipa text default null, p_escalao text default null,
  p_associacao text default null, p_posicao_principal text default null, p_pe_dominante text default null,
  p_zerozero_url text default null, p_joga_plus_url text default null,
  p_encarregado_nome text default null, p_encarregado_telefone text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_clube_antes text; v_esc_antes text; v_partes text[] := array[]::text[];
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_posicao_principal is not null and p_posicao_principal not in ('GR','DC','LD','LE','MD','MC','MO','ED','EE','PL','AV') then
    return jsonb_build_object('ok', false, 'motivo', 'posicao_invalida');
  end if;

  select clube_actual, escalao into v_clube_antes, v_esc_antes from public.atletas_360 where id = p_atleta;

  update public.atletas_360 set
    clube_actual         = case when p_clube_actual is not null and trim(p_clube_actual)<>'' then trim(p_clube_actual) else clube_actual end,
    equipa               = case when p_equipa is not null then nullif(trim(p_equipa),'') else equipa end,
    escalao              = case when p_escalao is not null and trim(p_escalao)<>'' then trim(p_escalao) else escalao end,
    associacao           = case when p_associacao is not null then nullif(trim(p_associacao),'') else associacao end,
    posicao_principal    = coalesce(p_posicao_principal, posicao_principal),
    pe_dominante         = case when p_pe_dominante is not null then public._ytb_pe_norm(p_pe_dominante) else pe_dominante end,
    zerozero_url         = case when p_zerozero_url is not null then nullif(trim(p_zerozero_url),'') else zerozero_url end,
    joga_plus_url        = case when p_joga_plus_url is not null then nullif(trim(p_joga_plus_url),'') else joga_plus_url end,
    encarregado_nome     = case when p_encarregado_nome is not null and trim(p_encarregado_nome)<>'' then trim(p_encarregado_nome) else encarregado_nome end,
    encarregado_telefone = case when p_encarregado_telefone is not null then nullif(trim(p_encarregado_telefone),'') else encarregado_telefone end
  where id = p_atleta;

  if p_clube_actual is not null and trim(p_clube_actual)<>'' and trim(p_clube_actual) <> coalesce(v_clube_antes,'') then
    v_partes := array_append(v_partes, 'novo clube: ' || trim(p_clube_actual));
  end if;
  if p_escalao is not null and trim(p_escalao)<>'' and trim(p_escalao) <> coalesce(v_esc_antes,'') then
    v_partes := array_append(v_partes, 'novo escalão: ' || trim(p_escalao));
  end if;
  if array_length(v_partes,1) > 0 then
    insert into public.atleta_eventos (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, payload)
    values (p_atleta, 'percurso_atualizado', 'marco', 'Percurso atualizado: ' || array_to_string(v_partes, ', '),
            'familia', 'declarado', 2, jsonb_build_object('clube_antes', v_clube_antes, 'escalao_antes', v_esc_antes));
  end if;

  return jsonb_build_object('ok', true);
end $$;
grant execute on function public.ytb_familia_perfil_atualizar(uuid,text,text,text,text,text,text,text,text,text,text) to authenticated;

create or replace function public.ytb_familia_epoca_registar(
  p_atleta uuid, p_epoca_ref text default null, p_divisao text default null,
  p_golos_epoca int default null, p_jogos_epoca int default null, p_assist_epoca int default null,
  p_golos_equipa_epoca int default null, p_classificacao_equipa text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public._ytb_e_encarregado(p_atleta) then
    return jsonb_build_object('ok', false, 'motivo', 'nao_autorizado');
  end if;
  if p_golos_epoca is not null and (p_golos_epoca < 0 or p_golos_epoca > 200) then return jsonb_build_object('ok',false,'motivo','golos_invalidos'); end if;
  if p_jogos_epoca is not null and (p_jogos_epoca < 0 or p_jogos_epoca > 100) then return jsonb_build_object('ok',false,'motivo','jogos_invalidos'); end if;
  if p_assist_epoca is not null and (p_assist_epoca < 0 or p_assist_epoca > 200) then return jsonb_build_object('ok',false,'motivo','assist_invalidos'); end if;

  update public.atletas_360 set
    epoca_ref             = case when p_epoca_ref is not null and trim(p_epoca_ref)<>'' then trim(p_epoca_ref) else epoca_ref end,
    divisao               = case when p_divisao is not null then nullif(trim(p_divisao),'') else divisao end,
    golos_epoca            = coalesce(p_golos_epoca, golos_epoca),
    jogos_epoca            = coalesce(p_jogos_epoca, jogos_epoca),
    assist_epoca           = coalesce(p_assist_epoca, assist_epoca),
    golos_equipa_epoca     = coalesce(p_golos_equipa_epoca, golos_equipa_epoca),
    classificacao_equipa  = case when p_classificacao_equipa is not null then nullif(trim(p_classificacao_equipa),'') else classificacao_equipa end
  where id = p_atleta;

  insert into public.atleta_eventos (atleta_id, tipo, categoria, titulo, fonte, origem, relevancia, payload)
  values (p_atleta, 'epoca_registada', 'marco',
          'Estatísticas da época registadas'
            || case when p_golos_epoca is not null then ' · ' || p_golos_epoca || ' golo' || case when p_golos_epoca=1 then '' else 's' end else '' end
            || case when p_jogos_epoca is not null then ' em ' || p_jogos_epoca || ' jogo' || case when p_jogos_epoca=1 then '' else 's' end else '' end,
          'familia', 'declarado', 2,
          jsonb_build_object('epoca_ref', p_epoca_ref, 'golos', p_golos_epoca, 'jogos', p_jogos_epoca, 'assist', p_assist_epoca));

  return jsonb_build_object('ok', true);
end $$;
grant execute on function public.ytb_familia_epoca_registar(uuid,text,text,int,int,int,int,text) to authenticated;
