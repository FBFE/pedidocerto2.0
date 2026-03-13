-- Criar tabela de medicamentos baseada no CATMED
CREATE TABLE IF NOT EXISTS public.catmed_medicamentos (
  codigo_siag TEXT PRIMARY KEY,
  descritivo_tecnico TEXT,
  unidade TEXT,
  exemplos TEXT,
  embalagem TEXT,
  cap TEXT,
  tipo TEXT,
  cb TEXT,
  ce TEXT,
  pe TEXT,
  hosp TEXT,
  ex TEXT,
  codigo_atc TEXT,
  atc TEXT,
  obs TEXT,
  status TEXT DEFAULT 'ativo',
  data_atualizacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Ativar RLS
ALTER TABLE public.catmed_medicamentos ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS
CREATE POLICY "Permitir leitura para todos os usuários autenticados" 
ON public.catmed_medicamentos FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Permitir inserção e atualização para usuários autenticados" 
ON public.catmed_medicamentos FOR INSERT 
TO authenticated 
WITH CHECK (true);

CREATE POLICY "Permitir atualização para usuários autenticados" 
ON public.catmed_medicamentos FOR UPDATE 
TO authenticated 
USING (true)
WITH CHECK (true);
