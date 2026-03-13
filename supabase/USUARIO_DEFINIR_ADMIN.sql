-- ============================================================
-- Definir um usuário como administrador do sistema
-- Execute no Supabase: SQL Editor > New query > Cole, ajuste o e-mail e Run
-- ============================================================

UPDATE public.usuarios
SET perfil_sistema = 'administrador'
WHERE email = 'seu-email@exemplo.com';

-- Verificar: deve retornar 1 linha se o e-mail existir
-- SELECT id, nome, email, perfil_sistema FROM public.usuarios WHERE email = 'seu-email@exemplo.com';
