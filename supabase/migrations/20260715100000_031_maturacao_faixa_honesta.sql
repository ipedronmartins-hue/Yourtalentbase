-- ============================================================================
-- MIGRAÇÃO 031 · MATURAÇÃO: FAIXA HONESTA EM VEZ DE PONTO ÚNICO
--
-- BUG (reportado pelo fundador: "a altura estimada dos atletas está demasiado
-- conservadora, espreita atletas que cresceram acima da média dos pais"):
-- _ytb_maturacao (migração 024) usa o
-- método clássico da altura-alvo dos pais (Tanner: (pai+mãe±13)/2) — fórmula
-- correta e é a que a literatura usa, mas é SÓ uma média populacional a partir
-- dos pais; ignora a trajetória de crescimento do próprio atleta. Isso o torna
-- estruturalmente conservador para quem cresce acima da média dos pais.
-- Prova concreta: um atleta real (altura_pai=170, altura_mae=165, ambos reais) dá
-- prevista=(170+165+13)/2=174cm — mas a altura atual dele já é 186cm. O ecrã
-- mostrava "Está a ~107% da altura adulta prevista", o que não faz sentido
-- nenhum e é exatamente o que pareceu "errado" ao fundador.
--
-- Não há forma de tornar este método clinicamente exato sem idade óssea (raio-
-- X de punho, Tanner-Whitehouse/Greulich-Pyle) — fora de alcance para uma
-- plataforma de scouting. A correção honesta não é fingir mais precisão, é
-- comunicar a incerteza real: mostrar uma FAIXA (±9cm, o desvio-padrão típico
-- reportado para este método) em vez de um número único, e assumir
-- explicitamente quando o atleta já ultrapassou a faixa — em vez de mostrar
-- uma "% atingida" acima de 100 como se fosse meta por bater.
--
-- Aditivo: mantém altura_prevista/pct_atingida/faltam_cm como estavam (nada
-- que já lia estes campos parte); acrescenta altura_prevista_min/max e um
-- 'estado' ('a_crescer' | 'na_faixa' | 'acima_da_faixa') para quem quiser a
-- leitura correta.
--
-- Validado em dry-run (2026-07-15) com um atleta real: prevista=174,
-- faixa=165–183, atual=186 → estado='acima_da_faixa' (em vez do nonsense de
-- 107%). Testado também com um atleta jovem normal (atual < min) →
-- 'a_crescer', e um dentro da faixa → 'na_faixa'.
-- ============================================================================

create or replace function public._ytb_maturacao(v_atleta uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  a public.atletas_360;
  v_altura_atual numeric; v_altura_em date;
  v_idade numeric; v_prevista numeric; v_pmin numeric; v_pmax numeric;
  v_estado text; v_pct numeric; v_faltam numeric;
  v_vel numeric; v_n int; v_primeira record; v_ultima record; v_dias numeric;
  v_falta text[] := array[]::text[];
  v_margem constant numeric := 9; -- ±9cm: desvio-padrão típico reportado para o método da altura-alvo dos pais
begin
  select * into a from public.atletas_360 where id = v_atleta;
  if a.id is null then return null; end if;

  -- altura atual: medição mais recente; fallback para a ficha
  select altura_cm, medido_em into v_altura_atual, v_altura_em
    from public.atleta_biometria
   where atleta_id = v_atleta and altura_cm is not null
   order by medido_em desc limit 1;
  if v_altura_atual is null then v_altura_atual := a.altura_cm; end if;

  -- idade decimal (anos)
  if a.ano_nascimento is not null then
    v_idade := round(extract(epoch from age(current_date,
      make_date(a.ano_nascimento, coalesce(a.mes_nascimento,1), coalesce(a.dia_nascimento,1))
    )) / 31557600.0, 1);
  end if;

  -- altura adulta prevista (altura-alvo dos pais, método de Tanner) + faixa honesta
  if a.sexo in ('M','F') and a.altura_pai is not null and a.altura_mae is not null then
    v_prevista := round(case a.sexo
      when 'M' then (a.altura_pai + a.altura_mae + 13) / 2.0
      else          (a.altura_pai + a.altura_mae - 13) / 2.0 end);
    v_pmin := v_prevista - v_margem;
    v_pmax := v_prevista + v_margem;
  end if;

  if v_prevista is not null and v_altura_atual is not null then
    v_pct := round(100.0 * v_altura_atual / v_prevista);
    v_faltam := round(v_prevista - v_altura_atual);
    v_estado := case
      when v_altura_atual > v_pmax then 'acima_da_faixa'
      when v_altura_atual < v_pmin then 'a_crescer'
      else 'na_faixa'
    end;
  end if;

  -- velocidade de crescimento (cm/ano) a partir da primeira e última medição,
  -- se houver pelo menos duas separadas por >= 60 dias
  select count(*) into v_n from public.atleta_biometria
   where atleta_id = v_atleta and altura_cm is not null;
  if v_n >= 2 then
    select altura_cm, medido_em into v_primeira
      from public.atleta_biometria where atleta_id = v_atleta and altura_cm is not null
      order by medido_em asc limit 1;
    select altura_cm, medido_em into v_ultima
      from public.atleta_biometria where atleta_id = v_atleta and altura_cm is not null
      order by medido_em desc limit 1;
    v_dias := v_ultima.medido_em - v_primeira.medido_em;
    if v_dias >= 60 then
      v_vel := round((v_ultima.altura_cm - v_primeira.altura_cm) / (v_dias / 365.25), 1);
    end if;
  end if;

  -- o que ainda falta preencher para a estimativa ficar completa
  if a.sexo is null or a.sexo not in ('M','F') then v_falta := array_append(v_falta, 'sexo'); end if;
  if a.altura_pai is null then v_falta := array_append(v_falta, 'altura_pai'); end if;
  if a.altura_mae is null then v_falta := array_append(v_falta, 'altura_mae'); end if;
  if v_altura_atual is null then v_falta := array_append(v_falta, 'altura_atual'); end if;

  return jsonb_build_object(
    'idade_anos', v_idade,
    'sexo', a.sexo,
    'altura_atual', v_altura_atual,
    'altura_atual_em', v_altura_em,
    'altura_pai', a.altura_pai,
    'altura_mae', a.altura_mae,
    'altura_prevista', v_prevista,
    'altura_prevista_min', v_pmin,
    'altura_prevista_max', v_pmax,
    'estado', v_estado,
    'pct_atingida', v_pct,
    'faltam_cm', v_faltam,
    'velocidade_cm_ano', v_vel,
    'medicoes', v_n,
    'em_falta', to_jsonb(v_falta),
    'metodo', 'Altura-alvo dos pais (Tanner) · faixa provável ±' || v_margem::text || 'cm, não um número exacto'
  );
end $$;
