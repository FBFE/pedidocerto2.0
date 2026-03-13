-- ============================================================
-- Governo (raiz do organograma) + vínculo em Secretarias
-- Execute no Supabase: SQL Editor > New query > Cole e Run
-- ============================================================

-- 1. Tabela Governo (raiz: nome, sigla, logo)
create table if not exists public.governo (
  id uuid default gen_random_uuid() primary key,
  nome text not null,
  sigla text,
  logo_url text,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

-- 2. Adicionar governo_id em secretarias (vincula secretaria ao governo)
alter table public.secretarias
  add column if not exists governo_id uuid references public.governo(id) on delete cascade;

create index if not exists idx_secretarias_governo on public.secretarias(governo_id);
