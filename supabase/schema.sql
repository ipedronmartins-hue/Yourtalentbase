-- ================================================================
-- BALNEÁRIO · YourTalentBase — Schema SQL Completo
-- Supabase PostgreSQL · RLS activo em todas as tabelas
-- ================================================================

-- ── EXTENSÕES ────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================================
-- 1. CLUBES E UTILIZADORES
-- ================================================================

CREATE TABLE IF NOT EXISTS clubes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome        TEXT NOT NULL,
  abreviatura TEXT,
  nif         TEXT,                         -- Para recibos
  morada      TEXT,
  logo_url    TEXT,
  cor_primaria TEXT DEFAULT '#D4AF37',
  plano       TEXT DEFAULT 'starter',       -- starter / pro / elite
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Perfis de utilizador (extends auth.users do Supabase)
CREATE TABLE IF NOT EXISTS perfis (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  clube_id    UUID REFERENCES clubes(id),
  nome        TEXT NOT NULL,
  role        TEXT NOT NULL CHECK (role IN ('admin','secretaria','team_manager','treinador')),
  escalao_id  UUID,                         -- Ligado a escalao se role=treinador/team_manager
  ativo       BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- 2. ESCALÕES
-- ================================================================

CREATE TABLE IF NOT EXISTS escaloes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  clube_id    UUID REFERENCES clubes(id) ON DELETE CASCADE,
  nome        TEXT NOT NULL,               -- "Sub-12", "Sub-15"
  formato     TEXT,                        -- "Fut9", "Fut11"
  treinador_id UUID REFERENCES perfis(id),
  team_manager_id UUID REFERENCES perfis(id),
  mensalidade_valor NUMERIC(8,2) DEFAULT 25.00,
  ativo       BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- 3. ATLETAS
-- ================================================================

CREATE TABLE IF NOT EXISTS atletas (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  clube_id        UUID REFERENCES clubes(id) ON DELETE CASCADE,
  escalao_id      UUID REFERENCES escaloes(id),
  nome            TEXT NOT NULL,
  nome_completo   TEXT,
  data_nascimento DATE,
  morada          TEXT,
  contacto_pai    TEXT,
  contacto_mae    TEXT,
  email_familia   TEXT,
  posicao         TEXT,
  pe_preferido    TEXT CHECK (pe_preferido IN ('Direito','Esquerdo','Ambidestro')),
  numero_camisola INTEGER,
  altura_cm       INTEGER,
  peso_kg         NUMERIC(5,1),
  nif_atleta      TEXT,
  zerozero_url    TEXT,
  foto_url        TEXT,
  desde           DATE,                    -- Data de inscrição no clube
  nivel_ytb       TEXT,                    -- A/B/C/D (confidencial)
  ativo           BOOLEAN DEFAULT TRUE,
  notas           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- 4. PAGAMENTOS / MENSALIDADES
-- ================================================================

CREATE TABLE IF NOT EXISTS pagamentos (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  clube_id        UUID REFERENCES clubes(id) ON DELETE CASCADE,
  atleta_id       UUID REFERENCES atletas(id) ON DELETE CASCADE,
  escalao_id      UUID REFERENCES escaloes(id),
  ano             INTEGER NOT NULL,
  mes             INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
  valor           NUMERIC(8,2) NOT NULL,
  estado          TEXT DEFAULT 'pendente' CHECK (estado IN ('pendente','pago','isento','devolvido')),
  data_pagamento  DATE,
  metodo          TEXT,                    -- "MB Way", "Transferência", "Numerário"
  referencia      TEXT,                    -- Referência MB ou comprovativo
  recibo_num      TEXT UNIQUE,             -- Ex: REC-2026-00001
  notas           TEXT,
  registado_por   UUID REFERENCES perfis(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(atleta_id, ano, mes)
);

-- Gerar número de recibo automático
CREATE SEQUENCE IF NOT EXISTS recibo_seq START 1;
CREATE OR REPLACE FUNCTION gerar_recibo_num() RETURNS TEXT AS $$
BEGIN
  RETURN 'REC-' || EXTRACT(YEAR FROM NOW())::TEXT || '-' || LPAD(nextval('recibo_seq')::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- 5. CONVOCATÓRIAS
-- ================================================================

CREATE TABLE IF NOT EXISTS convocatorias (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  escalao_id      UUID REFERENCES escaloes(id) ON DELETE CASCADE,
  tipo            TEXT DEFAULT 'jogo' CHECK (tipo IN ('jogo','torneio','treino_especial')),
  adversario      TEXT,
  data_evento     TIMESTAMPTZ NOT NULL,
  local           TEXT,
  hora_concentracao TIME,
  equipamento     TEXT,                    -- "Principal", "Alternativo"
  notas           TEXT,
  criado_por      UUID REFERENCES perfis(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS convocatoria_atletas (
  convocatoria_id UUID REFERENCES convocatorias(id) ON DELETE CASCADE,
  atleta_id       UUID REFERENCES atletas(id) ON DELETE CASCADE,
  posicao_jogo    TEXT,
  titular         BOOLEAN DEFAULT FALSE,
  presenca        TEXT CHECK (presenca IN ('confirmado','duvida','ausente','lesionado')),
  PRIMARY KEY (convocatoria_id, atleta_id)
);

-- ================================================================
-- 6. TREINOS E PRESENÇAS
-- ================================================================

CREATE TABLE IF NOT EXISTS treinos (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  escalao_id      UUID REFERENCES escaloes(id) ON DELETE CASCADE,
  data_treino     DATE NOT NULL,
  duracao_min     INTEGER DEFAULT 90,
  objetivo        TEXT,
  intensidade     INTEGER CHECK (intensidade BETWEEN 1 AND 5),
  tipos_trabalho  TEXT[],                  -- ["Ofensivo","Defensivo","Físico"]
  dinamicas       TEXT[],                  -- ["Rondo","Jogo Reduzido"]
  condicoes       TEXT,                    -- "Campo molhado", "Indoor"
  notas           TEXT,
  criado_por      UUID REFERENCES perfis(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS presencas (
  treino_id       UUID REFERENCES treinos(id) ON DELETE CASCADE,
  atleta_id       UUID REFERENCES atletas(id) ON DELETE CASCADE,
  estado          TEXT CHECK (estado IN ('presente','falta','lesionado','justificado')),
  intensidade_individual INTEGER CHECK (intensidade_individual BETWEEN 1 AND 5),
  nota_performance TEXT,                   -- Nota breve do treinador
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (treino_id, atleta_id)
);

-- ================================================================
-- 7. ESTATÍSTICAS DE JOGO
-- ================================================================

CREATE TABLE IF NOT EXISTS estatisticas (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  convocatoria_id UUID REFERENCES convocatorias(id) ON DELETE CASCADE,
  atleta_id       UUID REFERENCES atletas(id) ON DELETE CASCADE,
  minutos         INTEGER DEFAULT 0,
  golos           INTEGER DEFAULT 0,
  assistencias    INTEGER DEFAULT 0,
  cartao_amarelo  BOOLEAN DEFAULT FALSE,
  cartao_vermelho BOOLEAN DEFAULT FALSE,
  nota_desempenho INTEGER CHECK (nota_desempenho BETWEEN 1 AND 10),
  notas           TEXT,
  registado_por   UUID REFERENCES perfis(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(convocatoria_id, atleta_id)
);

-- ================================================================
-- 8. SCOUT REPORTS
-- ================================================================

CREATE TABLE IF NOT EXISTS relatorios (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  clube_id        UUID REFERENCES clubes(id),
  atleta_id       UUID REFERENCES atletas(id),
  scout           TEXT NOT NULL,
  atleta          TEXT NOT NULL,           -- Nome (desnormalizado para relatórios externos)
  clube           TEXT,
  categoria       TEXT,
  posicao         TEXT,
  epoca           TEXT,
  scores          JSONB,                   -- {t1: 4, t2: 3, ...}
  dados           JSONB,                   -- Dados biométricos e contexto
  relatorio_texto TEXT,
  decisao         TEXT,
  rendimento      TEXT,
  prazo           TEXT,
  media_geral     NUMERIC(4,2),
  num_relatorio   TEXT UNIQUE,             -- YTB-2026-12345
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- 9. TREINO EXTRA (MODULE PARA PAIS/ATLETAS)
-- ================================================================

CREATE TABLE IF NOT EXISTS subscricoes_treino (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  atleta_id       UUID REFERENCES atletas(id),
  treinador_id    UUID REFERENCES perfis(id),
  escalao_id      UUID REFERENCES escaloes(id),
  estado          TEXT DEFAULT 'ativa' CHECK (estado IN ('ativa','cancelada','pausada')),
  plano           TEXT DEFAULT 'mensal',
  valor_mensal    NUMERIC(8,2) DEFAULT 9.99,
  data_inicio     DATE DEFAULT CURRENT_DATE,
  data_fim        DATE,
  stripe_sub_id   TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- 10. COACH WALLET — Comissões do Treinador
-- ================================================================

CREATE TABLE IF NOT EXISTS comissoes (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  treinador_id    UUID REFERENCES perfis(id) ON DELETE CASCADE,
  subscricao_id   UUID REFERENCES subscricoes_treino(id),
  atleta_id       UUID REFERENCES atletas(id),
  mes             INTEGER,
  ano             INTEGER,
  valor           NUMERIC(8,2) DEFAULT 5.00,  -- 5€ por subscrição activa
  estado          TEXT DEFAULT 'pendente' CHECK (estado IN ('pendente','paga','cancelada')),
  data_pagamento  DATE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- 11. SUGESTÕES / INSCRIÇÕES (Landing Page)
-- ================================================================

CREATE TABLE IF NOT EXISTS sugestoes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome        TEXT,
  idade       INTEGER,
  clube       TEXT,
  escalao     TEXT,
  posicao     TEXT,
  contacto    TEXT,
  zerozero    TEXT,
  descricao   TEXT,
  estado      TEXT DEFAULT 'Novo' CHECK (estado IN ('Novo','Em análise','Aceite','Recusado')),
  notas_admin TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- ROW LEVEL SECURITY (RLS)
-- ================================================================

-- Activar RLS em todas as tabelas
ALTER TABLE clubes               ENABLE ROW LEVEL SECURITY;
ALTER TABLE perfis               ENABLE ROW LEVEL SECURITY;
ALTER TABLE escaloes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE atletas              ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagamentos           ENABLE ROW LEVEL SECURITY;
ALTER TABLE convocatorias        ENABLE ROW LEVEL SECURITY;
ALTER TABLE convocatoria_atletas ENABLE ROW LEVEL SECURITY;
ALTER TABLE treinos              ENABLE ROW LEVEL SECURITY;
ALTER TABLE presencas            ENABLE ROW LEVEL SECURITY;
ALTER TABLE estatisticas         ENABLE ROW LEVEL SECURITY;
ALTER TABLE relatorios           ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscricoes_treino   ENABLE ROW LEVEL SECURITY;
ALTER TABLE comissoes            ENABLE ROW LEVEL SECURITY;

-- Helper: obter clube_id do utilizador autenticado
CREATE OR REPLACE FUNCTION meu_clube_id() RETURNS UUID AS $$
  SELECT clube_id FROM perfis WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- Helper: obter role do utilizador
CREATE OR REPLACE FUNCTION meu_role() RETURNS TEXT AS $$
  SELECT role FROM perfis WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- Helper: obter escalao_id do utilizador
CREATE OR REPLACE FUNCTION meu_escalao_id() RETURNS UUID AS $$
  SELECT escalao_id FROM perfis WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- ── POLÍTICAS: ATLETAS ────────────────────────────────────────────
-- Admin/Secretaria: vê todos os atletas do clube
CREATE POLICY "atletas_admin_read" ON atletas FOR SELECT
  USING (clube_id = meu_clube_id() AND meu_role() IN ('admin','secretaria'));

CREATE POLICY "atletas_admin_write" ON atletas FOR ALL
  USING (clube_id = meu_clube_id() AND meu_role() IN ('admin','secretaria'));

-- Treinador: vê apenas atletas do seu escalão
CREATE POLICY "atletas_treinador_read" ON atletas FOR SELECT
  USING (escalao_id = meu_escalao_id() AND meu_role() = 'treinador');

-- Team Manager: vê atletas do seu escalão
CREATE POLICY "atletas_tm_read" ON atletas FOR SELECT
  USING (escalao_id = meu_escalao_id() AND meu_role() = 'team_manager');

-- ── POLÍTICAS: PAGAMENTOS ─────────────────────────────────────────
-- Só admin/secretaria pode ver e editar pagamentos
CREATE POLICY "pagamentos_secretaria" ON pagamentos FOR ALL
  USING (clube_id = meu_clube_id() AND meu_role() IN ('admin','secretaria'));

-- ── POLÍTICAS: PRESENÇAS ──────────────────────────────────────────
-- Treinador: regista e vê presenças do seu escalão
CREATE POLICY "presencas_treinador" ON presencas FOR ALL
  USING (
    treino_id IN (SELECT id FROM treinos WHERE escalao_id = meu_escalao_id())
    AND meu_role() = 'treinador'
  );

-- Admin: vê tudo
CREATE POLICY "presencas_admin" ON presencas FOR SELECT
  USING (meu_role() IN ('admin','secretaria'));

-- ── POLÍTICAS: TREINOS ────────────────────────────────────────────
CREATE POLICY "treinos_treinador" ON treinos FOR ALL
  USING (escalao_id = meu_escalao_id() AND meu_role() = 'treinador');

CREATE POLICY "treinos_admin" ON treinos FOR SELECT
  USING (
    escalao_id IN (SELECT id FROM escaloes WHERE clube_id = meu_clube_id())
    AND meu_role() IN ('admin','secretaria')
  );

-- ── POLÍTICAS: CONVOCATÓRIAS ──────────────────────────────────────
CREATE POLICY "convo_tm" ON convocatorias FOR ALL
  USING (escalao_id = meu_escalao_id() AND meu_role() = 'team_manager');

CREATE POLICY "convo_admin" ON convocatorias FOR SELECT
  USING (
    escalao_id IN (SELECT id FROM escaloes WHERE clube_id = meu_clube_id())
    AND meu_role() IN ('admin','secretaria')
  );

-- ── POLÍTICAS: COMISSÕES ──────────────────────────────────────────
-- Treinador só vê as suas próprias comissões
CREATE POLICY "comissoes_treinador" ON comissoes FOR SELECT
  USING (treinador_id = auth.uid());

CREATE POLICY "comissoes_admin" ON comissoes FOR ALL
  USING (meu_role() IN ('admin','secretaria'));

-- ── POLÍTICAS: SCOUT REPORTS ──────────────────────────────────────
-- Supabase anon key pode inserir (gerado pela API)
CREATE POLICY "relatorios_insert" ON relatorios FOR INSERT
  WITH CHECK (TRUE);

CREATE POLICY "relatorios_admin_read" ON relatorios FOR SELECT
  USING (meu_role() IN ('admin','secretaria') OR auth.uid() IS NOT NULL);

-- ── POLÍTICAS: SUGESTÕES ──────────────────────────────────────────
ALTER TABLE sugestoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sugestoes_insert" ON sugestoes FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "sugestoes_admin" ON sugestoes FOR ALL USING (meu_role() IN ('admin','secretaria'));

-- ================================================================
-- VIEWS ÚTEIS
-- ================================================================

-- View: Mapa de mensalidades (todos os meses)
CREATE OR REPLACE VIEW v_mapa_mensalidades AS
SELECT
  a.id AS atleta_id,
  a.nome,
  a.escalao_id,
  e.nome AS escalao_nome,
  p.ano,
  p.mes,
  p.valor,
  p.estado,
  p.data_pagamento,
  p.recibo_num
FROM atletas a
JOIN escaloes e ON a.escalao_id = e.id
LEFT JOIN pagamentos p ON p.atleta_id = a.id
WHERE a.ativo = TRUE
ORDER BY e.nome, a.nome, p.ano, p.mes;

-- View: Assiduidade por atleta
CREATE OR REPLACE VIEW v_assiduidade AS
SELECT
  a.id AS atleta_id,
  a.nome,
  a.escalao_id,
  COUNT(pr.treino_id) FILTER (WHERE pr.estado = 'presente') AS presenças,
  COUNT(pr.treino_id) AS total_treinos,
  ROUND(COUNT(pr.treino_id) FILTER (WHERE pr.estado = 'presente')::NUMERIC /
    NULLIF(COUNT(pr.treino_id), 0) * 100, 1) AS taxa_presença
FROM atletas a
LEFT JOIN presencas pr ON pr.atleta_id = a.id
GROUP BY a.id, a.nome, a.escalao_id;

-- View: Coach Wallet — sumário de comissões por treinador
CREATE OR REPLACE VIEW v_coach_wallet AS
SELECT
  p.id AS treinador_id,
  p.nome AS treinador_nome,
  COUNT(c.id) FILTER (WHERE c.estado = 'paga') AS subscricoes_pagas,
  SUM(c.valor) FILTER (WHERE c.estado = 'paga') AS total_recebido,
  COUNT(c.id) FILTER (WHERE c.estado = 'pendente') AS subscricoes_pendentes,
  SUM(c.valor) FILTER (WHERE c.estado = 'pendente') AS total_pendente
FROM perfis p
LEFT JOIN comissoes c ON c.treinador_id = p.id
WHERE p.role = 'treinador'
GROUP BY p.id, p.nome;

-- ================================================================
-- FUNÇÕES AUXILIARES
-- ================================================================

-- Calcular devedores (atletas com 1+ mensalidades em atraso)
CREATE OR REPLACE FUNCTION devedores(p_escalao_id UUID DEFAULT NULL)
RETURNS TABLE(atleta_id UUID, nome TEXT, meses_atraso INTEGER, valor_total NUMERIC) AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.nome,
    COUNT(p.id)::INTEGER,
    SUM(p.valor)
  FROM atletas a
  JOIN pagamentos p ON p.atleta_id = a.id
  WHERE p.estado = 'pendente'
    AND (p_escalao_id IS NULL OR a.escalao_id = p_escalao_id)
  GROUP BY a.id, a.nome
  ORDER BY COUNT(p.id) DESC;
END;
$$ LANGUAGE plpgsql;

-- Gerar recibo automático ao marcar pagamento como pago
CREATE OR REPLACE FUNCTION trigger_gerar_recibo()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.estado = 'pago' AND OLD.estado != 'pago' AND NEW.recibo_num IS NULL THEN
    NEW.recibo_num := gerar_recibo_num();
    NEW.data_pagamento := CURRENT_DATE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_recibo
  BEFORE UPDATE ON pagamentos
  FOR EACH ROW EXECUTE FUNCTION trigger_gerar_recibo();

-- Gerar comissões automaticamente quando subscrição de treino é criada/activada
CREATE OR REPLACE FUNCTION trigger_criar_comissao()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.estado = 'ativa' AND NEW.treinador_id IS NOT NULL THEN
    INSERT INTO comissoes (treinador_id, subscricao_id, atleta_id, mes, ano, valor)
    VALUES (
      NEW.treinador_id,
      NEW.id,
      NEW.atleta_id,
      EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER,
      EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
      5.00
    )
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_comissao
  AFTER INSERT OR UPDATE ON subscricoes_treino
  FOR EACH ROW EXECUTE FUNCTION trigger_criar_comissao();

-- ================================================================
-- DADOS INICIAIS (seed para desenvolvimento)
-- ================================================================

-- Exemplo de escalão para teste
-- INSERT INTO clubes (nome, abreviatura, nif, morada) VALUES ('Gondomar SC', 'GSC', '500123456', 'Gondomar, Porto');
