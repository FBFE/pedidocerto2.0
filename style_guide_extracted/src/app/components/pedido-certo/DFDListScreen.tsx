import { useState } from 'react';
import { Plus, Search, Edit, Trash2, FileText, Calendar } from 'lucide-react';

interface DFD {
  id: string;
  numero: string;
  descricao: string;
  status: 'Ativo' | 'Inativo';
  dataAtualizacao: string;
  itens: number;
}

export default function DFDListScreen() {
  const [busca, setBusca] = useState('');

  const dfds: DFD[] = [
    {
      id: '1',
      numero: 'DFD-2026-001',
      descricao: 'Materiais de Enfermagem e Curativos',
      status: 'Ativo',
      dataAtualizacao: '10/03/2026',
      itens: 145,
    },
    {
      id: '2',
      numero: 'DFD-2026-002',
      descricao: 'Medicamentos de Alto Custo',
      status: 'Ativo',
      dataAtualizacao: '08/03/2026',
      itens: 89,
    },
    {
      id: '3',
      numero: 'DFD-2026-003',
      descricao: 'Equipamentos Médico-Hospitalares',
      status: 'Ativo',
      dataAtualizacao: '12/03/2026',
      itens: 234,
    },
    {
      id: '4',
      numero: 'DFD-2025-098',
      descricao: 'Descartáveis Hospitalares',
      status: 'Inativo',
      dataAtualizacao: '28/12/2025',
      itens: 76,
    },
    {
      id: '5',
      numero: 'DFD-2026-004',
      descricao: 'Materiais de Limpeza e Higiene',
      status: 'Ativo',
      dataAtualizacao: '11/03/2026',
      itens: 52,
    },
  ];

  const dfdsFiltrados = dfds.filter(d =>
    d.numero.toLowerCase().includes(busca.toLowerCase()) ||
    d.descricao.toLowerCase().includes(busca.toLowerCase())
  );

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 mb-2">
            DFD (Documentos de Formalização da Demanda)
          </h1>
          <p className="text-gray-600">
            Lista e gerenciamento de DFDs
          </p>
        </div>
        <button className="px-4 py-2 bg-[#1A73E8] text-white rounded-lg font-medium hover:bg-[#1557B0] transition-colors flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Novo DFD
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <p className="text-sm text-gray-600">Total de DFDs</p>
          <p className="text-2xl font-semibold text-gray-900 mt-1">{dfds.length}</p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <p className="text-sm text-gray-600">DFDs Ativos</p>
          <p className="text-2xl font-semibold text-green-600 mt-1">
            {dfds.filter(d => d.status === 'Ativo').length}
          </p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <p className="text-sm text-gray-600">Total de Itens</p>
          <p className="text-2xl font-semibold text-gray-900 mt-1">
            {dfds.reduce((acc, d) => acc + d.itens, 0)}
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
            placeholder="Buscar por número ou descrição..."
            className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none"
          />
        </div>
      </div>

      {/* DFD List */}
      <div className="space-y-3">
        {dfdsFiltrados.map((dfd) => (
          <div
            key={dfd.id}
            className="bg-white rounded-lg border border-gray-200 p-4 hover:shadow-md transition-shadow"
          >
            <div className="flex items-start justify-between gap-4">
              <div className="flex gap-4 flex-1">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <FileText className="w-6 h-6 text-[#1A73E8]" />
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="font-semibold text-gray-900">{dfd.numero}</h3>
                    <span
                      className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                        dfd.status === 'Ativo'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}
                    >
                      {dfd.status}
                    </span>
                  </div>
                  <p className="text-gray-700 mb-2">{dfd.descricao}</p>
                  <div className="flex items-center gap-4 text-sm text-gray-600">
                    <div className="flex items-center gap-1">
                      <FileText className="w-4 h-4" />
                      <span>{dfd.itens} itens</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Calendar className="w-4 h-4" />
                      <span>Atualizado em {dfd.dataAtualizacao}</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                  <Edit className="w-5 h-5 text-gray-600" />
                </button>
                <button className="p-2 hover:bg-red-50 rounded-lg transition-colors">
                  <Trash2 className="w-5 h-5 text-red-600" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
