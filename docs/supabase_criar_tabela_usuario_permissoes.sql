-- Execute no Supabase (SQL Editor) uma vez para o sistema de permissões funcionar.

create table if not exists usuario_permissoes (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references usuarios(id) on delete cascade,
  modulo text not null,
  adicionar boolean not null default false,
  editar boolean not null default false,
  excluir boolean not null default false,
  unique(usuario_id, modulo)
);

create index if not exists idx_usuario_permissoes_usuario_id on usuario_permissoes(usuario_id);
