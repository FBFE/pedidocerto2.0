# Módulo Unidades de Lotação

Hierarquia para cadastro de unidades de lotação:

- **Governo do Estado** (raiz conceitual)
- **Secretaria** – vinculada ao Governo (Nome, Sigla, Descrição)
- **Secretaria Adjunta** – vinculada à Secretaria (Nome, Sigla, Descrição)
- **Unidade Hospitalar** – vinculada à Secretaria (dados completos: CNES, endereço, gestão, logo, etc.)
- **Setor** – vinculado à Secretaria Adjunta **ou** à Unidade Hospitalar (Nome, Sigla, Descrição)

## Tabelas no Supabase

Execute o script `supabase/CRIAR_BASE_UNIDADE_LOTACAO.sql` no SQL Editor.

## Uso

- `SecretariaRepository`, `SecretariaAdjuntaRepository`, `UnidadeHospitalarRepository`, `SetorRepository` para CRUD.
- Para listar setores de uma unidade: `SetorRepository().getByUnidadeHospitalarId(id)`.
- Para listar setores de uma secretaria adjunta: `SetorRepository().getBySecretariaAdjuntaId(id)`.
- Logo da unidade hospitalar: campo `logo_url` (pode apontar para Supabase Storage ou URL externa).
