# Bucket para logos das Unidades Hospitalares

O app guarda a logo de cada unidade como **arquivo** no Supabase Storage (bucket).

## Criar o bucket no Supabase

1. Acesse o **Supabase Dashboard** do seu projeto.
2. Vá em **Storage** no menu lateral.
3. Clique em **New bucket**.
4. Nome do bucket: **`logos-unidades`** (obrigatório – o código usa esse nome).
5. Marque **Public bucket** se quiser que as logos sejam acessíveis por URL pública (recomendado para exibir na interface).
6. Crie o bucket.

## Políticas RLS (obrigatório para upload funcionar)

Sem políticas, o upload da logo retorna **403 (row-level security policy)**. Execute o script que cria as políticas:

**Arquivo:** `supabase/UNIDADES_SIGLA_DESCRICAO_E_STORAGE_RLS.sql`

Esse script adiciona políticas em `storage.objects` para o bucket `logos-unidades`:
- **INSERT** e **UPDATE**: usuários autenticados podem enviar/substituir logos.
- **DELETE**: usuários autenticados podem remover logos.
- **SELECT**: leitura para exibir as imagens.

Execute no **SQL Editor** do Supabase (a parte das políticas de storage). Se ainda der 403, confira em **Storage** > **Policies** se as políticas foram criadas.

## Comportamento no app

- **Inserir unidade com logo:** upload do arquivo para `{id_da_unidade}/logo.{ext}` e gravação do path em `logo_url`.
- **Editar e trocar logo:** a logo antiga é **removida** do bucket e a nova é enviada (substituição).
- **Deletar unidade:** a logo é **removida** do bucket e em seguida o registro da unidade é excluído.
