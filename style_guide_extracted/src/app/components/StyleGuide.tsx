import { Check, Copy } from 'lucide-react';
import { useState } from 'react';

export default function StyleGuide() {
  const [copiedColor, setCopiedColor] = useState<string | null>(null);

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    setCopiedColor(label);
    setTimeout(() => setCopiedColor(null), 2000);
  };

  const colors = [
    { name: 'Primary Blue', value: '#1A73E8', usage: 'Botões principais, links, ícones ativos' },
    { name: 'Teal Accent', value: '#00897B', usage: 'Alternativa de destaque, estados de sucesso' },
    { name: 'White', value: '#FFFFFF', usage: 'Fundo de cards, AppBar, Bottom Navigation' },
    { name: 'Light Gray', value: '#F5F5F5', usage: 'Fundo da tela principal (Scaffold)' },
    { name: 'Medium Gray', value: '#E0E0E0', usage: 'Bordas, divisores' },
    { name: 'Dark Gray', value: '#424242', usage: 'Texto principal' },
    { name: 'Success Green', value: '#4CAF50', usage: 'Status positivo, aprovado' },
    { name: 'Warning Orange', value: '#FF9800', usage: 'Status pendente, atenção' },
    { name: 'Error Red', value: '#F44336', usage: 'Status negativo, erro' },
  ];

  const typography = [
    { name: 'Headline', size: '20px', weight: '500', usage: 'Títulos de página, AppBar' },
    { name: 'Title', size: '16px', weight: '600', usage: 'Título de cards, list items' },
    { name: 'Body', size: '14px', weight: '400', usage: 'Texto de corpo padrão' },
    { name: 'Caption', size: '12px', weight: '400', usage: 'Legendas, subtítulos secundários' },
    { name: 'Button', size: '14px', weight: '500', usage: 'Texto de botões' },
  ];

  const spacing = [
    { name: 'XS', value: '4px', usage: 'Espaçamento interno mínimo' },
    { name: 'S', value: '8px', usage: 'Espaçamento entre ícone e texto' },
    { name: 'M', value: '16px', usage: 'Padding padrão, margens laterais' },
    { name: 'L', value: '24px', usage: 'Espaçamento entre seções' },
    { name: 'XL', value: '32px', usage: 'Espaçamento entre grandes blocos' },
  ];

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Introduction */}
      <section className="mb-12">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">
          Visão Geral do Sistema de Design
        </h2>
        <p className="text-gray-600 mb-4">
          Este guia de estilo é inspirado na interface do AppSheet, focado em produtividade empresarial,
          alta densidade de informações e clareza visual. Ideal para aplicativos de gestão de dados,
          inventários, formulários e dashboards.
        </p>
        <div className="bg-blue-50 border-l-4 border-[#1A73E8] p-4 rounded">
          <p className="text-sm text-gray-700">
            <strong>Princípios de Design:</strong> Layout limpo, navegação intuitiva, 
            hierarquia visual clara e design responsivo para mobile e desktop.
          </p>
        </div>
      </section>

      {/* Color Palette */}
      <section className="mb-12">
        <h2 className="text-2xl font-semibold text-gray-900 mb-6">
          Paleta de Cores
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {colors.map((color) => (
            <div
              key={color.name}
              className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden"
            >
              <div
                className="h-24 w-full"
                style={{ backgroundColor: color.value }}
              />
              <div className="p-4">
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-semibold text-gray-900">{color.name}</h3>
                  <button
                    onClick={() => copyToClipboard(color.value, color.name)}
                    className="text-gray-400 hover:text-gray-600 transition-colors"
                    title="Copiar código hex"
                  >
                    {copiedColor === color.name ? (
                      <Check className="w-4 h-4 text-green-500" />
                    ) : (
                      <Copy className="w-4 h-4" />
                    )}
                  </button>
                </div>
                <p className="text-sm font-mono text-gray-600 mb-2">{color.value}</p>
                <p className="text-xs text-gray-500">{color.usage}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Typography */}
      <section className="mb-12">
        <h2 className="text-2xl font-semibold text-gray-900 mb-6">
          Tipografia
        </h2>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <p className="text-sm text-gray-600 mb-6">
            Fonte: <strong>Roboto</strong> ou <strong>Inter</strong> (use Inter quando disponível no projeto)
          </p>
          <div className="space-y-6">
            {typography.map((type) => (
              <div key={type.name} className="border-b border-gray-100 pb-4 last:border-b-0">
                <div className="flex items-baseline gap-4 mb-2">
                  <span
                    className="flex-1"
                    style={{
                      fontSize: type.size,
                      fontWeight: type.weight,
                    }}
                  >
                    {type.name} - The quick brown fox jumps over the lazy dog
                  </span>
                </div>
                <div className="flex gap-6 text-xs text-gray-500">
                  <span>Tamanho: {type.size}</span>
                  <span>Peso: {type.weight}</span>
                  <span className="flex-1">{type.usage}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Spacing */}
      <section className="mb-12">
        <h2 className="text-2xl font-semibold text-gray-900 mb-6">
          Espaçamentos
        </h2>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="space-y-4">
            {spacing.map((space) => (
              <div key={space.name} className="flex items-center gap-4">
                <div className="w-16 text-sm font-semibold text-gray-700">{space.name}</div>
                <div
                  className="bg-[#1A73E8] h-8"
                  style={{ width: space.value }}
                />
                <div className="text-sm text-gray-600">{space.value}</div>
                <div className="flex-1 text-sm text-gray-500">{space.usage}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Grid System */}
      <section className="mb-12">
        <h2 className="text-2xl font-semibold text-gray-900 mb-6">
          Sistema de Grid
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Mobile Grid */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="font-semibold text-gray-900 mb-4">Mobile (4 colunas)</h3>
            <div className="space-y-2 mb-4">
              <p className="text-sm text-gray-600">Margens: 16px</p>
              <p className="text-sm text-gray-600">Gutter: 16px</p>
            </div>
            <div className="grid grid-cols-4 gap-4">
              {[1, 2, 3, 4].map((col) => (
                <div key={col} className="bg-[#1A73E8] h-16 rounded flex items-center justify-center text-white text-sm">
                  {col}
                </div>
              ))}
            </div>
          </div>

          {/* Desktop Grid */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="font-semibold text-gray-900 mb-4">Desktop/Tablet (12 colunas)</h3>
            <div className="space-y-2 mb-4">
              <p className="text-sm text-gray-600">Margens: 24px</p>
              <p className="text-sm text-gray-600">Gutter: 16px</p>
            </div>
            <div className="grid grid-cols-12 gap-2">
              {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map((col) => (
                <div key={col} className="bg-[#00897B] h-12 rounded flex items-center justify-center text-white text-xs">
                  {col}
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Flutter Code Example */}
      <section className="mb-12">
        <h2 className="text-2xl font-semibold text-gray-900 mb-6">
          Código Flutter - ThemeData
        </h2>
        <div className="bg-gray-900 rounded-lg p-6 overflow-x-auto">
          <pre className="text-sm text-gray-100">
            <code>{`ThemeData appSheetStyle = ThemeData(
  // Cores principais
  primaryColor: Color(0xFF1A73E8),
  scaffoldBackgroundColor: Color(0xFFF5F5F5),
  
  // AppBar
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 1,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    ),
  ),
  
  // Cards
  cardTheme: CardTheme(
    elevation: 0.5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  ),
  
  // Bottom Navigation
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Color(0xFF1A73E8),
    unselectedItemColor: Colors.grey[600],
    elevation: 8,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(fontSize: 12),
    unselectedLabelStyle: TextStyle(fontSize: 12),
  ),
  
  // Input Decoration
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xFF1A73E8), width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: TextStyle(fontSize: 14),
  ),
  
  // Floating Action Button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF1A73E8),
    foregroundColor: Colors.white,
    elevation: 6,
  ),
);`}</code>
          </pre>
        </div>
      </section>
    </div>
  );
}
