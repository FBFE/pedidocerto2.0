import { MenuItem } from './types';

export const menuStructure: MenuItem[] = [
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
    adminOnly: true,
    children: [
      { id: 'duplicados', label: 'Usuários Duplicados', icon: 'UserX', route: '/pc/duplicados' },
      { id: 'config', label: 'Configurações', icon: 'Sliders', route: '/pc/configuracoes' },
    ],
  },
];
