-- ============================================================
-- Corrige erro 403 ao salvar unidade com logo
-- "new row violates row-level security policy" no Storage
--
-- Execute no Supabase: SQL Editor > New query > Cole e Run
-- ============================================================

-- 1. Criar o bucket logos-unidades se ainda não existir (público para exibir as logos)
insert into storage.buckets (id, name, public)
values ('logos-unidades', 'logos-unidades', true)
on conflict (id) do update set public = true;

-- 2. Remover políticas antigas (se existirem) para poder recriar
drop policy if exists "Permitir upload de logos (autenticados)" on storage.objects;
drop policy if exists "Permitir update de logos (autenticados)" on storage.objects;
drop policy if exists "Permitir delete de logos (autenticados)" on storage.objects;
drop policy if exists "Permitir leitura de logos (autenticados)" on storage.objects;

-- 3. Políticas para usuários autenticados no bucket logos-unidades
create policy "Permitir upload de logos (autenticados)"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'logos-unidades');

create policy "Permitir update de logos (autenticados)"
  on storage.objects for update to authenticated
  using (bucket_id = 'logos-unidades')
  with check (bucket_id = 'logos-unidades');

create policy "Permitir delete de logos (autenticados)"
  on storage.objects for delete to authenticated
  using (bucket_id = 'logos-unidades');

create policy "Permitir leitura de logos (autenticados)"
  on storage.objects for select to authenticated
  using (bucket_id = 'logos-unidades');
