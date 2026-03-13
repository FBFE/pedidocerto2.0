# Templates de e-mail – Pedido Certo 2.0

Configure os e-mails de **cadastro** e **redefinição de senha** no **Supabase Dashboard** para usar a marca do sistema.

**Onde configurar:**  
[Supabase Dashboard](https://supabase.com/dashboard) → seu projeto → **Authentication** → **Email Templates**.

---

## 1. Confirm sign up (Confirmar cadastro)

Quando o usuário se cadastra, ele recebe um e-mail para confirmar o endereço.

### Subject (assunto)

```
Pedido Certo 2.0 - Confirme seu cadastro
```

### Body (corpo do e-mail)

Cole no campo **Message body** (pode ser HTML):

```html
<h2>Bem-vindo ao Pedido Certo 2.0</h2>

<p>Olá,</p>

<p>Você solicitou o cadastro no sistema <strong>Pedido Certo 2.0</strong>. Para ativar sua conta, confirme seu e-mail clicando no link abaixo:</p>

<p><a href="{{ .ConfirmationURL }}" style="display: inline-block; padding: 12px 24px; background-color: #1B4965; color: white; text-decoration: none; border-radius: 8px; font-weight: 600;">Confirmar meu cadastro</a></p>

<p>Ou copie e cole este link no navegador:</p>
<p style="word-break: break-all; color: #666; font-size: 12px;">{{ .ConfirmationURL }}</p>

<p>Se você não solicitou este cadastro, ignore este e-mail.</p>

<p>— Equipe Pedido Certo 2.0</p>
```

---

## 2. Reset password (Redefinir senha)

Quando o usuário solicita “Esqueci minha senha”, ele recebe um e-mail com o link para redefinir.

### Subject (assunto)

```
Pedido Certo 2.0 - Redefinir senha
```

### Body (corpo do e-mail)

Cole no campo **Message body**:

```html
<h2>Redefinir senha - Pedido Certo 2.0</h2>

<p>Olá,</p>

<p>Foi solicitada a redefinição de senha da sua conta no sistema <strong>Pedido Certo 2.0</strong>. Clique no botão abaixo para definir uma nova senha:</p>

<p><a href="{{ .ConfirmationURL }}" style="display: inline-block; padding: 12px 24px; background-color: #1B4965; color: white; text-decoration: none; border-radius: 8px; font-weight: 600;">Redefinir minha senha</a></p>

<p>Ou copie e cole este link no navegador:</p>
<p style="word-break: break-all; color: #666; font-size: 12px;">{{ .ConfirmationURL }}</p>

<p>Este link expira em algumas horas. Se você não solicitou a redefinição, ignore este e-mail e sua senha permanecerá a mesma.</p>

<p>— Equipe Pedido Certo 2.0</p>
```

---

## Variáveis do Supabase (não altere)

- `{{ .ConfirmationURL }}` – link de confirmação (obrigatório no corpo)
- `{{ .Email }}` – e-mail do usuário (opcional, para personalizar)
- `{{ .SiteURL }}` – URL do site configurada no projeto

Depois de colar, clique em **Save** em cada template.
