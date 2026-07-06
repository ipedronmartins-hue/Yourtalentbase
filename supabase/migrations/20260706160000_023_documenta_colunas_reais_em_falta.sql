-- ============================================================================
-- MIGRAÇÃO 023 · DOCUMENTA COLUNAS REAIS EM FALTA NAS MIGRAÇÕES LOCAIS
-- Sem efeito funcional em produção — todas estas colunas já existem lá
-- (confirmado por information_schema.columns antes de escrever), por isso
-- todos os "add column if not exists" abaixo são no-op. O objetivo é só
-- corrigir o MODELO LOCAL, que nunca as descreveu (drift anterior à
-- disciplina de migrações, o mesmo padrão já encontrado em
-- atletas_360_pedidos_contacto na migração 022).
--
-- Encontrado pela nova ferramenta tests/check-schema-refs.js (heurística
-- que cruza .from()/.select()/.eq() do código contra o esquema das
-- migrações) — todos os 13 avisos que deu foram verificados um a um contra
-- produção antes de aqui entrarem: nenhum é bug de código, são só colunas
-- reais que faltavam no modelo local.
-- ============================================================================

alter table public.perfis add column if not exists id uuid references auth.users(id);

alter table public.atletas_360 add column if not exists created_at timestamptz default now();

alter table public.atletas_360_pedidos_contacto add column if not exists enviado_em timestamptz default now();
alter table public.atletas_360_pedidos_contacto add column if not exists responsavel_nome text;
alter table public.atletas_360_pedidos_contacto add column if not exists responsavel_email text;
alter table public.atletas_360_pedidos_contacto add column if not exists motivo text;

alter table public.atletas_360_clubes_subscritores add column if not exists created_at timestamptz default now();

alter table public.atletas_360_historico add column if not exists ordem integer;

alter table public.atletas_360_avaliacoes add column if not exists estado text;
alter table public.atletas_360_avaliacoes add column if not exists created_at timestamptz default now();
