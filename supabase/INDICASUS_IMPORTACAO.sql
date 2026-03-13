-- Tabela para armazenar importações de planilha Indicasus (.xls/.xlsx) da unidade.
-- Execute no SQL Editor do Supabase.

CREATE TABLE IF NOT EXISTS indicasus_importacao (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unidade_id UUID NOT NULL REFERENCES unidades_hospitalares(id) ON DELETE CASCADE,
  ano_referencia INT NOT NULL,
  nome_unidade_planilha TEXT,
  dados_json JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_indicasus_importacao_unidade
  ON indicasus_importacao(unidade_id);
CREATE INDEX IF NOT EXISTS idx_indicasus_importacao_ano
  ON indicasus_importacao(unidade_id, ano_referencia);

COMMENT ON TABLE indicasus_importacao IS 'Importações de planilha Indicasus (ex.: Relatorio - Alta Floresta 2018.xls) por unidade';
