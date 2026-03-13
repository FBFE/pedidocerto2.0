import { useState } from 'react';
import { Plus, Search, Building2, MapPin, FileCheck, Phone, Mail } from 'lucide-react';

interface Fornecedor {
  id: string;
  razaoSocial: string;
  cnpj: string;
  endereco: string;
  municipio: string;
  uf: string;
  telefone: string;
  email: string;
  status: 'Ativo' | 'Inativo';
  numeroAtas: number;
}

export default function FornecedoresScreen() {
  const [busca, setBusca] = useState('');

  const fornecedores: Fornecedor[] = [
    {
      id: '1',
      razaoSocial: 'MedSupply Distribuidora Ltda',
      cnpj: '12.345.678/0001-90',
      endereco: 'Rua das Flores, 100',
      municipio: 'São Paulo',
      uf: 'SP',
      telefone: '(11) 3456-7890',
      email: 'contato@medsupply.com.br',
      status: 'Ativo',
      numeroAtas: 12,
    },
    {
      id: '2',
      razaoSocial: 'Pharma Brasil S.A.',
      cnpj: '23.456.789/0001-01',
      endereco: 'Av. Principal, 500',
      municipio: 'Rio de Janeiro',
      uf: 'RJ',
      telefone: '(21) 2345-6789',
      email: 'vendas@pharmabrasil.com.br',
      status: 'Ativo',
      numeroAtas: 8,
    },
    {
      id: '3',
      razaoSocial: 'Equipamentos Hospitalares do Norte',
      cnpj: '34.567.890/0001-12',
      endereco: 'Rua Norte, 200',
      municipio: 'Manaus',
      uf: 'AM',
      telefone: '(92) 3234-5678',
      email: 'contato@equiphospnorte.com.br',
      status: 'Ativo',
      numeroAtas: 5,
    },
    {
      id: '4',
      razaoSocial: 'Sul Medicamentos Ltda',
      cnpj: '45.678.901/0001-23',
      endereco: 'Av. Sul, 300',
      municipio: 'Porto Alegre',
      uf: 'RS',
      telefone: '(51) 3123-4567',
      email: 'comercial@sulmed.com.br',
      status: 'Inativo',
      numeroAtas: 3,
    },
  ];

  const fornecedoresFiltrados = fornecedores.filter(f =>
    f.razaoSocial.toLowerCase().includes(busca.toLowerCase()) ||
    f.cnpj.includes(busca)
  );

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 mb-2">
            Fornecedores
          </h1>
          <p className="text-gray-600">
            Cadastro e gestão de fornecedores
          </p>
        </div>
        <button className="px-4 py-2 bg-[#1A73E8] text-white rounded-lg font-medium hover:bg-[#1557B0] transition-colors flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Novo Fornecedor
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <p className="text-sm text-gray-600">Total de Fornecedores</p>
          <p className="text-2xl font-semibold text-gray-900 mt-1">{fornecedores.length}</p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <p className="text-sm text-gray-600">Fornecedores Ativos</p>
          <p className="text-2xl font-semibold text-green-600 mt-1">
            {fornecedores.filter(f => f.status === 'Ativo').length}
          </p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <p className="text-sm text-gray-600">Total de Atas</p>
          <p className="text-2xl font-semibold text-gray-900 mt-1">
            {fornecedores.reduce((acc, f) => acc + f.numeroAtas, 0)}
          </p>
        </div>
      </div>

      {/* Search */}
      <div className="bg-white rounded-lg border border-gray-200 p-4 mb-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={busca}
            onChange={(e) => setBusca(e.target.value)}
            placeholder="Buscar por razão social ou CNPJ..."
            className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none"
          />
        </div>
      </div>

      {/* Suppliers Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {fornecedoresFiltrados.map((fornecedor) => (
          <div
            key={fornecedor.id}
            className="bg-white rounded-lg border border-gray-200 p-5 hover:shadow-md transition-shadow cursor-pointer"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="flex gap-3 flex-1">
                <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Building2 className="w-6 h-6 text-orange-600" />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="font-semibold text-gray-900">{fornecedor.razaoSocial}</h3>
                    <span
                      className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                        fornecedor.status === 'Ativo'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}
                    >
                      {fornecedor.status}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600">CNPJ: {fornecedor.cnpj}</p>
                </div>
              </div>
            </div>

            <div className="space-y-2 mb-4">
              <div className="flex items-start gap-2 text-sm text-gray-600">
                <MapPin className="w-4 h-4 mt-0.5 flex-shrink-0" />
                <span>{fornecedor.endereco} - {fornecedor.municipio}/{fornecedor.uf}</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Phone className="w-4 h-4 flex-shrink-0" />
                <span>{fornecedor.telefone}</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Mail className="w-4 h-4 flex-shrink-0" />
                <span>{fornecedor.email}</span>
              </div>
            </div>

            <div className="flex items-center justify-between pt-3 border-t border-gray-200">
              <div className="flex items-center gap-2 text-sm">
                <FileCheck className="w-4 h-4 text-gray-600" />
                <span className="text-gray-600">{fornecedor.numeroAtas} atas cadastradas</span>
              </div>
              <button className="px-3 py-1.5 bg-gray-100 text-gray-700 rounded text-sm font-medium hover:bg-gray-200 transition-colors">
                Editar
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
