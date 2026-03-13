-- ============================================================
-- ATUALIZAÇÃO: Classificação da ata + Padronização de itens
-- Execute no SQL Editor do Supabase (após create_banco_atas.sql).
-- ============================================================

-- 1) Classificação da ata (Medicamento, Equipamento, Material/Procedimento)
ALTER TABLE atas
ADD COLUMN IF NOT EXISTS classificacao TEXT;

-- 2) Permitir mesma ata registrada por credor (sub-ata): remove UNIQUE do número
ALTER TABLE atas
DROP CONSTRAINT IF EXISTS uq_atas_numero_controle;

-- 3) Padronização do item: vínculo com banco (CATMED/RENEM/SIGTAP) ou novo por ata
ALTER TABLE ata_credor_itens
ADD COLUMN IF NOT EXISTS codigo_item_padrao TEXT;

ALTER TABLE ata_credor_itens
ADD COLUMN IF NOT EXISTS tipo_item_padrao TEXT;

ALTER TABLE ata_credor_itens
ADD COLUMN IF NOT EXISTS descricao_item_padrao TEXT;
