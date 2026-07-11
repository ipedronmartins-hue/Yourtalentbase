-- ============================================================================
-- MIGRAÇÃO 026 · MONTRA v3 — PERCURSO E PROVENIÊNCIA, NUNCA VEREDICTO
-- Pedido do fundador: uma montra sem login, de fácil acesso, "com mais alguns
-- dados". A v2 devolvia só nome/posição/escalão/clube — parecia uma lista.
-- A v3 enriquece com TUDO o que é percurso e proveniência (permitido) e NADA
-- que seja nota/classificação de menor (Constituição · nunca 1):
--   desde        — ano do primeiro evento no livro-razão ("percurso desde X")
--   epocas       — nº de anos distintos com eventos
--   eventos      — densidade do livro-razão
--   observadores — nº de fontes distintas com origem='observado'
--   verificacao  — selo de proveniência (Scout + Treinador / Scout / …), o
--                  mesmo texto que a área B2B usa; é autenticidade, não nota
--   marcos       — os 2 marcos mais recentes (títulos: "Atleta inscrito",
--                  "Sequência de 7 dias", "Interesse de clube"…) — são factos
--                  do percurso, não avaliações. WHITELIST por tipo: só
--                  inscricao/marco_sequencia/epoca_registada/interesse_clube;
--                  o dry-run mostrou que a categoria 'marco' também apanha
--                  ruído administrativo ("Ficha atualizada pelo admin") e até
--                  "Consentimento concedido: montra_publica" — informação de
--                  privacidade que NUNCA pode aparecer publicamente
--   ativo        — teve evento nos últimos 14 dias
--   foto         — só com foto_consentida (âmbito de consentimento próprio)
--   associacao   — contexto geográfico
-- Continua EXPLICITAMENTE de fora: rating, médias, dimensões, evolução %,
-- qualquer número derivado de avaliações. Filtros de elegibilidade
-- inalterados (visivel_publico + consentido + não oculto + não revogado).
-- Ordenação: mais percurso primeiro (eventos desc), depois nome.
-- Validado em dry-run (2026-07-11): shape novo com contagens certas contra
-- os atletas públicos reais; campos proibidos ausentes; anon mantém acesso.
-- ============================================================================

create or replace function public.ytb_montra()
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  return coalesce((
    select jsonb_agg(linha order by (linha->>'eventos')::int desc, linha->>'nome')
    from (
      select jsonb_build_object(
        'nome', a.nome,
        'posicao', a.posicao_principal,
        'escalao', a.escalao,
        'clube', a.clube_actual,
        'associacao', a.associacao,
        'foto', case when coalesce(a.foto_consentida,false) then a.foto_path else null end,
        'desde', (select min(date_part('year', e.criado_em))::int from public.atleta_eventos e where e.atleta_id = a.id),
        'epocas', (select count(distinct date_part('year', e.criado_em)) from public.atleta_eventos e where e.atleta_id = a.id),
        'eventos', (select count(*) from public.atleta_eventos e where e.atleta_id = a.id),
        'observadores', (select count(distinct e.fonte) from public.atleta_eventos e where e.atleta_id = a.id and e.origem = 'observado'),
        'verificacao', (select p.nivel_verificacao from public.atleta_passaporte p where p.atleta_id = a.id),
        'marcos', (
          select coalesce(jsonb_agg(m), '[]'::jsonb) from (
            select jsonb_build_object('titulo', e.titulo, 'em', e.criado_em) as m
            from public.atleta_eventos e
            where e.atleta_id = a.id and e.categoria = 'marco' and e.titulo is not null
              and e.tipo in ('inscricao','marco_sequencia','epoca_registada','interesse_clube')
            order by e.criado_em desc limit 2) s),
        'ativo', exists (select 1 from public.atleta_eventos e where e.atleta_id = a.id and e.criado_em > now() - interval '14 days')
      ) as linha
      from public.atletas_360 a
      where coalesce(a.visivel_publico,false) = true
        and a.consentido_em is not null
        and coalesce(a.oculto_pelo_responsavel,false) = false
        and coalesce(a.estado,'') <> 'revogado'
    ) t
  ), '[]'::jsonb);
end $$;

grant execute on function public.ytb_montra() to anon, authenticated;
