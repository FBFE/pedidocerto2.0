import { Search, User, Home, Database, Map, BarChart3, Menu, Plus, Filter, ChevronRight } from 'lucide-react';

export default function Components() {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <h2 className="text-2xl font-semibold text-gray-900 mb-8">
        Componentes Principais
      </h2>

      {/* AppBar */}
      <section className="mb-12">
        <h3 className="text-xl font-semibold text-gray-900 mb-4">
          1. AppBar (Barra Superior)
        </h3>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="border-b border-gray-200 p-4 bg-gray-50">
            <p className="text-sm text-gray-600">
              Barra superior simples com título, botão de busca e ícone de perfil
            </p>
          </div>
          
          {/* AppBar Examples */}
          <div className="p-6 space-y-4">
            {/* Example 1: Title Left */}
            <div className="border border-gray-200 rounded-lg overflow-hidden">
              <div className="bg-white shadow-sm flex items-center justify-between px-4 py-3">
                <h4 className="text-lg font-medium text-gray-900">Meus Projetos</h4>
                <div className="flex items-center gap-2">
                  <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                    <Search className="w-5 h-5 text-gray-600" />
                  </button>
                  <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                    <User className="w-5 h-5 text-gray-600" />
                  </button>
                </div>
              </div>
            </div>

            {/* Example 2: Title Center */}
            <div className="border border-gray-200 rounded-lg overflow-hidden">
              <div className="bg-white shadow-sm flex items-center justify-between px-4 py-3">
                <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                  <Menu className="w-5 h-5 text-gray-600" />
                </button>
                <h4 className="text-lg font-medium text-gray-900">Dashboard</h4>
                <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                  <Filter className="w-5 h-5 text-gray-600" />
                </button>
              </div>
            </div>
          </div>

          {/* Code */}
          <div className="bg-gray-900 p-4">
            <pre className="text-xs text-gray-100 overflow-x-auto">
              <code>{`AppBar(
  backgroundColor: Colors.white,
  elevation: 1,
  title: Text('Meus Projetos'),
  actions: [
    IconButton(icon: Icon(Icons.search), onPressed: () {}),
    IconButton(icon: Icon(Icons.account_circle), onPressed: () {}),
  ],
)`}</code>
            </pre>
          </div>
        </div>
      </section>

      {/* Bottom Navigation */}
      <section className="mb-12">
        <h3 className="text-xl font-semibold text-gray-900 mb-4">
          2. Bottom Navigation (Navegação Inferior)
        </h3>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="border-b border-gray-200 p-4 bg-gray-50">
            <p className="text-sm text-gray-600">
              Até 5 ícones com labels claros para navegação principal
            </p>
          </div>
          
          <div className="p-6">
            <div className="border border-gray-200 rounded-lg overflow-hidden max-w-md mx-auto">
              <div className="bg-white shadow-lg flex items-center justify-around px-2 py-3">
                <button className="flex flex-col items-center gap-1 flex-1 text-[#1A73E8]">
                  <Home className="w-6 h-6" />
                  <span className="text-xs font-medium">Home</span>
                </button>
                <button className="flex flex-col items-center gap-1 flex-1 text-gray-500">
                  <Database className="w-6 h-6" />
                  <span className="text-xs">Dados</span>
                </button>
                <button className="flex flex-col items-center gap-1 flex-1 text-gray-500">
                  <Map className="w-6 h-6" />
                  <span className="text-xs">Mapas</span>
                </button>
                <button className="flex flex-col items-center gap-1 flex-1 text-gray-500">
                  <BarChart3 className="w-6 h-6" />
                  <span className="text-xs">Dashboards</span>
                </button>
                <button className="flex flex-col items-center gap-1 flex-1 text-gray-500">
                  <Menu className="w-6 h-6" />
                  <span className="text-xs">Menu</span>
                </button>
              </div>
            </div>
          </div>

          <div className="bg-gray-900 p-4">
            <pre className="text-xs text-gray-100 overflow-x-auto">
              <code>{`BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  currentIndex: 0,
  selectedItemColor: Color(0xFF1A73E8),
  unselectedItemColor: Colors.grey[600],
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.database), label: 'Dados'),
    BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapas'),
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboards'),
    BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
  ],
)`}</code>
            </pre>
          </div>
        </div>
      </section>

      {/* Deck View Cards */}
      <section className="mb-12">
        <h3 className="text-xl font-semibold text-gray-900 mb-4">
          3. Deck View (Visualização em Cards)
        </h3>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="border-b border-gray-200 p-4 bg-gray-50">
            <p className="text-sm text-gray-600">
              Cards compactos com thumbnail à esquerda, título em negrito, dois subtítulos e status color-coded
            </p>
          </div>
          
          <div className="p-6 space-y-3">
            {/* Card Example 1 */}
            <div className="bg-white border border-gray-200 rounded-lg p-3 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex gap-3">
                {/* Thumbnail */}
                <div className="w-16 h-16 bg-gray-200 rounded flex-shrink-0 overflow-hidden">
                  <img 
                    src="https://images.unsplash.com/photo-1716703432455-3045789de738?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxidXNpbmVzcyUyMG1lZXRpbmclMjB0ZWFtfGVufDF8fHx8MTc3MzMzNzc0MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                    alt="Project" 
                    className="w-full h-full object-cover"
                  />
                </div>
                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <h4 className="font-semibold text-gray-900 truncate">Projeto Alpha - Q1 2026</h4>
                    <span className="px-2 py-0.5 bg-green-100 text-green-800 text-xs font-medium rounded-full whitespace-nowrap">
                      Aprovado
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mt-1">Cliente: Tech Solutions Inc.</p>
                  <p className="text-xs text-gray-500 mt-0.5">Atualizado: 12/03/2026</p>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400 flex-shrink-0" />
              </div>
            </div>

            {/* Card Example 2 */}
            <div className="bg-white border border-gray-200 rounded-lg p-3 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex gap-3">
                <div className="w-16 h-16 bg-gray-200 rounded flex-shrink-0 overflow-hidden">
                  <img 
                    src="https://images.unsplash.com/photo-1623679072629-3aaa0192a391?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxvZmZpY2UlMjB3b3Jrc3BhY2UlMjBkZXNrfGVufDF8fHx8MTc3MzMwOTQ5Nnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                    alt="Project" 
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <h4 className="font-semibold text-gray-900 truncate">Inventário Warehouse 2</h4>
                    <span className="px-2 py-0.5 bg-orange-100 text-orange-800 text-xs font-medium rounded-full whitespace-nowrap">
                      Pendente
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mt-1">Responsável: Maria Silva</p>
                  <p className="text-xs text-gray-500 mt-0.5">Atualizado: 11/03/2026</p>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400 flex-shrink-0" />
              </div>
            </div>

            {/* Card Example 3 */}
            <div className="bg-white border border-gray-200 rounded-lg p-3 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex gap-3">
                <div className="w-16 h-16 bg-gray-200 rounded flex-shrink-0 overflow-hidden">
                  <img 
                    src="https://images.unsplash.com/photo-1710585761854-57ff6839395c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb25zdHJ1Y3Rpb24lMjBzaXRlJTIwcHJvamVjdHxlbnwxfHx8fDE3NzM0MTAxODN8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" 
                    alt="Project" 
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <h4 className="font-semibold text-gray-900 truncate">Construção Sede Norte</h4>
                    <span className="px-2 py-0.5 bg-red-100 text-red-800 text-xs font-medium rounded-full whitespace-nowrap">
                      Atrasado
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mt-1">Orçamento: R$ 2.5M</p>
                  <p className="text-xs text-gray-500 mt-0.5">Atualizado: 10/03/2026</p>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400 flex-shrink-0" />
              </div>
            </div>
          </div>

          <div className="bg-gray-900 p-4">
            <pre className="text-xs text-gray-100 overflow-x-auto">
              <code>{`ListTile(
  leading: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover),
  ),
  title: Text('Projeto Alpha - Q1 2026', style: TextStyle(fontWeight: FontWeight.w600)),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Cliente: Tech Solutions Inc.', style: TextStyle(fontSize: 14)),
      Text('Atualizado: 12/03/2026', style: TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  ),
  trailing: Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.green[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text('Aprovado', style: TextStyle(fontSize: 12, color: Colors.green[800])),
  ),
  onTap: () {},
)`}</code>
            </pre>
          </div>
        </div>
      </section>

      {/* Forms */}
      <section className="mb-12">
        <h3 className="text-xl font-semibold text-gray-900 mb-4">
          4. Formulários
        </h3>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="border-b border-gray-200 p-4 bg-gray-50">
            <p className="text-sm text-gray-600">
              Inputs com bordas suaves, labels claros e suporte a Enum (seleção rápida)
            </p>
          </div>
          
          <div className="p-6 max-w-lg">
            <div className="space-y-4">
              {/* Text Input */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Nome do Projeto
                </label>
                <input
                  type="text"
                  placeholder="Digite o nome do projeto"
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none transition-colors"
                />
              </div>

              {/* Dropdown */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Categoria
                </label>
                <select className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none transition-colors bg-white">
                  <option>Selecione uma categoria</option>
                  <option>Infraestrutura</option>
                  <option>Tecnologia</option>
                  <option>Recursos Humanos</option>
                </select>
              </div>

              {/* Enum (Quick Selection Buttons) */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Prioridade
                </label>
                <div className="flex gap-2">
                  <button className="flex-1 px-4 py-2 border-2 border-gray-300 rounded-lg hover:border-[#1A73E8] hover:bg-blue-50 transition-colors">
                    Baixa
                  </button>
                  <button className="flex-1 px-4 py-2 border-2 border-[#1A73E8] bg-blue-50 text-[#1A73E8] rounded-lg font-medium">
                    Média
                  </button>
                  <button className="flex-1 px-4 py-2 border-2 border-gray-300 rounded-lg hover:border-[#1A73E8] hover:bg-blue-50 transition-colors">
                    Alta
                  </button>
                </div>
              </div>

              {/* Textarea */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Descrição
                </label>
                <textarea
                  placeholder="Adicione uma descrição detalhada"
                  rows={4}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none transition-colors resize-none"
                />
              </div>

              {/* Submit Button */}
              <button className="w-full bg-[#1A73E8] text-white py-3 rounded-lg font-medium hover:bg-[#1557B0] transition-colors">
                Salvar Projeto
              </button>
            </div>
          </div>

          <div className="bg-gray-900 p-4">
            <pre className="text-xs text-gray-100 overflow-x-auto">
              <code>{`TextFormField(
  decoration: InputDecoration(
    labelText: 'Nome do Projeto',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
)

// Enum com botões de seleção rápida
Wrap(
  spacing: 8,
  children: ['Baixa', 'Média', 'Alta'].map((priority) => 
    ChoiceChip(
      label: Text(priority),
      selected: selectedPriority == priority,
      onSelected: (selected) => setState(() => selectedPriority = priority),
    ),
  ).toList(),
)`}</code>
            </pre>
          </div>
        </div>
      </section>

      {/* FAB */}
      <section className="mb-12">
        <h3 className="text-xl font-semibold text-gray-900 mb-4">
          5. Floating Action Button (FAB)
        </h3>
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="border-b border-gray-200 p-4 bg-gray-50">
            <p className="text-sm text-gray-600">
              Botão de ação principal no canto inferior direito
            </p>
          </div>
          
          <div className="p-6">
            <div className="relative border border-gray-200 rounded-lg h-64 bg-gray-50">
              <button className="absolute bottom-4 right-4 w-14 h-14 bg-[#1A73E8] text-white rounded-full shadow-lg hover:bg-[#1557B0] transition-colors flex items-center justify-center">
                <Plus className="w-6 h-6" />
              </button>
              <div className="absolute inset-0 flex items-center justify-center text-gray-400 text-sm">
                Área de conteúdo
              </div>
            </div>
          </div>

          <div className="bg-gray-900 p-4">
            <pre className="text-xs text-gray-100 overflow-x-auto">
              <code>{`Scaffold(
  floatingActionButton: FloatingActionButton(
    onPressed: () {},
    backgroundColor: Color(0xFF1A73E8),
    child: Icon(Icons.add),
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
)`}</code>
            </pre>
          </div>
        </div>
      </section>
    </div>
  );
}
