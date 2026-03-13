-- Novos campos: DGA (quando Comissionado) e Data do Vencimento do Contrato (quando Contrato)
-- O nome da coluna deve ser data_vencimento_contrato (não date_vencimento_contrato).
ALTER TABLE public.usuarios
  ADD COLUMN IF NOT EXISTS dga text,
  ADD COLUMN IF NOT EXISTS data_vencimento_contrato date;

-- Se você criou a coluna com nome errado (date_vencimento_contrato), descomente e execute:
-- ALTER TABLE public.usuarios RENAME COLUMN date_vencimento_contrato TO data_vencimento_contrato;
