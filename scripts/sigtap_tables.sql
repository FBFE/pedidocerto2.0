-- 1. Tabela de Grupos
CREATE TABLE public.sigtap_grupo (
  co_grupo text PRIMARY KEY,
  no_grupo text NOT NULL,
  dt_competencia text
);
ALTER TABLE public.sigtap_grupo ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir leitura de grupo" ON public.sigtap_grupo FOR SELECT USING (true);
CREATE POLICY "Permitir insercao temporaria grupo" ON public.sigtap_grupo FOR INSERT WITH CHECK (true);
CREATE POLICY "Permitir atualizacao temporaria grupo" ON public.sigtap_grupo FOR UPDATE USING (true) WITH CHECK (true);

-- 2. Tabela de Subgrupos
CREATE TABLE public.sigtap_sub_grupo (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  co_grupo text NOT NULL,
  co_sub_grupo text NOT NULL,
  no_sub_grupo text NOT NULL,
  dt_competencia text,
  UNIQUE(co_grupo, co_sub_grupo)
);
ALTER TABLE public.sigtap_sub_grupo ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir leitura de sub grupo" ON public.sigtap_sub_grupo FOR SELECT USING (true);
CREATE POLICY "Permitir insercao temporaria sub grupo" ON public.sigtap_sub_grupo FOR INSERT WITH CHECK (true);
CREATE POLICY "Permitir atualizacao temporaria sub grupo" ON public.sigtap_sub_grupo FOR UPDATE USING (true) WITH CHECK (true);

-- 3. Tabela Forma Organizacao
CREATE TABLE public.sigtap_forma_organizacao (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  co_grupo text NOT NULL,
  co_sub_grupo text NOT NULL,
  co_forma_organizacao text NOT NULL,
  no_forma_organizacao text NOT NULL,
  dt_competencia text,
  UNIQUE(co_grupo, co_sub_grupo, co_forma_organizacao)
);
ALTER TABLE public.sigtap_forma_organizacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir leitura de forma organizacao" ON public.sigtap_forma_organizacao FOR SELECT USING (true);
CREATE POLICY "Permitir insercao temporaria forma organizacao" ON public.sigtap_forma_organizacao FOR INSERT WITH CHECK (true);
CREATE POLICY "Permitir atualizacao temporaria forma organizacao" ON public.sigtap_forma_organizacao FOR UPDATE USING (true) WITH CHECK (true);

-- 5. Tabela de Descricao
CREATE TABLE public.sigtap_descricao (
  co_procedimento text PRIMARY KEY,
  ds_procedimento text NOT NULL,
  dt_competencia text
);
ALTER TABLE public.sigtap_descricao ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir leitura de descricao" ON public.sigtap_descricao FOR SELECT USING (true);
CREATE POLICY "Permitir insercao temporaria descricao" ON public.sigtap_descricao FOR INSERT WITH CHECK (true);
CREATE POLICY "Permitir atualizacao temporaria descricao" ON public.sigtap_descricao FOR UPDATE USING (true) WITH CHECK (true);
-- 4. Tabela de Procedimentos Compativeis (OPMEs e outros)
CREATE TABLE public.sigtap_procedimento_compativel (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  co_procedimento_principal text NOT NULL,
  co_registro_principal text,
  co_procedimento_compativel text NOT NULL,
  co_registro_compativel text,
  tp_compatibilidade text,
  qt_permitida integer,
  dt_competencia text,
  UNIQUE(co_procedimento_principal, co_procedimento_compativel)
);
ALTER TABLE public.sigtap_procedimento_compativel ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir leitura de compativel" ON public.sigtap_procedimento_compativel FOR SELECT USING (true);
CREATE POLICY "Permitir insercao temporaria compativel" ON public.sigtap_procedimento_compativel FOR INSERT WITH CHECK (true);
CREATE POLICY "Permitir atualizacao temporaria compativel" ON public.sigtap_procedimento_compativel FOR UPDATE USING (true) WITH CHECK (true);
