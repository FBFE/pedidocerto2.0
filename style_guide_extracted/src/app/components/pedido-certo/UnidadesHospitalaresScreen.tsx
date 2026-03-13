import { useState } from 'react';
import { Plus, Search, Filter, MapPin, Phone, Building2, Upload, BarChart } from 'lucide-react';

interface UnidadeHospitalar {
  id: string;
  nome: string;
  cnes: string;
  tipo: string;
  endereco: string;
  municipio: string;
  uf: string;
  telefone: string;
  status: 'Ativa' | 'Inativa';
  leitos: number;
}

export default function UnidadesHospitalaresScreen() {
  const [busca, setBusca] = useState('');
  const [filtroStatus, setFiltroStatus] = useState('Todas');

  const unidades: UnidadeHospitalar[] = [
    {
      id: '1',
      nome: 'Hospital Central Dr. José Silva',
      cnes: '2345678',
      tipo: 'Hospital Geral',
      endereco: 'Av. Principal, 1000 - Centro',
      municipio: 'São Paulo',
      uf: 'SP',
      telefone: '(11) 3456-7890',
      status: 'Ativa',
      leitos: 250,
    },
    {
      id: '2',
      nome: 'UPA Norte 24h',
      cnes: '3456789',
      tipo: 'UPA',
      endereco: 'Rua do Norte, 500 - Zona Norte',
      municipio: 'São Paulo',
      uf: 'SP',
      telefone: '(11) 3567-8901',
      status: 'Ativa',
      leitos: 30,
    },
    {
      id: '3',
      nome: 'Hospital Regional Sul',
      cnes: '4567890',
      tipo: 'Hospital Regional',
      endereco: 'Av. Sul, 2000 - Zona Sul',
      municipio: 'São Paulo',
      uf: 'SP',
      telefone: '(11) 3678-9012',
      status: 'Ativa',
      leitos: 180,
    },
    {
      id: '4',
      nome: 'Posto de Saúde Vila Nova',
      cnes: '5678901',
      tipo: 'Posto de Saúde',
      endereco: 'Rua Vila Nova, 100',
      municipio: 'São Paulo',
      uf: 'SP',
      telefone: '(11) 3789-0123',
      status: 'Ativa',
      leitos: 0,
    },
    {
      id: '5',
      nome: 'Hospital Especializado Cardio',
      cnes: '6789012',
      tipo: 'Hospital Especializado',
      endereco: 'Av. Cardio, 300 - Jardins',
      municipio: 'São Paulo',
      uf: 'SP',
      telefone: '(11) 3890-1234',
      status: 'Inativa',
      leitos: 80,
    },
  ];

  const unidadesFiltradas = unidades.filter(u => {
    const matchBusca = u.nome.toLowerCase().includes(busca.toLowerCase()) ||
                       u.cnes.includes(busca);
    const matchStatus = filtroStatus === 'Todas' || u.status === filtroStatus;
    return matchBusca && matchStatus;
  });

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 mb-2">
            Unidades Hospitalares
          </h1>
          <p className="text-gray-600">
            Gerencie unidades de saúde, custos e importações
          </p>
        </div>
        <button className="px-4 py-2 bg-[#1A73E8] text-white rounded-lg font-medium hover:bg-[#1557B0] transition-colors flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Nova Unidade
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total de Unidades</p>
              <p className="text-2xl font-semibold text-gray-900 mt-1">{unidades.length}</p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Building2 className="w-6 h-6 text-[#1A73E8]" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Unidades Ativas</p>
              <p className="text-2xl font-semibold text-green-600 mt-1">
                {unidades.filter(u => u.status === 'Ativa').length}
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <BarChart className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total de Leitos</p>
              <p className="text-2xl font-semibold text-gray-900 mt-1">
                {unidades.reduce((acc, u) => acc + u.leitos, 0)}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
              <Upload className="w-6 h-6 text-purple-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="bg-white rounded-lg border border-gray-200 p-4 mb-4">
        <div className="flex flex-wrap items-center gap-4">
          <div className="flex-1 min-w-[300px]">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={busca}
                onChange={(e) => setBusca(e.target.value)}
                placeholder="Buscar por nome ou CNES..."
                className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none"
              />
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Filter className="w-5 h-5 text-gray-600" />
            {['Todas', 'Ativa', 'Inativa'].map(status => (
              <button
                key={status}
                onClick={() => setFiltroStatus(status)}
                className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                  filtroStatus === status
                    ? 'bg-[#1A73E8] text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {status}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Units List */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {unidadesFiltradas.map((unidade) => (
          <div
            key={unidade.id}
            className="bg-white rounded-lg border border-gray-200 p-5 hover:shadow-md transition-shadow cursor-pointer"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <h3 className="font-semibold text-gray-900">{unidade.nome}</h3>
                  <span
                    className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                      unidade.status === 'Ativa'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {unidade.status}
                  </span>
                </div>
                <p className="text-sm text-gray-600">{unidade.tipo}</p>
              </div>
            </div>

            <div className="space-y-2 mb-4">
              <div className="flex items-start gap-2 text-sm text-gray-600">
                <Building2 className="w-4 h-4 mt-0.5 flex-shrink-0" />
                <span>CNES: {unidade.cnes}</span>
              </div>
              <div className="flex items-start gap-2 text-sm text-gray-600">
                <MapPin className="w-4 h-4 mt-0.5 flex-shrink-0" />
                <span>{unidade.endereco} - {unidade.municipio}/{unidade.uf}</span>
              </div>
              <div className="flex items-start gap-2 text-sm text-gray-600">
                <Phone className="w-4 h-4 mt-0.5 flex-shrink-0" />
                <span>{unidade.telefone}</span>
              </div>
            </div>

            <div className="flex items-center justify-between pt-3 border-t border-gray-200">
              <div className="text-sm">
                <span className="text-gray-600">Leitos: </span>
                <span className="font-semibold text-gray-900">{unidade.leitos}</span>
              </div>
              <div className="flex gap-2">
                <button className="px-3 py-1.5 bg-blue-50 text-[#1A73E8] rounded text-sm font-medium hover:bg-blue-100 transition-colors">
                  Dados/Custo
                </button>
                <button className="px-3 py-1.5 bg-gray-100 text-gray-700 rounded text-sm font-medium hover:bg-gray-200 transition-colors">
                  Editar
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {unidadesFiltradas.length === 0 && (
        <div className="bg-white rounded-lg border border-gray-200 p-12 text-center">
          <Building2 className="w-12 h-12 text-gray-400 mx-auto mb-3" />
          <p className="text-gray-600">Nenhuma unidade encontrada</p>
        </div>
      )}
    </div>
  );
}
