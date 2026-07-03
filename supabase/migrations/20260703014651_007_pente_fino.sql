-- ============================================================================
-- MIGRAÇÃO 007 · PENTE FINO (fecho das 3 pontas da verificação viva)
-- ============================================================================

-- 1) familia_avaliacoes: última tabela com escrita direta concedida.
--    Zero páginas vivas a usam; a policy familia_aval_dono fica (leitura do
--    encarregado), mas escrita passa a ser só por RPC futura.
revoke insert, update, delete on public.familia_avaliacoes from anon, authenticated;
revoke select on public.familia_avaliacoes from anon;

-- 2) última policy ALL/USING(true): rate-limit sem restrição alguma.
--    As escritas já estavam revogadas; a policy era peso morto perigoso.
drop policy if exists rate_limit_acesso on public.atletas_360_rate_limit;

-- 3) eventos-fantasma sem titular (atleta_id NULL, herdados da espinha antiga,
--    antes do NOT NULL/FK). Sem sujeito não há proveniência nem RGPD — é ruído
--    estrutural que criava um "passaporte fantasma" na view. Remoção documentada.
delete from public.atleta_eventos where atleta_id is null;

-- 4) impedir que voltem: NOT NULL se ainda não estiver garantido
do $$ begin
  begin
    alter table public.atleta_eventos alter column atleta_id set not null;
  exception when others then null;  -- já era NOT NULL, ou constraint concorrente
  end;
end $$;