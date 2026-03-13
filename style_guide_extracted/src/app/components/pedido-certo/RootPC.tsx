import { useState } from 'react';
import { Outlet, Link, useLocation, useNavigate } from 'react-router';
import { 
  Menu, 
  X, 
  Search, 
  Bell, 
  User,
  LogOut,
  Users,
  Database,
  GitBranch,
  FileText,
  Building2,
  FileCheck,
  Table2,
  Stethoscope,
  Pill,
  Monitor,
  BarChart3,
  TrendingUp,
  Activity,
  DollarSign,
  Settings,
  UserX,
  Sliders,
  ChevronDown,
  ChevronRight,
  Hospital,
} from 'lucide-react';

const iconMap: Record<string, any> = {
  Users, Database, GitBranch, FileText, Building2, FileCheck,
  Table2, Stethoscope, Pill, Monitor, BarChart3, TrendingUp,
  Activity, DollarSign, Settings, UserX, Sliders, Hospital,
};

interface MenuItem {
  id: string;
  label: string;
  icon: string;
  route: string;
  adminOnly?: boolean;
  children?: MenuItem[];
}

const menuStructure: MenuItem[] = [
  {
    id: 'home',
    label: 'Usuários do Sistema',
    icon: 'Users',
    route: '/pc/usuarios',
  },
  {
    id: 'cadastros',
    label: 'Cadastros',
    icon: 'Database',
    route: '#',
    children: [
      { id: 'organograma', label: 'Organograma', icon: 'GitBranch', route: '/pc/organograma' },
      { id: 'dfd', label: 'DFD', icon: 'FileText', route: '/pc/dfd' },
      { id: 'unidades', label: 'Unidades Hospitalares', icon: 'Hospital', route: '/pc/unidades' },
      { id: 'fornecedores', label: 'Fornecedores', icon: 'Building2', route: '/pc/fornecedores' },
      { id: 'atas', label: 'Banco de Atas', icon: 'FileCheck', route: '/pc/atas' },
    ],
  },
  {
    id: 'tabelas',
    label: 'Tabelas de Referência',
    icon: 'Table2',
    route: '#',
    children: [
      { id: 'sigtap', label: 'Procedimentos SIGTAP', icon: 'Stethoscope', route: '/pc/sigtap' },
      { id: 'catmed', label: 'Medicamentos CATMED', icon: 'Pill', route: '/pc/catmed' },
      { id: 'renem', label: 'Equipamentos RENEM', icon: 'Monitor', route: '/pc/renem' },
    ],
  },
  {
    id: 'relatorios',
    label: 'Relatórios e Painéis',
    icon: 'BarChart3',
    route: '#',
    children: [
      { id: 'painel-tatico', label: 'Painel Tático', icon: 'TrendingUp', route: '/pc/painel-tatico' },
      { id: 'painel-sgs', label: 'Painel SGS', icon: 'Activity', route: '/pc/painel-sgs' },
      { id: 'relatorio-custo', label: 'Relatórios de Custo', icon: 'DollarSign', route: '/pc/relatorio-custo' },
    ],
  },
  {
    id: 'admin',
    label: 'Administração',
    icon: 'Settings',
    route: '#',
    children: [
      { id: 'duplicados', label: 'Usuários Duplicados', icon: 'UserX', route: '/pc/duplicados' },
      { id: 'config', label: 'Configurações', icon: 'Sliders', route: '/pc/configuracoes' },
    ],
  },
];

export default function RootPC() {
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [expandedMenus, setExpandedMenus] = useState<string[]>(['cadastros']);
  const location = useLocation();
  const navigate = useNavigate();

  const toggleMenu = (menuId: string) => {
    setExpandedMenus(prev =>
      prev.includes(menuId)
        ? prev.filter(id => id !== menuId)
        : [...prev, menuId]
    );
  };

  const handleLogout = () => {
    navigate('/');
  };

  const renderMenuItem = (item: MenuItem, level = 0) => {
    const Icon = iconMap[item.icon];
    const isActive = location.pathname === item.route;
    const isExpanded = expandedMenus.includes(item.id);
    const hasChildren = item.children && item.children.length > 0;

    if (hasChildren) {
      return (
        <div key={item.id}>
          <button
            onClick={() => toggleMenu(item.id)}
            className={`w-full flex items-center justify-between px-4 py-3 text-gray-700 hover:bg-gray-100 transition-colors ${
              level > 0 ? 'pl-8' : ''
            }`}
          >
            <div className="flex items-center gap-3">
              <Icon className="w-5 h-5" />
              <span className="text-sm font-medium">{item.label}</span>
            </div>
            {isExpanded ? (
              <ChevronDown className="w-4 h-4" />
            ) : (
              <ChevronRight className="w-4 h-4" />
            )}
          </button>
          {isExpanded && (
            <div className="bg-gray-50">
              {item.children!.map(child => renderMenuItem(child, level + 1))}
            </div>
          )}
        </div>
      );
    }

    return (
      <Link
        key={item.id}
        to={item.route}
        onClick={() => setDrawerOpen(false)}
        className={`flex items-center gap-3 px-4 py-3 text-sm transition-colors ${
          level > 0 ? 'pl-12' : ''
        } ${
          isActive
            ? 'bg-blue-50 text-[#1A73E8] font-medium border-r-4 border-[#1A73E8]'
            : 'text-gray-700 hover:bg-gray-100'
        }`}
      >
        <Icon className="w-5 h-5" />
        {item.label}
      </Link>
    );
  };

  return (
    <div className="min-h-screen bg-[#F5F5F5]">
      {/* AppBar */}
      <header className="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
        <div className="flex items-center justify-between px-4 py-3">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setDrawerOpen(!drawerOpen)}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors lg:hidden"
            >
              <Menu className="w-6 h-6 text-gray-600" />
            </button>
            <div className="flex items-center gap-2">
              <div className="bg-[#1A73E8] w-8 h-8 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-sm">PC</span>
              </div>
              <h1 className="text-lg font-semibold text-gray-900 hidden sm:block">
                Pedido Certo
              </h1>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors relative">
              <Bell className="w-5 h-5 text-gray-600" />
              <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
            </button>
            <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
              <Search className="w-5 h-5 text-gray-600" />
            </button>
            <div className="h-8 w-px bg-gray-300 mx-1"></div>
            <div className="flex items-center gap-2 px-2 py-1 hover:bg-gray-100 rounded-lg cursor-pointer transition-colors">
              <div className="w-8 h-8 bg-[#1A73E8] rounded-full flex items-center justify-center">
                <User className="w-5 h-5 text-white" />
              </div>
              <span className="text-sm font-medium text-gray-700 hidden md:block">Admin</span>
            </div>
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Sidebar - Desktop */}
        <aside className="hidden lg:block w-64 bg-white border-r border-gray-200 min-h-[calc(100vh-57px)] sticky top-[57px]">
          <nav className="py-4 overflow-y-auto max-h-[calc(100vh-57px)]">
            {menuStructure.map(item => renderMenuItem(item))}
            
            <div className="border-t border-gray-200 mt-4 pt-4">
              <button
                onClick={handleLogout}
                className="w-full flex items-center gap-3 px-4 py-3 text-sm text-red-600 hover:bg-red-50 transition-colors"
              >
                <LogOut className="w-5 h-5" />
                Sair do sistema
              </button>
            </div>
          </nav>
        </aside>

        {/* Drawer - Mobile */}
        {drawerOpen && (
          <>
            <div
              className="fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden"
              onClick={() => setDrawerOpen(false)}
            />
            <aside className="fixed left-0 top-0 bottom-0 w-72 bg-white z-50 shadow-2xl lg:hidden overflow-y-auto">
              <div className="flex items-center justify-between p-4 border-b border-gray-200">
                <div className="flex items-center gap-2">
                  <div className="bg-[#1A73E8] w-8 h-8 rounded-lg flex items-center justify-center">
                    <span className="text-white font-bold text-sm">PC</span>
                  </div>
                  <h2 className="font-semibold text-gray-900">Menu</h2>
                </div>
                <button
                  onClick={() => setDrawerOpen(false)}
                  className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-gray-600" />
                </button>
              </div>
              
              <nav className="py-4">
                {menuStructure.map(item => renderMenuItem(item))}
                
                <div className="border-t border-gray-200 mt-4 pt-4">
                  <button
                    onClick={handleLogout}
                    className="w-full flex items-center gap-3 px-4 py-3 text-sm text-red-600 hover:bg-red-50 transition-colors"
                  >
                    <LogOut className="w-5 h-5" />
                    Sair do sistema
                  </button>
                </div>
              </nav>
            </aside>
          </>
        )}

        {/* Main Content */}
        <main className="flex-1 min-h-[calc(100vh-57px)]">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
