-- ============================================================
-- Base hierárquica para Unidade de Lotação
--
-- Estrutura:
--   Governo do Estado (raiz)
--   └── Secretaria (Nome, Sigla, Descrição)
--       ├── Secretaria Adjunta (Nome, Sigla, Descrição)
--       │   └── Setores (Nome, Sigla, Descrição)
--       └── Unidade Hospitalar (CNES, Nome, CNPJ, endereço, gestão, logo, etc.)
--           └── Setores (Nome, Sigla, Descrição)
--
-- Execute no Supabase: SQL Editor > New query > Cole e Run
-- ============================================================

-- 1. Secretarias (vinculadas ao Governo)
create table if not exists public.secretarias (
  id uuid default gen_random_uuid() primary key,
  nome text not null,
  sigla text,
  descricao text,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

-- 2. Secretarias Adjuntas (vinculadas à Secretaria)
create table if not exists public.secretarias_adjuntas (
  id uuid default gen_random_uuid() primary key,
  secretaria_id uuid not null references public.secretarias(id) on delete cascade,
  nome text not null,
  sigla text,
  descricao text,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

-- 3. Unidades Hospitalares (vinculadas à Secretaria) + dados da imagem + logo
create table if not exists public.unidades_hospitalares (
  id uuid default gen_random_uuid() primary key,
  secretaria_id uuid not null references public.secretarias(id) on delete cascade,
  cnes text,
  nome text not null,
  cnpj text,
  nome_empresarial text,
  natureza_juridica text,
  cep text,
  logradouro text,
  numero text,
  bairro text,
  municipio text,
  uf text,
  complemento text,
  classificacao_estabelecimento text,
  gestao text,
  tipo_estrutura text,
  latitude text,
  longitude text,
  responsavel_tecnico text,
  telefone text,
  email text,
  cadastrado_em date,
  atualizacao_base_local date,
  ultima_atualizacao_nacional date,
  horario_funcionamento text,
  data_desativacao date,
  motivo_desativacao text,
  logo_url text,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

-- 4. Setores (vinculados à Secretaria Adjunta OU à Unidade Hospitalar)
create table if not exists public.setores (
  id uuid default gen_random_uuid() primary key,
  nome text not null,
  sigla text,
  descricao text,
  secretaria_adjunta_id uuid references public.secretarias_adjuntas(id) on delete cascade,
  unidade_hospitalar_id uuid references public.unidades_hospitalares(id) on delete cascade,
  created_at timestamptz default timezone('utc'::text, now()) not null,
  constraint setor_vinculo_check check (
    (secretaria_adjunta_id is not null and unidade_hospitalar_id is null) or
    (secretaria_adjunta_id is null and unidade_hospitalar_id is not null)
  )
);

create index if not exists idx_secretarias_adjuntas_secretaria on public.secretarias_adjuntas(secretaria_id);
create index if not exists idx_unidades_hospitalares_secretaria on public.unidades_hospitalares(secretaria_id);
create index if not exists idx_setores_adjunta on public.setores(secretaria_adjunta_id);
create index if not exists idx_setores_unidade on public.setores(unidade_hospitalar_id);
