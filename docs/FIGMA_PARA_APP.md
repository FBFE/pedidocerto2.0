# Como exportar do Figma e usar no app Pedido Certo

## 1. Plano de fundo

**No Figma:**
- Selecione o **frame** ou a **área** que será o fundo (ex.: a tela inteira ou o retângulo de fundo).
- No painel direito, em **Export**:
  - Formato: **PNG** (o app aceita PNG normalmente; se o Figma tiver WebP, pode usar para arquivo menor).
  - Escala: **2x** (deixe em 2x como na sua tela).
- Clique em **Export** e salve o arquivo.

**No app:**
- **Opção A:** Configurações (engrenagem) → Upload de plano de fundo → selecione o arquivo exportado e envie.
- **Opção B:** Coloque o arquivo em `assets/backgrounds/` (ex.: `fundo_figma.png`) e avise para incluirmos no seletor de fundo.

---

## 2. Botões e elementos de interface

Dá para seguir por dois caminhos:

### Caminho A – Você exporta imagens e a gente usa no app

**No Figma:**
- Selecione cada **botão** ou **elemento** (ex.: botão “Aprovar”, ícone de configurações).
- Export com **PNG 2x** (ou **SVG** se for ícone/forma simples, sem texto).
- Salve com nome claro: `botao_aprovar.png`, `ic_configuracoes.svg`, etc.

**No projeto:**
- Botões/imagens: coloque em `assets/icons/png/` ou `assets/illustrations/`.
- Ícones em vetor: coloque em `assets/icons/svg/`.
- A partir daí dá para:
  - Trocar o plano de fundo da tela principal pela imagem exportada.
  - Usar as imagens dos botões (Image.asset) ou, no caso de SVG, exibir com um pacote como `flutter_svg`.

### Caminho B – Você manda o “desenho” e a gente replica em código (recomendado)

Em vez de exportar cada botão como imagem, você pode:

1. **Exportar uma tela inteira** (PNG 2x) do Figma como **referência visual**.
2. **Anotar** (ou mandar print do painel do Figma com):
   - Cores (ex.: fundo `#1E1E1E`, botão primário `#2563EB`).
   - Bordas (border radius dos botões/cards).
   - Tamanhos (altura do botão, padding).
   - Fonte e tamanho dos textos (nome da fonte, 14px, 16px, etc.).

Com isso, dá para **trocar no app**:
- Cores dos botões e do fundo.
- Estilo dos botões (cantos arredondados, sombra).
- Fonte e tamanhos de texto.

Ou seja: você desenha no Figma; a gente “traduz” esse desenho em tema (cores, bordas, fontes) e em widgets Flutter (botões, plano de fundo, etc.), sem depender de muitas imagens exportadas.

---

## 3. Resumo prático

| O que você quer | O que exportar no Figma | Onde colocar no projeto | O que a gente faz no sistema |
|-----------------|-------------------------|--------------------------|------------------------------|
| **Plano de fundo** | Frame/área em **PNG**, **2x** | Upload em Configurações ou `assets/backgrounds/` | Usar como fundo da tela principal (já está pronto). |
| **Botão como imagem** | Cada botão em **PNG 2x** | `assets/icons/png/` ou `assets/illustrations/` | Trocar botões do app por `Image.asset` ou `DecorationImage`. |
| **Ícone em vetor** | **SVG** | `assets/icons/svg/` | Exibir com `flutter_svg` e usar no lugar dos ícones atuais. |
| **Aparência geral (cores, bordas, fontes)** | **Print da tela** + **cores/estilos** anotados ou em screenshot do painel | Não precisa de pasta; você manda a referência | Ajustar tema (cores, bordas, fontes) e botões em código. |

---

## 4. O que você pode fazer agora

1. **Só fundo:** exporte o frame de fundo em PNG/WebP 2x e use em **Configurações → Upload de plano de fundo** (ou em `assets/backgrounds/`).
2. **Botões/ícones como imagem:** exporte cada um em PNG 2x (ou SVG para ícones), coloque em `assets/icons/` ou `assets/illustrations/` e diga quais telas/botões quer trocar; a gente conecta no código.
3. **Mudar cores/botões/fundo “no estilo” do Figma:** mande uma exportação da tela (PNG) +, se possível, as cores e o estilo dos botões (ou um print do painel de design do Figma); a gente adapta o tema e os widgets do sistema (plano de fundo, botões, etc.) para ficar igual ao layout.

Se você disser qual desses quer (só fundo, botões como imagem, ou “deixar igual ao Figma em cores e estilo”), mando os próximos passos exatos no seu projeto (arquivos e trechos de código para alterar).
