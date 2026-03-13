-- Cole no SQL Editor do Supabase e execute (Run).

create table public.usuarios (
  id uuid default gen_random_uuid() primary key,
  nome text not null,
  nascimento date,
  documento text,
  contato text,
  matricula text,
  data_posse date,
  regime_contrato text,
  dga text,
  data_vencimento_contrato date,
  carga_horaria text,
  escolaridade text,
  formacao text,
  email text,
  unidade_lotacao text,
  setor_lotacao text,
  situacao text default 'Ativo',
  cargo text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
