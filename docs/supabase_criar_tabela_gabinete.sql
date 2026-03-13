-- Execute este SQL no Supabase (SQL Editor) uma vez para a tela
-- "Unidades do Gabinete (Gestão Hospitalar)" funcionar.

create table if not exists gabinete_gestao_hospitalar_unidades (
  unidade_id uuid primary key references unidades_hospitalares(id) on delete cascade
);

-- Opcional: permitir que o app (anon key) leia e escreva nesta tabela.
-- Se usar RLS, crie políticas conforme suas regras de segurança.
