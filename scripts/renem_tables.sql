-- Criar tabela de equipamentos baseada no RENEM
CREATE TABLE IF NOT EXISTS public.renem_equipamentos (
  cod_item TEXT PRIMARY KEY,
  item TEXT,
  definicao TEXT,
  classificacao TEXT,
  valor_sugerido NUMERIC,
  item_dolarizado TEXT,
  especificacao_sugerida TEXT,
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Ativar RLS
ALTER TABLE public.renem_equipamentos ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS
CREATE POLICY "Permitir leitura para todos os usuários autenticados" 
ON public.renem_equipamentos FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Permitir inserção e atualização para usuários autenticados" 
ON public.renem_equipamentos FOR INSERT 
TO authenticated 
WITH CHECK (true);

CREATE POLICY "Permitir atualização para usuários autenticados" 
ON public.renem_equipamentos FOR UPDATE 
TO authenticated 
USING (true)
WITH CHECK (true);
