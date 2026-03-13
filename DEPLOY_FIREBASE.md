# Deploy no Firebase Hosting

O projeto está configurado para usar **apenas** o Firebase Hosting (sem Auth, Firestore etc.). O app Flutter Web é gerado e publicado na pasta `build/web`.

## Pré-requisitos

1. **Node.js** instalado (para o Firebase CLI).
2. **Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```
3. Login no Firebase:
   ```bash
   firebase login
   ```

## Publicar o site

Na raiz do projeto:

```bash
# 1. Gerar o build web do Flutter (usa renderizador CanvasKit para melhor desempenho)
flutter build web

# 2. Fazer o deploy no Hosting
firebase deploy
```

O `index.html` está configurado para usar o **renderizador CanvasKit** (motor gráfico Skia), o que melhora a fluidez ao expandir o organograma e em animações.

Após o deploy, o Firebase exibirá a URL do site (ex.: `https://pedidocerto2-2026.web.app`).

## Configuração no console

- **Projeto:** pedidocerto2-2026  
- **Arquivos:** `firebase.json` (Hosting apontando para `build/web`) e `.firebaserc` (ID do projeto).

Para trocar de projeto, edite o `default` em `.firebaserc` ou use:

```bash
firebase use outro-projeto-id
```
