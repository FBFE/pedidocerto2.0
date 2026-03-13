# Sistema Pedido Certo - Guia de Estilo e Componentes

## 📋 Visão Geral

O **Pedido Certo** é um sistema de gestão hospitalar governamental inspirado no design do AppSheet, focado em produtividade, alta densidade de informações e interface limpa.

## 🎨 Design System

### Paleta de Cores

| Cor                | Hex       | Uso                                     |
| ------------------ | --------- | --------------------------------------- |
| **Primary Blue**   | `#1A73E8` | Botões principais, links, ícones ativos |
| **Teal Accent**    | `#00897B` | Alternativa de destaque                 |
| **White**          | `#FFFFFF` | Fundo de cards, AppBar                  |
| **Light Gray**     | `#F5F5F5` | Fundo da tela (Scaffold)                |
| **Medium Gray**    | `#E0E0E0` | Bordas, divisores                       |
| **Success Green**  | `#4CAF50` | Status aprovado, vigente                |
| **Warning Orange** | `#FF9800` | Status pendente                         |
| **Error Red**      | `#F44336` | Status rejeitado, cancelado             |

### Tipografia

- **Fonte**: Roboto ou Inter
- **Headline**: 20px, peso 500 (Títulos de página)
- **Title**: 16px, peso 600 (Título de cards)
- **Body**: 14px, peso 400 (Texto padrão)
- **Caption**: 12px, peso 400 (Legendas)

### Espaçamentos

- **XS**: 4px (Mínimo)
- **S**: 8px (Ícone + texto)
- **M**: 16px (Padding padrão)
- **L**: 24px (Entre seções)
- **XL**: 32px (Grandes blocos)

## 🏗️ Estrutura do Sistema

### Arquitetura de Navegação

O sistema utiliza uma **navegação lateral (Drawer)** para acomodar as 37+ telas organizadas em módulos:

1. **Autenticação**
   - Login
   - Criar conta

2. **Usuários**
   - Usuários do Sistema (Home)
   - Meus dados
   - Usuários duplicados (Admin)

3. **Cadastros**
   - Organograma (Governo → Secretarias → Unidades)
   - DFD
   - Unidades Hospitalares
   - Fornecedores
   - Banco de Atas

4. **Tabelas de Referência**
   - Procedimentos SIGTAP
   - Medicamentos CATMED
   - Equipamentos RENEM

5. **Relatórios e Painéis**
   - Painel Tático
   - Painel SGS
   - Relatórios de Custo

6. **Administração**
   - Configurações
   - Usuários Duplicados

## 🧩 Componentes Principais

### 1. AppBar (Barra Superior)

```tsx
<header className="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
  <div className="flex items-center justify-between px-4 py-3">
    {/* Logo + Título */}
    {/* Ações: Notificações, Busca, Perfil */}
  </div>
</header>
```

**Características:**

- Fundo branco com sombra suave
- Logo à esquerda
- Ações rápidas à direita
- Sticky no topo

### 2. Drawer (Navegação Lateral)

```tsx
<aside className="w-64 bg-white border-r border-gray-200">
  {/* Menu hierárquico com expansão */}
</aside>
```

**Características:**

- Menu expansível com subitens
- Indicador visual de página ativa
- Responsivo (overlay no mobile)
- Ícones + labels

### 3. Cards de Lista

```tsx
<div className="bg-white rounded-lg border border-gray-200 p-4 hover:shadow-md">
  {/* Conteúdo do card */}
</div>
```

**Características:**

- Bordas arredondadas (8px)
- Hover com elevação
- Status badges color-coded
- Ações rápidas visíveis

### 4. Tabelas de Dados

```tsx
<table className="w-full">
  <thead className="bg-gray-50 border-b">
    {/* Cabeçalhos */}
  </thead>
  <tbody className="divide-y">{/* Linhas de dados */}</tbody>
</table>
```

**Características:**

- Cabeçalho fixo com fundo cinza
- Hover em linhas
- Ações inline
- Responsivo com scroll horizontal

### 5. Formulários

```tsx
<div>
  <label className="block text-sm font-medium text-gray-700 mb-2">
    Label do Campo
  </label>
  <input className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8]" />
</div>
```

**Características:**

- Labels claros acima do campo
- Bordas suaves (8px)
- Focus state destacado
- Suporte a seleção rápida (Enum)

### 6. Status Badges

```tsx
<span className="px-2 py-0.5 text-xs font-medium rounded-full bg-green-100 text-green-800">
  Aprovado
</span>
```

**Estados:**

- **Verde**: Aprovado, Vigente, Ativo
- **Laranja**: Pendente, Em análise
- **Vermelho**: Rejeitado, Cancelado, Atrasado
- **Azul**: Em progresso
- **Cinza**: Inativo, Vencido

### 7. Cards de Estatísticas

```tsx
<div className="bg-white rounded-lg border border-gray-200 p-4">
  <p className="text-sm text-gray-600">Label</p>
  <p className="text-2xl font-semibold text-gray-900 mt-1">
    Valor
  </p>
  {/* Ícone opcional */}
</div>
```

## 📱 Responsividade

### Grid System

**Mobile (< 768px)**

- 4 colunas
- Margens: 16px
- Gutter: 16px
- Drawer overlay

**Desktop (≥ 768px)**

- 12 colunas
- Margens: 24px
- Gutter: 16px
- Drawer fixo lateral

### Breakpoints

```css
sm: 640px   /* Tablet pequeno */
md: 768px   /* Tablet */
lg: 1024px  /* Desktop */
xl: 1280px  /* Desktop grande */
```

## 🎯 Telas Implementadas

### ✅ Telas Criadas

1. **LoginScreen** - Autenticação de usuários
2. **UsuariosScreen** - Gestão e aprovação de usuários
3. **OrganogramaScreen** - Estrutura hierárquica organizacional
4. **UnidadesHospitalaresScreen** - Cadastro de unidades de saúde
5. **DFDListScreen** - Lista de DFDs
6. **FornecedoresScreen** - Cadastro de fornecedores
7. **AtasScreen** - Banco de atas de registro de preços
8. **ConfiguracoesScreen** - Preferências do sistema

### 📝 Telas Pendentes (a implementar)

- Criar conta (register_screen)
- Atualizar dados (atualizar_dados_screen)
- Formulários de governo, unidades, DFD
- Importações (SIGTAP, CATMED, RENEM, Custo)
- Painéis (Tático, SGS)
- Relatórios de custo
- Detalhe e edição de atas
- Busca PNCP
- E mais...

## 🛠️ Tecnologias

- **React** 18.3.1
- **TypeScript**
- **React Router** 7.13.0
- **Tailwind CSS** 4.1.12
- **Lucide React** (ícones)

## 🚀 Como Usar

### Estrutura de Arquivos

```
/src/app/
  ├── routes-pc.ts                    # Rotas do sistema
  ├── App.tsx                         # Componente raiz
  └── components/
      └── pedido-certo/
          ├── types.ts                # TypeScript types
          ├── menuStructure.ts        # Estrutura do menu
          ├── RootPC.tsx              # Layout principal
          ├── LoginScreen.tsx
          ├── UsuariosScreen.tsx
          ├── OrganogramaScreen.tsx
          ├── UnidadesHospitalaresScreen.tsx
          ├── DFDListScreen.tsx
          ├── FornecedoresScreen.tsx
          ├── AtasScreen.tsx
          └── ConfiguracoesScreen.tsx
```

### Adicionar Nova Tela

1. Criar o componente em `/src/app/components/pedido-certo/NomeTela.tsx`
2. Adicionar a rota em `/src/app/routes-pc.ts`
3. Adicionar item no menu em `menuStructure` (se necessário)

Exemplo:

```tsx
// 1. Criar NovaTela.tsx
export default function NovaTela() {
  return (
    <div className="p-6">
      <h1 className="text-2xl font-semibold text-gray-900 mb-2">
        Título da Tela
      </h1>
      {/* Conteúdo */}
    </div>
  );
}

// 2. Adicionar em routes-pc.ts
import NovaTela from "./components/pedido-certo/NovaTela";

children: [
  // ... outras rotas
  { path: "nova-tela", Component: NovaTela },
]

// 3. Adicionar em menuStructure (RootPC.tsx)
{
  id: 'nova-tela',
  label: 'Nova Tela',
  icon: 'FileText',
  route: '/pc/nova-tela',
}
```

## 📊 Código Flutter - ThemeData

```dart
ThemeData appSheetStyle = ThemeData(
  primaryColor: Color(0xFF1A73E8),
  scaffoldBackgroundColor: Color(0xFFF5F5F5),

  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 1,
  ),

  cardTheme: CardTheme(
    elevation: 0.5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xFF1A73E8), width: 2),
    ),
  ),
);
```

## ✅ Checklist de Implementação

### Fase 1: Estrutura Base ✓

- [x] Sistema de cores
- [x] Tipografia
- [x] Layout base (AppBar + Drawer)
- [x] Sistema de rotas
- [x] Menu de navegação

### Fase 2: Telas Principais ✓

- [x] Login
- [x] Usuários
- [x] Organograma
- [x] Unidades Hospitalares
- [x] DFD
- [x] Fornecedores
- [x] Banco de Atas
- [x] Configurações

### Fase 3: Funcionalidades Avançadas (Pendente)

- [ ] Importações (SIGTAP, CATMED, RENEM)
- [ ] Painéis e dashboards
- [ ] Relatórios
- [ ] Busca PNCP
- [ ] Gestão de custos
- [ ] Edição de atas

### Fase 4: Refinamento (Pendente)

- [ ] Validações de formulário
- [ ] Feedback visual (toasts)
- [ ] Loading states
- [ ] Tratamento de erros
- [ ] Otimizações de performance

## 📝 Boas Práticas

1. **Consistência Visual**: Use sempre os componentes base definidos
2. **Responsividade**: Teste em mobile e desktop
3. **Acessibilidade**: Labels claros, contraste adequado
4. **Performance**: Evite re-renders desnecessários
5. **Código Limpo**: Componentes pequenos e reutilizáveis

## 🎓 Referências

- [AppSheet Design](https://about.appsheet.com/)
- [Material Design Guidelines](https://m3.material.io/)
- [Tailwind CSS Docs](https://tailwindcss.com/)
- [React Router Docs](https://reactrouter.com/)

---

**Desenvolvido com foco em produtividade e experiência do usuário governamental.**