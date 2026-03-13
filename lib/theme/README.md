# Tema Pedido Certo (Style Guide)

Design system aplicado ao Flutter, alinhado ao **Style Guide for Flutter App** (Figma).

## Paleta de cores

| Token | Hex | Uso |
|-------|-----|-----|
| **Primary Blue** | `#1A73E8` | Botões principais, links, ícones ativos |
| **Teal Accent** | `#00897B` | Destaque alternativo |
| **White** | `#FFFFFF` | Fundo de cards, AppBar |
| **Scaffold** | `#F5F5F5` | Fundo da tela |
| **Medium Gray** | `#E0E0E0` | Bordas, divisores |
| **Success** | `#4CAF50` | Aprovado, vigente |
| **Warning** | `#FF9800` | Pendente |
| **Error** | `#F44336` | Rejeitado, cancelado |

## Tipografia

- **Headline**: 20px, peso 500 (títulos de página)
- **Title**: 16px, peso 600 (título de cards)
- **Body**: 14px, peso 400 (texto padrão)
- **Caption**: 12px, peso 400 (legendas)

## Espaçamentos

- **XS**: 4px  
- **S**: 8px  
- **M**: 16px  
- **L**: 24px  
- **XL**: 32px  

## Componentes

- **AppBar**: fundo branco, sombra suave (`elevation: 1`).
- **Cards**: branco, borda `#E0E0E0`, raio 8px.
- **Inputs**: raio 8px, borda de focus Primary Blue 2px.
- **Botões primários**: Primary Blue, raio 8px.

## Uso no código

```dart
import 'package:pedidocerto/theme/pedido_certo_theme.dart';

// Cores
PedidoCertoTheme.primaryBlue
PedidoCertoTheme.scaffoldBackground
PedidoCertoTheme.successGreen

// Espaçamentos
PedidoCertoTheme.spacingM
PedidoCertoTheme.radiusCard

// Status badges
PedidoCertoTheme.statusColor('Aprovado')  // => successGreen
```

O `ThemeData` completo está em `PedidoCertoTheme.theme` e é aplicado em `main.dart`.

## Responsividade

- **Breakpoint:** `PedidoCertoTheme.breakpointSidebarStack` (700px) — abaixo disso, prefira empilhar conteúdo (ex.: sidebar abaixo da lista).
- **Conteúdo:** Use `LayoutBuilder` para adaptar layout; evite larguras fixas que causem overflow.
- **Sidebar:** Calendário e cards devem respeitar `ConstrainedBox(maxWidth: sidebarWidth)` e botões podem virar só ícone em larguras pequenas.
