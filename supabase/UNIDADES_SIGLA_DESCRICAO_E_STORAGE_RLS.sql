-- ============================================================
-- 1. Adicionar Sigla e Descrição em Unidades Hospitalares
-- 2. Políticas RLS do Storage para permitir upload/delete de logos
--    (corrige erro 403 "new row violates row-level security policy")
-- Execute no Supabase: SQL Editor > New query > Cole e Run
-- ============================================================

-- 1. Colunas Sigla e Descrição na tabela unidades_hospitalares
alter table public.unidades_hospitalares
  add column if not exists sigla text,
  add column if not exists descricao text;

-- 2. Políticas do Storage (bucket logos-unidades)
--    Permite usuários autenticados fazer upload e deletar arquivos no bucket.
--    Sem isso, o upload da logo retorna 403.

-- Upload (INSERT) no bucket logos-unidades
create policy "Permitir upload de logos (autenticados)"
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'logos-unidades');

-- Atualizar (UPDATE) para permitir upsert/substituição da logo
create policy "Permitir update de logos (autenticados)"
  on storage.objects
  for update
  to authenticated
  using (bucket_id = 'logos-unidades')
  with check (bucket_id = 'logos-unidades');

-- Deletar (DELETE) arquivos do bucket
create policy "Permitir delete de logos (autenticados)"
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'logos-unidades');

-- Leitura (SELECT) para exibir as logos (útil se o bucket não for público)
create policy "Permitir leitura de logos (autenticados)"
  on storage.objects
  for select
  to authenticated
  using (bucket_id = 'logos-unidades');
