import { useState } from 'react';
import { Plus, Search, Filter, FileCheck, Calendar, DollarSign, Download, ExternalLink } from 'lucide-react';

interface Ata {
  id: string;
  numero: string;
  fornecedor: string;
  dataInicio: string;
  dataFim: string;
  valor: number;
  status: 'Vigente' | 'Vencida' | 'Cancelada';
  itens: number;
  origem: 'Manual' | 'PNCP';
}

export default function AtasScreen() {
  const [busca, setBusca] = useState('');
  const [filtroStatus, setFiltroStatus] = useState('Todas');

  const atas: Ata[] = [
    {
      id: '1',
      numero: 'ATA-2026-001',
      fornecedor: 'MedSupply Distribuidora Ltda',
      dataInicio: '01/01/2026',
      dataFim: '31/12/2026',
      valor: 2500000.00,
      status: 'Vigente',
      itens: 145,
      origem: 'Manual',
    },
    {
      id: '2',
      numero: 'ATA-2026-002',
      fornecedor: 'Pharma Brasil S.A.',
      dataInicio: '15/01/2026',
      dataFim: '14/01/2027',
      valor: 1800000.00,
      status: 'Vigente',
      itens: 89,
      origem: 'PNCP',
    },
    {
      id: '3',
      numero: 'ATA-2025-098',
      fornecedor: 'Sul Medicamentos Ltda',
      dataInicio: '01/06/2025',
      dataFim: '31/12/2025',
      valor: 950000.00,
      status: 'Vencida',
      itens: 76,
      origem: 'Manual',
    },
    {
      id: '4',
      numero: 'ATA-2026-003',
      fornecedor: 'Equipamentos Hospitalares do Norte',
      dataInicio: '01/02/2026',
      dataFim: '31/01/2027',
      valor: 3200000.00,
      status: 'Vigente',
      itens: 234,
      origem: 'PNCP',
    },
    {
      id: '5',
      numero: 'ATA-2025-087',
      fornecedor: 'MedSupply Distribuidora Ltda',
      dataInicio: '01/03/2025',
      dataFim: '28/02/2026',
      valor: 1200000.00,
      status: 'Cancelada',
      itens: 52,
      origem: 'Manual',
    },
  ];

  const atasFiltradas = atas.filter(a => {
    const matchBusca = a.numero.toLowerCase().includes(busca.toLowerCase()) ||
                       a.fornecedor.toLowerCase().includes(busca.toLowerCase());
    const matchStatus = filtroStatus === 'Todas' || a.status === filtroStatus;
    return matchBusca && matchStatus;
  });

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(value);
  };

  const getStatusBadge = (status: string) => {
    const styles = {
      Vigente: 'bg-green-100 text-green-800',
      Vencida: 'bg-gray-100 text-gray-800',
      Cancelada: 'bg-red-100 text-red-800',
    };
    return styles[status as keyof typeof styles];
  };

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 mb-2">
            Banco de Atas
          </h1>
          <p className="text-gray-600">
            Gestão de atas de registro de preços
          </p>
        </div>
        <div className="flex gap-2">
          <button className="px-4 py-2 bg-white border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition-colors flex items-center gap-2">
            <ExternalLink className="w-5 h-5" />
            Buscar PNCP
          </button>
          <button className="px-4 py-2 bg-[#1A73E8] text-white rounded-lg font-medium hover:bg-[#1557B0] transition-colors flex items-center gap-2">
            <Plus className="w-5 h-5" />
            Nova Ata
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <p className="text-sm text-gray-600">Total de Atas</p>
          <p className="text-2xl font-semibold text-gray-900 mt-1">{atas.length}</p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <p className="text-sm text-gray-600">Atas Vigentes</p>
          <p className="text-2xl font-semibold text-green-600 mt-1">
            {atas.filter(a => a.status === 'Vigente').length}
          </p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <p className="text-sm text-gray-600">Total de Itens</p>
          <p className="text-2xl font-semibold text-gray-900 mt-1">
            {atas.reduce((acc, a) => acc + a.itens, 0)}
          </p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-4">
          <p className="text-sm text-gray-600">Valor Total (Vigentes)</p>
          <p className="text-lg font-semibold text-gray-900 mt-1">
            {formatCurrency(atas.filter(a => a.status === 'Vigente').reduce((acc, a) => acc + a.valor, 0))}
          </p>
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
                placeholder="Buscar por número ou fornecedor..."
                className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none"
              />
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Filter className="w-5 h-5 text-gray-600" />
            {['Todas', 'Vigente', 'Vencida', 'Cancelada'].map(status => (
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

      {/* Atas List */}
      <div className="space-y-3">
        {atasFiltradas.map((ata) => (
          <div
            key={ata.id}
            className="bg-white rounded-lg border border-gray-200 p-5 hover:shadow-md transition-shadow cursor-pointer"
          >
            <div className="flex items-start justify-between gap-4 mb-3">
              <div className="flex gap-4 flex-1">
                <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <FileCheck className="w-6 h-6 text-green-600" />
                </div>
                
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1 flex-wrap">
                    <h3 className="font-semibold text-gray-900">{ata.numero}</h3>
                    <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${getStatusBadge(ata.status)}`}>
                      {ata.status}
                    </span>
                    <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                      ata.origem === 'PNCP' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'
                    }`}>
                      {ata.origem}
                    </span>
                  </div>
                  <p className="text-gray-700 mb-2">{ata.fornecedor}</p>
                  
                  <div className="flex flex-wrap gap-4 text-sm text-gray-600">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-4 h-4" />
                      <span>{ata.dataInicio} a {ata.dataFim}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <DollarSign className="w-4 h-4" />
                      <span className="font-medium">{formatCurrency(ata.valor)}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <FileCheck className="w-4 h-4" />
                      <span>{ata.itens} itens</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button className="px-3 py-1.5 bg-blue-50 text-[#1A73E8] rounded text-sm font-medium hover:bg-blue-100 transition-colors">
                  Ver Detalhes
                </button>
                <button className="p-2 hover:bg-gray-100 rounded transition-colors">
                  <Download className="w-5 h-5 text-gray-600" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
