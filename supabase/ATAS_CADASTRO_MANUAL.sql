-- ============================================================
-- Atas: cadastro manual (substitui fluxo via API PNCP).
-- Execute no Supabase: SQL Editor > New query > Cole e Run.
-- ============================================================

-- 1. Tabela atas (cabeçalho) – cadastro manual
CREATE TABLE IF NOT EXISTS public.atas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,

  -- Usuário que cadastrou
  usuario_cadastrou_nome TEXT,
  usuario_cadastrou_matricula TEXT,

  -- Data/hora do registro (dd/mm/yyyy hh:mm:ss na aplicação; aqui armazena timestamptz)
  data_hora_registro TIMESTAMPTZ DEFAULT now(),

  -- Identificação da ata
  numero_ata TEXT,
  modalidade TEXT CHECK (modalidade IN (
    'ADESÃO CARONA',
    'CHAMAMENTO PÚBLICO',
    'DISPENSA DE LICITAÇÃO',
    'INEXIGIBILIDADE',
    'PREGÃO ELETRÔNICO'
  )),
  numero_modalidade TEXT,

  -- Vigência
  vigencia_inicio DATE,
  vigencia_fim DATE,
  status_vigencia TEXT,

  -- Detalhamento
  detalhamento TEXT,
  ano_competencia INT,
  numero_processo_administrativo TEXT,
  link_processo_administrativo TEXT,

  -- Tipo da ata: medicamento | material | opme (define de qual banco puxar itens)
  tipo_ata TEXT CHECK (tipo_ata IN ('medicamento', 'material', 'opme')),

  -- Campos legados PNCP (opcionais, para compatibilidade)
  numero_controle_pncp_ata TEXT,
  numero_controle_pncp_compra TEXT,
  orgao TEXT,
  objeto TEXT,
  classificacao TEXT
);

-- Permitir NULL em campos PNCP (cadastro manual não tem número PNCP)
ALTER TABLE public.atas ALTER COLUMN numero_controle_pncp_ata DROP NOT NULL;
ALTER TABLE public.atas ALTER COLUMN numero_controle_pncp_compra DROP NOT NULL;

-- Colunas adicionais se a tabela atas já existir (estrutura antiga)
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS usuario_cadastrou_nome TEXT;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS usuario_cadastrou_matricula TEXT;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS data_hora_registro TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS numero_ata TEXT;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS modalidade TEXT;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS numero_modalidade TEXT;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS vigencia_inicio DATE;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS vigencia_fim DATE;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS status_vigencia TEXT;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS detalhamento TEXT;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS ano_competencia INT;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS numero_processo_administrativo TEXT;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS link_processo_administrativo TEXT;
ALTER TABLE public.atas ADD COLUMN IF NOT EXISTS tipo_ata TEXT;

-- 2. Tabela ata_credores (fornecedor/empresa + representante)
CREATE TABLE IF NOT EXISTS public.ata_credores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ata_id UUID NOT NULL REFERENCES public.atas(id) ON DELETE CASCADE,

  -- Empresa
  cnpj TEXT,
  razao_social TEXT,
  nome_fantasia TEXT,
  endereco TEXT,
  contato TEXT,
  situacao TEXT,

  -- Representante
  representante_nome TEXT,
  representante_cpf TEXT,
  representante_rg TEXT,
  representante_contato TEXT,
  representante_email TEXT,

  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS nome_fantasia TEXT;
ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS endereco TEXT;
ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS contato TEXT;
ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS situacao TEXT;
ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS representante_nome TEXT;
ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS representante_cpf TEXT;
ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS representante_rg TEXT;
ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS representante_contato TEXT;
ALTER TABLE public.ata_credores ADD COLUMN IF NOT EXISTS representante_email TEXT;

CREATE INDEX IF NOT EXISTS idx_ata_credores_ata_id ON public.ata_credores(ata_id);

-- 3. Tabela ata_credor_itens (itens vinculados ao credor – do banco medicamento/material/opme)
CREATE TABLE IF NOT EXISTS public.ata_credor_itens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ata_credor_id UUID NOT NULL REFERENCES public.ata_credores(id) ON DELETE CASCADE,

  numero_item INT DEFAULT 0,
  descricao TEXT,
  quantidade DOUBLE PRECISION DEFAULT 0,
  valor_unitario DOUBLE PRECISION DEFAULT 0,
  valor_total DOUBLE PRECISION DEFAULT 0,

  -- Vinculação ao banco (catmed / renem / sigtap)
  codigo_item_padrao TEXT,
  tipo_item_padrao TEXT,
  descricao_item_padrao TEXT,

  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ata_credor_itens_ata_credor_id ON public.ata_credor_itens(ata_credor_id);

-- 4. Banco de Marcas/Fabricantes (evitar duplicatas; auditoria de cadastro)
CREATE TABLE IF NOT EXISTS public.marcas_fabricantes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  usuario_cadastrou_nome TEXT,
  usuario_cadastrou_matricula TEXT,
  data_hora_registro TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  CONSTRAINT marcas_fabricantes_nome_unico UNIQUE (nome)
);

CREATE INDEX IF NOT EXISTS idx_marcas_fabricantes_nome ON public.marcas_fabricantes(LOWER(TRIM(nome)));

-- 5. Banco de Unidades de Medida (detalhes e categorias)
CREATE TABLE IF NOT EXISTS public.unidades_medida (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sigla TEXT NOT NULL,
  nome TEXT,
  detalhes TEXT,
  categoria TEXT,
  usuario_cadastrou_nome TEXT,
  usuario_cadastrou_matricula TEXT,
  data_hora_registro TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  CONSTRAINT unidades_medida_sigla_unico UNIQUE (sigla)
);

CREATE INDEX IF NOT EXISTS idx_unidades_medida_categoria ON public.unidades_medida(categoria);

-- Unidades de medida iniciais (opcional; só insere se não existir)
INSERT INTO public.unidades_medida (sigla, nome, categoria)
SELECT 'UN', 'Unidade', 'Geral' WHERE NOT EXISTS (SELECT 1 FROM public.unidades_medida WHERE sigla = 'UN');
INSERT INTO public.unidades_medida (sigla, nome, categoria)
SELECT 'CX', 'Caixa', 'Geral' WHERE NOT EXISTS (SELECT 1 FROM public.unidades_medida WHERE sigla = 'CX');
INSERT INTO public.unidades_medida (sigla, nome, categoria)
SELECT 'GAL', 'Galão', 'Geral' WHERE NOT EXISTS (SELECT 1 FROM public.unidades_medida WHERE sigla = 'GAL');
INSERT INTO public.unidades_medida (sigla, nome, categoria)
SELECT 'FR', 'Frasco', 'Geral' WHERE NOT EXISTS (SELECT 1 FROM public.unidades_medida WHERE sigla = 'FR');
INSERT INTO public.unidades_medida (sigla, nome, categoria)
SELECT 'PCT', 'Pacote', 'Geral' WHERE NOT EXISTS (SELECT 1 FROM public.unidades_medida WHERE sigla = 'PCT');

-- Colunas em ata_credor_itens (detalhamento: nome, especificação, marca, unidade)
ALTER TABLE public.ata_credor_itens ADD COLUMN IF NOT EXISTS nome_item TEXT;
ALTER TABLE public.ata_credor_itens ADD COLUMN IF NOT EXISTS especificacao TEXT;
ALTER TABLE public.ata_credor_itens ADD COLUMN IF NOT EXISTS marca_fabricante_id UUID REFERENCES public.marcas_fabricantes(id) ON DELETE SET NULL;
ALTER TABLE public.ata_credor_itens ADD COLUMN IF NOT EXISTS unidade_medida_id UUID REFERENCES public.unidades_medida(id) ON DELETE SET NULL;
-- Auditoria para itens de cadastro manual (quem cadastrou e quando)
ALTER TABLE public.ata_credor_itens ADD COLUMN IF NOT EXISTS usuario_cadastrou_nome TEXT;
ALTER TABLE public.ata_credor_itens ADD COLUMN IF NOT EXISTS usuario_cadastrou_matricula TEXT;
CREATE INDEX IF NOT EXISTS idx_ata_credor_itens_marca ON public.ata_credor_itens(marca_fabricante_id);
CREATE INDEX IF NOT EXISTS idx_ata_credor_itens_unidade ON public.ata_credor_itens(unidade_medida_id);

COMMENT ON TABLE public.atas IS 'Atas de registro – cadastro manual (numero_ata, modalidade, vigência, tipo_ata, etc.)';
COMMENT ON TABLE public.ata_credores IS 'Fornecedor/empresa e representante por ata';
COMMENT ON TABLE public.ata_credor_itens IS 'Itens da ata vinculados ao credor (origem: catmed_medicamentos, renem_equipamentos ou OPME)';
COMMENT ON TABLE public.marcas_fabricantes IS 'Banco de marcas/fabricantes; cadastro com auditoria (quem cadastrou, quando)';
COMMENT ON TABLE public.unidades_medida IS 'Banco de unidades de medida (sigla, nome, detalhes, categoria)';
