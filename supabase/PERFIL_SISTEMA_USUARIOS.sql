-- ============================================================
-- Execute no Supabase: SQL Editor > New query > Cole e Run
-- ============================================================
-- Adiciona a coluna perfil_sistema na tabela usuarios.
-- Valores: 'pendente_aprovacao' (novo cadastro), 'usuario' (aprovado), 'administrador'.
-- Apenas usuários com perfil 'administrador' podem aprovar cadastros.
-- ============================================================

ALTER TABLE public.usuarios
  ADD COLUMN IF NOT EXISTS perfil_sistema text;

-- Usuários já existentes: considerar aprovados como 'usuario'.
UPDATE public.usuarios
SET perfil_sistema = 'usuario'
WHERE perfil_sistema IS NULL;

-- Para definir um usuário como administrador, use o script: USUARIO_DEFINIR_ADMIN.sql
