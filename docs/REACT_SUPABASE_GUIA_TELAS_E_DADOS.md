# Guia React + Supabase – Onde puxar dados e como configurar

Este documento resume **de onde cada tela puxa dados** no Supabase e **como configurar** cadastro, usuários, organograma e detalhes no React.

---

## 1. Configuração inicial (onde configurar)

### 1.1 Cliente Supabase no React

Garanta que o cliente está inicializado com a **mesma** URL e anon key do Flutter:

```js
// Exemplo: src/lib/supabaseClient.js (ou .ts)
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL   // ou process.env.REACT_APP_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

**Variáveis de ambiente (`.env`):**
- `VITE_SUPABASE_URL=https://bwdyzdhguwknbcagdado.supabase.co`
- `VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (a mesma anon key do Flutter)

### 1.2 De onde cada coisa vem

| O quê | Onde está | Como acessar no React |
|-------|-----------|------------------------|
| Usuários (perfil, lista, aprovação) | Tabela `public.usuarios` | `supabase.from('usuarios')` |
| Login/Cadastro/Logout | Supabase Auth | `supabase.auth.signInWithPassword`, `signUp`, `signOut` |
| Governo (organograma raiz) | Tabela `public.governo` | `supabase.from('governo')` |
| Secretarias | Tabela `public.secretarias` | `supabase.from('secretarias')` |
| Secretarias adjuntas | Tabela `public.secretarias_adjuntas` | `supabase.from('secretarias_adjuntas')` |
| Unidades hospitalares | Tabela `public.unidades_hospitalares` | `supabase.from('unidades_hospitalares')` |
| Setores | Tabela `public.setores` | `supabase.from('setores')` |
| Logos (Governo e Unidades) | Storage bucket `logos-unidades` | `supabase.storage.from('logos-unidades')` |
| Planos de fundo | Storage bucket `backgrounds` + localStorage | `supabase.storage.from('backgrounds')` + chaves abaixo |
| Importações Indicasus | Tabelas `indicasus_importacao`, `indicasus_importacao_historico` | `supabase.from('indicasus_importacao')` |
| Importações Custo | Tabelas `custo_unidade_importacao`, `custo_unidade_importacao_historico` | `supabase.from('custo_unidade_importacao')` |

---

## 2. Cadastro (registro de novo usuário)

### 2.1 Fluxo

1. **Auth:** criar conta no Supabase Auth.
2. **Perfil:** criar linha na tabela `usuarios` com `perfil_sistema = 'pendente_aprovacao'`.

### 2.2 Onde puxar / onde gravar

| Etapa | Onde | Como no React |
|-------|------|----------------|
| Criar conta | Auth | `await supabase.auth.signUp({ email, password, options: { data: { nome } } })` |
| Criar perfil | Tabela `usuarios` | `await supabase.from('usuarios').insert({ nome, email, perfil_sistema: 'pendente_aprovacao' }).select().single()` |

**Campos para insert em `usuarios` no cadastro:**  
`nome` (obrigatório), `email` (obrigatório), `perfil_sistema: 'pendente_aprovacao'`.  
O restante o usuário preenche depois na tela “Meus dados”.

### 2.3 Configuração

- RLS na tabela `usuarios`: permitir `INSERT` para usuários autenticados (e, se quiser, que o próprio usuário insira só seu registro, por exemplo com `auth.uid()` ou email).
- Após `signUp`, usar `supabase.auth.getUser()` para pegar email e nome e então fazer o `insert` em `usuarios`.

---

## 3. Telas de usuários

### 3.1 Lista de usuários (painel principal)

**De onde puxar:** tabela `usuarios`.

| Ação | Tabela | Chamada Supabase |
|------|--------|------------------|
| Listar todos | `usuarios` | `supabase.from('usuarios').select()` |
| Filtrar por perfil | `usuarios` | `.select().eq('perfil_sistema', 'pendente_aprovacao')` ou `'usuario'` ou `'administrador'` |
| Listar só pendentes | `usuarios` | `supabase.from('usuarios').select().eq('perfil_sistema', 'pendente_aprovacao').order('nome')` |

**Quem vê o quê:**
- **Todos (logados):** lista de usuários (filtrável por perfil).
- **Admin:** vê também a lista de “pendentes de aprovação” e pode aprovar.

### 3.2 Perfil do usuário logado (para decidir tela inicial)

**De onde puxar:** tabela `usuarios`, pelo **email** do Auth.

```js
const { data: { user } } = await supabase.auth.getUser()
const email = user?.email
const { data: perfil } = await supabase.from('usuarios').select().eq('email', email).maybeSingle()
```

- Se `perfil === null` → pode mostrar “Meus dados” para completar cadastro.
- Se `perfil.perfil_sistema === 'pendente_aprovacao'` → mostrar só **Meus dados** (sem painel).
- Se `perfil.perfil_sistema === 'usuario'` ou `'administrador'` → mostrar **painel (lista de usuários)** e demais telas.

### 3.3 Aprovar usuário (admin)

**Onde gravar:** tabela `usuarios`, **update** de uma linha.

```js
await supabase.from('usuarios').update({ perfil_sistema: 'usuario' }).eq('id', usuarioId).select().single()
```

### 3.4 Meus dados / Editar usuário

**De onde puxar:**
- **Próprio usuário:** buscar por `email` (Auth) ou por `id` se já tiver o perfil.
- **Admin editando outro:** buscar por `id` (ex.: `usuarios/:id`).

**Onde gravar:** tabela `usuarios`, **update**.

```js
await supabase.from('usuarios').update({
  nome, nascimento, documento, contato, matricula, data_posse,
  regime_contrato, dga, data_vencimento_contrato, carga_horaria,
  escolaridade, formacao, email, unidade_lotacao, setor_lotacao,
  situacao, cargo, perfil_sistema  // perfil_sistema só se for admin
}).eq('id', usuarioId).select().single()
```

**Campos da tabela (snake_case):**  
`nome`, `nascimento`, `documento`, `contato`, `matricula`, `data_posse`, `regime_contrato`, `dga`, `data_vencimento_contrato`, `carga_horaria`, `escolaridade`, `formacao`, `email`, `unidade_lotacao`, `setor_lotacao`, `situacao`, `cargo`, `perfil_sistema`.

Para “unidade de lotação” e “setor de lotação”, os valores exibidos vêm do **organograma** (governo → secretarias → secretarias_adjuntas / unidades_hospitalares → setores). Ver seção 4.

### 3.5 Atualizar nome no Auth (opcional, ao salvar Meus dados)

```js
await supabase.auth.updateUser({ data: { nome: novoNome } })
```

---

## 4. Organograma

Estrutura: **Governo** → **Secretarias** → (**Secretarias Adjuntas** + **Unidades Hospitalares**) → **Setores** (cada setor pertence a uma secretaria_adjunta **ou** a uma unidade_hospitalar).

### 4.1 Onde puxar cada nível

| Nível | Tabela | Como listar |
|-------|--------|-------------|
| Governo (raiz) | `governo` | `supabase.from('governo').select().limit(1).maybeSingle()` ou `.select().order('nome')` |
| Secretarias de um governo | `secretarias` | `supabase.from('secretarias').select().eq('governo_id', governoId).order('nome')` |
| Secretarias adjuntas de uma secretaria | `secretarias_adjuntas` | `supabase.from('secretarias_adjuntas').select().eq('secretaria_id', secretariaId).order('nome')` |
| Unidades de uma secretaria | `unidades_hospitalares` | `supabase.from('unidades_hospitalares').select().eq('secretaria_id', secretariaId).order('nome')` |
| Setores de uma secretaria adjunta | `setores` | `supabase.from('setores').select().eq('secretaria_adjunta_id', secretariaAdjuntaId).order('nome')` |
| Setores de uma unidade | `setores` | `supabase.from('setores').select().eq('unidade_hospitalar_id', unidadeId).order('nome')` |

### 4.2 CRUD – onde gravar

| Entidade | Inserir | Atualizar | Deletar |
|----------|---------|-----------|--------|
| Governo | `governo` insert; logo em Storage (abaixo) | `governo` update por `id` | `governo` delete por `id`; remover logo do Storage |
| Secretaria | `secretarias` insert (com `governo_id`) | `secretarias` update por `id` | `secretarias` delete por `id` |
| Secretaria adjunta | `secretarias_adjuntas` insert (com `secretaria_id`) | `secretarias_adjuntas` update por `id` | `secretarias_adjuntas` delete por `id` |
| Unidade hospitalar | `unidades_hospitalares` insert (com `secretaria_id`); logo em Storage | `unidades_hospitalares` update por `id`; logo em Storage | `unidades_hospitalares` delete por `id`; remover logo do Storage |
| Setor | `setores` insert (com `secretaria_adjunta_id` **ou** `unidade_hospitalar_id`) | `setores` update por `id` | `setores` delete por `id` |

### 4.3 Logos (Governo e Unidades)

**Bucket:** `logos-unidades`.

**Governo:**
- Path no bucket: `governo/{governoId}/logo.{ext}` (ex.: `governo/uuid/logo.png`).
- Upload: `supabase.storage.from('logos-unidades').upload(path, file, { upsert: true })`.
- URL pública: `supabase.storage.from('logos-unidades').getPublicUrl(path).data.publicUrl`.
- Na tabela `governo`: guardar em `logo_url` apenas o **path** (ex.: `governo/uuid/logo.png`).

**Unidade hospitalar:**
- Path: `{unidadeId}/logo.{ext}`.
- Mesmo processo: upload → pegar URL pública para exibir; na tabela `unidades_hospitalares` guardar o path em `logo_url`.

**Deletar logo:** `supabase.storage.from('logos-unidades').remove([path])`.

---

## 5. Detalhes das telas

### 5.1 Detalhe da Unidade Hospitalar

**De onde puxar:**
- Unidade: `supabase.from('unidades_hospitalares').select().eq('id', unidadeId).single()`
- Logo: usar `logo_url` (path) com `supabase.storage.from('logos-unidades').getPublicUrl(logo_url)`.

Na tela de detalhe você pode mostrar ainda:
- Setores da unidade: `supabase.from('setores').select().eq('unidade_hospitalar_id', unidadeId)`.
- Importações Indicasus da unidade: `supabase.from('indicasus_importacao').select().eq('unidade_id', unidadeId).order('ano_referencia', { ascending: false })`.
- Importações Custo: `supabase.from('custo_unidade_importacao').select().eq('unidade_id', unidadeId).order('ano_competencia', { ascending: false })`.

### 5.2 Lista de Unidades (por secretaria)

**De onde puxar:**  
`supabase.from('unidades_hospitalares').select().eq('secretaria_id', secretariaId).order('nome')`.  
Para “todas”: `supabase.from('unidades_hospitalares').select().order('nome')`.

### 5.3 Importar Indicasus (planilha)

**Onde gravar:**
- `indicasus_importacao`: `unidade_id`, `ano_referencia`, `nome_unidade_planilha`, `dados_json` (array de objetos).
- Se for reimportação (mesmo unidade + ano): fazer **update** em vez de insert e gravar em `indicasus_importacao_historico` com `tipo: 'reimportacao'`.
- Histórico: `indicasus_importacao_historico`: `importacao_id`, `tipo` ('criacao'|'edicao'|'reimportacao'), `descricao`, `usuario_email` (opcional).

### 5.4 Importar Custo (CSV)

**Onde gravar:**
- `custo_unidade_importacao`: `unidade_id`, `ano_competencia`, `nome_unidade_planilha`, `dados_json` (lista de `{ itemCusto, valoresMensais }`).
- Histórico: `custo_unidade_importacao_historico`: mesmo padrão (importacao_id, tipo, descricao, usuario_email).

### 5.5 Painéis (SGS / Tático) e Relatório de Custo

**De onde puxar:**  
Os dados já estão em `indicasus_importacao.dados_json` e `custo_unidade_importacao.dados_json`.  
A tela só precisa buscar a importação por `id` (ou unidade + ano) e usar o JSON para gráficos/tabelas.

---

## 6. Configurações (plano de fundo)

### 6.1 Onde está configurado

- **Qual plano de fundo está escolhido:** **localStorage** (não é Supabase).
- **Lista de URLs de planos de fundo (admin):** **localStorage** (JSON array).
- **Arquivo de plano de fundo:** Storage bucket **`backgrounds`** (admin faz upload; a URL retornada é que é salva no localStorage).

### 6.2 Chaves de localStorage (igual ao Flutter)

- `app_background_path`: string com path do asset ou URL do plano de fundo atual.
- `app_background_urls`: string JSON = array de URLs (ex.: `["https://...supabase.co/storage/.../arquivo.png"]`).

### 6.3 Upload de plano de fundo (admin)

- Bucket: `backgrounds`.
- Upload: `supabase.storage.from('backgrounds').upload(nomeArquivo, file, { upsert: true })`.
- Pegar URL pública e: (1) salvar em `app_background_path` no localStorage; (2) adicionar na lista `app_background_urls` (ler → parse → push → stringify → salvar).

---

## 7. Resumo por tela – onde puxar e onde gravar

| Tela | Puxar de | Gravar em |
|------|----------|-----------|
| Login | Auth | Auth (`signInWithPassword`) |
| Criar conta | - | Auth (`signUp`) + `usuarios` (insert) |
| Painel / Lista de usuários | `usuarios` (select) | - |
| Pendentes de aprovação | `usuarios` (perfil_sistema = pendente_aprovacao) | `usuarios` (update perfil_sistema = usuario) |
| Meus dados / Editar usuário | `usuarios` (por email ou id); organograma (governo, secretarias, etc.) para dropdowns | `usuarios` (update); opcional Auth (updateUser) |
| Organograma (árvore) | `governo`, `secretarias`, `secretarias_adjuntas`, `unidades_hospitalares`, `setores` | Insert/update/delete em cada tabela; logos em Storage `logos-unidades` |
| Lista de unidades | `unidades_hospitalares` (por secretaria ou todos) | - |
| Detalhe da unidade | `unidades_hospitalares` (por id); Storage para logo; opcional setores, indicasus, custo | - |
| Formulário Unidade (criar/editar) | `secretarias` (para dropdown) | `unidades_hospitalares`; logo em `logos-unidades` |
| Importar Indicasus | - | `indicasus_importacao` + `indicasus_importacao_historico` |
| Importar Custo | - | `custo_unidade_importacao` + `custo_unidade_importacao_historico` |
| Painel SGS / Relatório Custo | `indicasus_importacao` ou `custo_unidade_importacao` (dados_json) | - |
| Configurações (fundo) | localStorage (`app_background_path`, `app_background_urls`) | localStorage; upload em Storage `backgrounds` |

---

## 8. Checklist de configuração no React

1. **Supabase:** mesmo projeto (URL + anon key); cliente criado uma vez e usado em serviços/hooks.
2. **Auth:** após login, buscar perfil em `usuarios` por `email` para decidir se mostra “Meus dados” ou painel.
3. **RLS:** políticas nas tabelas e no Storage conforme regras de negócio (quem pode ler/inserir/atualizar).
4. **Organograma:** carregar governo → secretarias (por governo_id) → secretarias_adjuntas e unidades (por secretaria_id) → setores (por secretaria_adjunta_id ou unidade_hospitalar_id).
5. **Logos:** bucket `logos-unidades`; paths `governo/{id}/logo.ext` e `{unidadeId}/logo.ext`; exibir com `getPublicUrl(path)`.
6. **Planos de fundo:** localStorage para path e lista de URLs; bucket `backgrounds` para upload.
7. **Formulário Meus dados:** opções de unidade/setor vêm das tabelas do organograma; salvar em `usuarios.unidade_lotacao` e `usuarios.setor_lotacao` (texto ou id, conforme o que o Flutter usa).

Com isso, o React fica alinhado ao que o Flutter faz: mesma base Supabase, mesmas tabelas e buckets, e regras claras de onde puxar e onde configurar cada função e tela.
