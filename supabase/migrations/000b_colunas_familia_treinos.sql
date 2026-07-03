-- Patch 000b (aplicado em prod): colunas que o ytb_treino_feedback e a view esperam
alter table public.familia_treinos add column if not exists confianca int;
alter table public.familia_treinos add column if not exists tempo numeric;
alter table public.familia_treinos add column if not exists flags jsonb;
