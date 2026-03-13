-- Histórico de importações SGS (Indicasus). Execute após INDICASUS_IMPORTACAO.sql.

CREATE TABLE IF NOT EXISTS indicasus_importacao_historico (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  importacao_id UUID NOT NULL REFERENCES indicasus_importacao(id) ON DELETE CASCADE,
  ocorrido_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  tipo TEXT NOT NULL CHECK (tipo IN ('criacao', 'edicao', 'reimportacao')),
  descricao TEXT,
  usuario_email TEXT
);

CREATE INDEX IF NOT EXISTS idx_indicasus_importacao_historico_importacao
  ON indicasus_importacao_historico(importacao_id);

COMMENT ON TABLE indicasus_importacao_historico IS 'Histórico de importações e reimportações SGS (Indicasus)';
