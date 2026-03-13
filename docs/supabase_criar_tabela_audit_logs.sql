-- Trilha de auditoria: registros de CREATE, UPDATE e DELETE para restauração (apenas admin).
-- Execute no Supabase (SQL Editor) uma vez.

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references usuarios(id) on delete set null,
  action text not null check (action in ('CREATE', 'UPDATE', 'DELETE')),
  entity_name text not null,
  entity_id text,
  old_value jsonb,
  new_value jsonb,
  ip_address text,
  created_at timestamptz not null default now()
);

create index if not exists idx_audit_logs_entity on audit_logs(entity_name);
create index if not exists idx_audit_logs_action on audit_logs(action);
create index if not exists idx_audit_logs_created_at on audit_logs(created_at desc);
create index if not exists idx_audit_logs_user_id on audit_logs(user_id);

comment on table audit_logs is 'Trilha de auditoria: apenas administradores podem ver e restaurar.';
