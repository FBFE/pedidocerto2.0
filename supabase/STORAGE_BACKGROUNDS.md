# Bucket de planos de fundo (Configurações)

Para o upload de planos de fundo pelo admin funcionar, crie um bucket no Supabase Storage:

1. Acesse o [Painel Supabase](https://supabase.com/dashboard) → seu projeto → **Storage**.
2. Clique em **New bucket**.
3. Nome: `backgrounds`
4. Marque **Public bucket** (para as URLs geradas serem acessíveis no app).
5. Crie o bucket.

Políticas (RLS): para usuários autenticados poderem fazer upload, adicione uma policy no bucket `backgrounds` permitindo `INSERT` (e opcionalmente `SELECT`) para usuários com role `authenticated` ou para administradores. No painel: Storage → backgrounds → Policies → New policy.
