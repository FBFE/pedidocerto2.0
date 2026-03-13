-- Adicionar colunas de itens ao DFD
ALTER TABLE public.dfd 
ADD COLUMN IF NOT EXISTS categoria_itens TEXT,
ADD COLUMN IF NOT EXISTS classificacao_renem TEXT,
ADD COLUMN IF NOT EXISTS itens JSONB DEFAULT '[]'::jsonb;
