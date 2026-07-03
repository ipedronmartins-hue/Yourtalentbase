-- Patch 000b: colunas que o ytb_treino_feedback (001) e a view atleta_passaporte
-- esperam em familia_treinos e que a produção não tinha. Idempotente, sem dados tocados.
alter table public.familia_treinos add column if not exists confianca int;
alter table public.familia_treinos add column if not exists tempo numeric;
alter table public.familia_treinos add column if not exists flags jsonb;