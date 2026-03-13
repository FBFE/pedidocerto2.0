import { useState } from 'react';
import { Check, X, Filter, Download, UserPlus, MoreVertical } from 'lucide-react';

interface User {
  id: string;
  nome: string;
  email: string;
  cpf: string;
  status: 'Pendente' | 'Aprovado' | 'Rejeitado';
  perfil: 'Admin' | 'Gestor' | 'Usuário';
  unidade?: string;
  dataCriacao: string;
}

export default function UsuariosScreen() {
  const [filtroStatus, setFiltroStatus] = useState<string>('Todos');
  
  const usuarios: User[] = [
    {
      id: '1',
      nome: 'Maria Silva Santos',
      email: 'maria.silva@saude.gov.br',
      cpf: '123.456.789-00',
      status: 'Pendente',
      perfil: 'Usuário',
      unidade: 'Hospital Central',
      dataCriacao: '10/03/2026',
    },
    {
      id: '2',
      nome: 'João Pedro Costa',
      email: 'joao.costa@saude.gov.br',
      cpf: '987.654.321-00',
      status: 'Aprovado',
      perfil: 'Gestor',
      unidade: 'UPA Norte',
      dataCriacao: '08/03/2026',
    },
    {
      id: '3',
      nome: 'Ana Paula Oliveira',
      email: 'ana.oliveira@saude.gov.br',
      cpf: '456.789.123-00',
      status: 'Pendente',
      perfil: 'Usuário',
      unidade: 'Hospital Regional',
      dataCriacao: '12/03/2026',
    },
    {
      id: '4',
      nome: 'Carlos Eduardo Lima',
      email: 'carlos.lima@saude.gov.br',
      cpf: '321.654.987-00',
      status: 'Aprovado',
      perfil: 'Admin',
      unidade: 'Secretaria de Saúde',
      dataCriacao: '05/03/2026',
    },
    {
      id: '5',
      nome: 'Fernanda Martins',
      email: 'fernanda.martins@saude.gov.br',
      cpf: '159.753.486-00',
      status: 'Rejeitado',
      perfil: 'Usuário',
      unidade: 'Posto de Saúde Sul',
      dataCriacao: '07/03/2026',
    },
  ];

  const handleAprovar = (userId: string) => {
    console.log('Aprovar usuário:', userId);
  };

  const handleRejeitar = (userId: string) => {
    console.log('Rejeitar usuário:', userId);
  };

  const getStatusBadge = (status: string) => {
    const styles = {
      Pendente: 'bg-orange-100 text-orange-800',
      Aprovado: 'bg-green-100 text-green-800',
      Rejeitado: 'bg-red-100 text-red-800',
    };
    return styles[status as keyof typeof styles] || styles.Pendente;
  };

  const getPerfilBadge = (perfil: string) => {
    const styles = {
      Admin: 'bg-purple-100 text-purple-800',
      Gestor: 'bg-blue-100 text-blue-800',
      Usuário: 'bg-gray-100 text-gray-800',
    };
    return styles[perfil as keyof typeof styles] || styles.Usuário;
  };

  const usuariosFiltrados = filtroStatus === 'Todos' 
    ? usuarios 
    : usuarios.filter(u => u.status === filtroStatus);

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-semibold text-gray-900 mb-2">
          Usuários do Sistema
        </h1>
        <p className="text-gray-600">
          Gerencie usuários, aprovações e permissões do sistema
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total de Usuários</p>
              <p className="text-2xl font-semibold text-gray-900 mt-1">
                {usuarios.length}
              </p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <UserPlus className="w-6 h-6 text-[#1A73E8]" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Pendentes</p>
              <p className="text-2xl font-semibold text-orange-600 mt-1">
                {usuarios.filter(u => u.status === 'Pendente').length}
              </p>
            </div>
            <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
              <Filter className="w-6 h-6 text-orange-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Aprovados</p>
              <p className="text-2xl font-semibold text-green-600 mt-1">
                {usuarios.filter(u => u.status === 'Aprovado').length}
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <Check className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Rejeitados</p>
              <p className="text-2xl font-semibold text-red-600 mt-1">
                {usuarios.filter(u => u.status === 'Rejeitado').length}
              </p>
            </div>
            <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
              <X className="w-6 h-6 text-red-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Filters and Actions */}
      <div className="bg-white rounded-lg border border-gray-200 mb-4">
        <div className="p-4 flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium text-gray-700">Filtrar por:</span>
            {['Todos', 'Pendente', 'Aprovado', 'Rejeitado'].map(status => (
              <button
                key={status}
                onClick={() => setFiltroStatus(status)}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  filtroStatus === status
                    ? 'bg-[#1A73E8] text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {status}
              </button>
            ))}
          </div>

          <div className="flex items-center gap-2">
            <button className="px-4 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors flex items-center gap-2">
              <Download className="w-4 h-4" />
              Exportar
            </button>
            <button className="px-4 py-2 bg-[#1A73E8] text-white rounded-lg text-sm font-medium hover:bg-[#1557B0] transition-colors flex items-center gap-2">
              <UserPlus className="w-4 h-4" />
              Novo Usuário
            </button>
          </div>
        </div>
      </div>

      {/* Users List */}
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider">
                  Usuário
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider">
                  CPF
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider">
                  Unidade
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider">
                  Perfil
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider">
                  Data
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider">
                  Ações
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {usuariosFiltrados.map((usuario) => (
                <tr key={usuario.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-4">
                    <div>
                      <div className="font-medium text-gray-900">{usuario.nome}</div>
                      <div className="text-sm text-gray-500">{usuario.email}</div>
                    </div>
                  </td>
                  <td className="px-4 py-4 text-sm text-gray-700">
                    {usuario.cpf}
                  </td>
                  <td className="px-4 py-4 text-sm text-gray-700">
                    {usuario.unidade}
                  </td>
                  <td className="px-4 py-4">
                    <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getPerfilBadge(usuario.perfil)}`}>
                      {usuario.perfil}
                    </span>
                  </td>
                  <td className="px-4 py-4">
                    <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getStatusBadge(usuario.status)}`}>
                      {usuario.status}
                    </span>
                  </td>
                  <td className="px-4 py-4 text-sm text-gray-700">
                    {usuario.dataCriacao}
                  </td>
                  <td className="px-4 py-4">
                    {usuario.status === 'Pendente' ? (
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleAprovar(usuario.id)}
                          className="p-1.5 bg-green-100 text-green-700 rounded hover:bg-green-200 transition-colors"
                          title="Aprovar"
                        >
                          <Check className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleRejeitar(usuario.id)}
                          className="p-1.5 bg-red-100 text-red-700 rounded hover:bg-red-200 transition-colors"
                          title="Rejeitar"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </div>
                    ) : (
                      <button className="p-1.5 hover:bg-gray-100 rounded transition-colors">
                        <MoreVertical className="w-4 h-4 text-gray-600" />
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
