-- ============================================================
-- BANCO DE ATAS (PNCP) - Script para Supabase SQL Editor
-- Execute este script no SQL Editor do seu projeto Supabase.
-- ============================================================

-- Tabela principal: atas (cabeçalho da ata registrada)
CREATE TABLE IF NOT EXISTS atas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  numero_controle_pncp_ata TEXT NOT NULL,
  numero_controle_pncp_compra TEXT NOT NULL,
  orgao TEXT,
  objeto TEXT,
  vigencia_inicio TEXT,
  vigencia_fim TEXT,
  CONSTRAINT uq_atas_numero_controle UNIQUE (numero_controle_pncp_ata)
);

-- Credores por ata (fornecedor/credor que ganhou itens na ata)
CREATE TABLE IF NOT EXISTS ata_credores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ata_id UUID NOT NULL REFERENCES atas(id) ON DELETE CASCADE,
  cnpj TEXT,
  razao_social TEXT
);

CREATE INDEX IF NOT EXISTS idx_ata_credores_ata_id ON ata_credores(ata_id);

-- Itens por credor (item que o credor é responsável + quantidade e valores)
CREATE TABLE IF NOT EXISTS ata_credor_itens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ata_credor_id UUID NOT NULL REFERENCES ata_credores(id) ON DELETE CASCADE,
  numero_item INTEGER NOT NULL,
  descricao TEXT,
  quantidade NUMERIC(18,4) NOT NULL DEFAULT 0,
  valor_unitario NUMERIC(18,4) NOT NULL DEFAULT 0,
  valor_total NUMERIC(18,4) NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_ata_credor_itens_ata_credor_id ON ata_credor_itens(ata_credor_id);

-- Habilitar RLS (Row Level Security) se quiser controle por usuário depois
-- ALTER TABLE atas ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE ata_credores ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE ata_credor_itens ENABLE ROW LEVEL SECURITY;
