-- Atualização: data da última modificação + histórico de modificações.
-- Execute no SQL Editor do Supabase (após CUSTO_UNIDADE_IMPORTACAO.sql).

-- Coluna de última alteração
ALTER TABLE custo_unidade_importacao
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

COMMENT ON COLUMN custo_unidade_importacao.updated_at IS 'Data da última alteração (edição) dos dados';

-- Tabela de histórico de modificações
CREATE TABLE IF NOT EXISTS custo_unidade_importacao_historico (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  importacao_id UUID NOT NULL REFERENCES custo_unidade_importacao(id) ON DELETE CASCADE,
  ocorrido_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  tipo TEXT NOT NULL CHECK (tipo IN ('criacao', 'edicao', 'reimportacao')),
  descricao TEXT,
  usuario_email TEXT
);

CREATE INDEX IF NOT EXISTS idx_custo_unidade_historico_importacao
  ON custo_unidade_importacao_historico(importacao_id);

COMMENT ON TABLE custo_unidade_importacao_historico IS 'Histórico de importação e edições do relatório de custo';
