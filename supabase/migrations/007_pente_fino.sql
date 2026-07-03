-- MIGRAÇÃO 007 · PENTE FINO (aplicada em prod)
revoke insert, update, delete on public.familia_avaliacoes from anon, authenticated;
revoke select on public.familia_avaliacoes from anon;
drop policy if exists rate_limit_acesso on public.atletas_360_rate_limit;
delete from public.atleta_eventos where atleta_id is null;
do $$ begin
  begin
    alter table public.atleta_eventos alter column atleta_id set not null;
  exception when others then null;
  end;
end $$;
