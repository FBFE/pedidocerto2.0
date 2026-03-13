-- ============================================================
-- Execute este script no Supabase: SQL Editor > New query > Cole e Run
-- ============================================================
-- Adiciona as colunas "dga" e "data_vencimento_contrato" na tabela usuarios.
-- Necessário para o formulário de Regime/Contrato e Data do vencimento do contrato.
-- ============================================================

ALTER TABLE public.usuarios
  ADD COLUMN IF NOT EXISTS dga text,
  ADD COLUMN IF NOT EXISTS data_vencimento_contrato date;
