# Deploy do Pedido Certo na Vercel

## Pré-requisitos

1. **Conta na Vercel** – [vercel.com](https://vercel.com) (login com GitHub).
2. **Projeto no GitHub** – O código deve estar em um repositório GitHub (ex.: `FBFE/pedidocerto2.0`).

## Passo a passo

### 1. Conectar o repositório à Vercel

1. Acesse [vercel.com/new](https://vercel.com/new).
2. Clique em **Import Git Repository**.
3. Selecione o repositório **pedidocerto2.0** (ou faça o login no GitHub e autorize a Vercel).
4. Clique em **Import**.

### 2. Configuração do projeto

O arquivo **`vercel.json`** na raiz do projeto já define:

- **Install Command:** clona o Flutter SDK (branch stable) e habilita web.
- **Build Command:** `./flutter/bin/flutter build web --release`
- **Output Directory:** `build/web`
- **Rewrites:** redirecionamento para `index.html` (SPA).

Não é necessário alterar nada no painel da Vercel se o `vercel.json` estiver commitado. Se quiser conferir ou sobrescrever no painel:

- **Framework Preset:** Other
- **Build Command:** `./flutter/bin/flutter build web --release`
- **Output Directory:** `build/web`
- **Install Command:** (deixe o do `vercel.json` ou use o mesmo do arquivo)

### 3. Variáveis de ambiente (Supabase)

Se o app usa **Supabase**, configure as variáveis no projeto Vercel:

1. No projeto na Vercel, vá em **Settings** → **Environment Variables**.
2. Adicione as variáveis que o Flutter/Supabase usam (por exemplo, se estiverem em `lib` ou em algum config):
   - Normalmente o Supabase Flutter usa a URL e a chave anônima no próprio código; se estiverem em env, adicione aqui (ex.: `SUPABASE_URL`, `SUPABASE_ANON_KEY`).

### 4. Fazer o deploy

1. Clique em **Deploy**.
2. O primeiro build pode levar **5–10 minutos** (download do Flutter + compilação).
3. Ao terminar, a Vercel exibe a URL do projeto (ex.: `pedidocerto2-0.vercel.app`).

### 5. Acessar o app

- Use a URL gerada (ex.: `https://pedidocerto2-0.vercel.app`).
- Novos pushes na branch conectada (ex.: `main`) disparam um novo deploy automaticamente.

## Deploy pelo terminal (opcional)

Com [Vercel CLI](https://vercel.com/docs/cli) instalado:

```bash
npm i -g vercel
cd f:\pedidocerto2.0
vercel
```

Siga as perguntas (linkar projeto existente ou criar novo). O deploy usará o `vercel.json` da pasta.

## Problemas comuns

- **Build falha no Install:** confira se o repositório tem permissão de rede para clonar `github.com/flutter/flutter`.
- **Build falha no Flutter:** verifique os logs; às vezes é preciso garantir que o branch está em `stable` (já feito no script de install).
- **Página em branco:** confira se a **Output Directory** é mesmo `build/web` e se o **Rewrite** para `index.html` está ativo (já no `vercel.json`).
