// Types for Pedido Certo System

export interface User {
  id: string;
  nome: string;
  email: string;
  cpf: string;
  status: 'Pendente' | 'Aprovado' | 'Rejeitado';
  perfil: 'Admin' | 'Gestor' | 'Usuário';
  unidade?: string;
  dataCriacao: string;
  avatar?: string;
}

export interface UnidadeHospitalar {
  id: string;
  nome: string;
  cnes: string;
  tipo: string;
  endereco: string;
  municipio: string;
  uf: string;
  status: 'Ativa' | 'Inativa';
}

export interface DFD {
  id: string;
  numero: string;
  descricao: string;
  status: 'Ativo' | 'Inativo';
  dataAtualizacao: string;
}

export interface Fornecedor {
  id: string;
  razaoSocial: string;
  cnpj: string;
  municipio: string;
  uf: string;
  status: 'Ativo' | 'Inativo';
  numeroAtas: number;
}

export interface Ata {
  id: string;
  numero: string;
  fornecedor: string;
  dataInicio: string;
  dataFim: string;
  valor: number;
  status: 'Vigente' | 'Vencida' | 'Cancelada';
  itens: number;
}

export interface MenuItem {
  id: string;
  label: string;
  icon: string;
  route: string;
  adminOnly?: boolean;
  children?: MenuItem[];
}
