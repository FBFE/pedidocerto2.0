-- ============================================================
-- Cadastro de fornecedores e representantes.
-- CNPJ único; representante não pode duplicar (CPF único por fornecedor).
-- Execute no Supabase: SQL Editor > New query > Cole e Run.
-- ============================================================

-- 1. Tabela fornecedores (banco de fornecedores)
CREATE TABLE IF NOT EXISTS public.fornecedores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cnpj TEXT NOT NULL UNIQUE,
  razao_social TEXT,
  nome_fantasia TEXT,
  endereco TEXT,
  contato TEXT,
  email TEXT,
  situacao TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_fornecedores_cnpj ON public.fornecedores(cnpj);

-- 1.1 E-mail da empresa (executar se a tabela já existir sem a coluna)
ALTER TABLE public.fornecedores ADD COLUMN IF NOT EXISTS email TEXT;

-- 2. Tabela representantes do fornecedor (um fornecedor pode ter vários; CPF não duplica por fornecedor)
CREATE TABLE IF NOT EXISTS public.fornecedor_representantes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fornecedor_id UUID NOT NULL REFERENCES public.fornecedores(id) ON DELETE CASCADE,
  nome TEXT,
  cpf TEXT,
  rg TEXT,
  contato TEXT,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(fornecedor_id, cpf)
);

CREATE INDEX IF NOT EXISTS idx_fornecedor_representantes_fornecedor ON public.fornecedor_representantes(fornecedor_id);

-- 3. Vincular ata_credores ao fornecedor e ao representante (opcional)
ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS fornecedor_id UUID REFERENCES public.fornecedores(id) ON DELETE SET NULL;
ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS representante_id UUID REFERENCES public.fornecedor_representantes(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_ata_credores_fornecedor ON public.ata_credores(fornecedor_id);

COMMENT ON TABLE public.fornecedores IS 'Cadastro de fornecedores (CNPJ único); dados podem vir da BrasilAPI';
COMMENT ON TABLE public.fornecedor_representantes IS 'Representantes do fornecedor; CPF não pode duplicar no mesmo fornecedor';
