-- Tabela para armazenar importações de relatório de custo da unidade (planilha CSV).
-- Execute no SQL Editor do Supabase.

CREATE TABLE IF NOT EXISTS custo_unidade_importacao (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unidade_id UUID NOT NULL REFERENCES unidades_hospitalares(id) ON DELETE CASCADE,
  ano_competencia INT NOT NULL,
  nome_unidade_planilha TEXT,
  dados_json JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_custo_unidade_importacao_unidade
  ON custo_unidade_importacao(unidade_id);
CREATE INDEX IF NOT EXISTS idx_custo_unidade_importacao_ano
  ON custo_unidade_importacao(unidade_id, ano_competencia);

COMMENT ON TABLE custo_unidade_importacao IS 'Importações do Relatório Custo Total da Unidade (CSV Apurasus)';
