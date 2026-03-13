import { useState } from 'react';
import { Plus, Edit, Trash2, ChevronRight, ChevronDown, Building2 } from 'lucide-react';

interface OrgNode {
  id: string;
  nome: string;
  tipo: 'Governo' | 'Secretaria' | 'Unidade';
  responsavel?: string;
  children?: OrgNode[];
}

export default function OrganogramaScreen() {
  const [expandedNodes, setExpandedNodes] = useState<string[]>(['1', '1-1', '1-2']);

  const organograma: OrgNode = {
    id: '1',
    nome: 'Governo Municipal de São Paulo',
    tipo: 'Governo',
    responsavel: 'Prefeito João Silva',
    children: [
      {
        id: '1-1',
        nome: 'Secretaria Municipal de Saúde',
        tipo: 'Secretaria',
        responsavel: 'Sec. Maria Santos',
        children: [
          {
            id: '1-1-1',
            nome: 'Hospital Central',
            tipo: 'Unidade',
            responsavel: 'Dr. Carlos Lima',
          },
          {
            id: '1-1-2',
            nome: 'UPA Norte',
            tipo: 'Unidade',
            responsavel: 'Dra. Ana Paula',
          },
          {
            id: '1-1-3',
            nome: 'Hospital Regional Sul',
            tipo: 'Unidade',
            responsavel: 'Dr. Pedro Costa',
          },
        ],
      },
      {
        id: '1-2',
        nome: 'Secretaria de Administração',
        tipo: 'Secretaria',
        responsavel: 'Sec. Paulo Oliveira',
        children: [
          {
            id: '1-2-1',
            nome: 'Departamento de Compras',
            tipo: 'Unidade',
            responsavel: 'Fernanda Martins',
          },
          {
            id: '1-2-2',
            nome: 'Departamento Financeiro',
            tipo: 'Unidade',
            responsavel: 'Roberto Santos',
          },
        ],
      },
      {
        id: '1-3',
        nome: 'Secretaria de Educação',
        tipo: 'Secretaria',
        responsavel: 'Sec. Juliana Alves',
      },
    ],
  };

  const toggleNode = (nodeId: string) => {
    setExpandedNodes(prev =>
      prev.includes(nodeId)
        ? prev.filter(id => id !== nodeId)
        : [...prev, nodeId]
    );
  };

  const getNodeColor = (tipo: string) => {
    const colors = {
      Governo: 'bg-purple-100 border-purple-300 text-purple-900',
      Secretaria: 'bg-blue-100 border-blue-300 text-blue-900',
      Unidade: 'bg-green-100 border-green-300 text-green-900',
    };
    return colors[tipo as keyof typeof colors];
  };

  const renderNode = (node: OrgNode, level = 0) => {
    const isExpanded = expandedNodes.includes(node.id);
    const hasChildren = node.children && node.children.length > 0;

    return (
      <div key={node.id} className={level > 0 ? 'ml-8' : ''}>
        <div className="mb-2">
          <div className={`border-2 rounded-lg p-4 ${getNodeColor(node.tipo)} hover:shadow-md transition-shadow`}>
            <div className="flex items-start justify-between gap-4">
              <div className="flex items-start gap-3 flex-1">
                {hasChildren && (
                  <button
                    onClick={() => toggleNode(node.id)}
                    className="mt-1 p-1 hover:bg-white hover:bg-opacity-50 rounded transition-colors"
                  >
                    {isExpanded ? (
                      <ChevronDown className="w-5 h-5" />
                    ) : (
                      <ChevronRight className="w-5 h-5" />
                    )}
                  </button>
                )}
                {!hasChildren && <div className="w-7" />}
                
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <Building2 className="w-5 h-5" />
                    <h3 className="font-semibold text-lg">{node.nome}</h3>
                  </div>
                  {node.responsavel && (
                    <p className="text-sm opacity-90">Responsável: {node.responsavel}</p>
                  )}
                  <span className="inline-block mt-2 px-2 py-1 text-xs font-medium bg-white bg-opacity-50 rounded">
                    {node.tipo}
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-1">
                <button className="p-2 hover:bg-white hover:bg-opacity-50 rounded transition-colors">
                  <Edit className="w-4 h-4" />
                </button>
                <button className="p-2 hover:bg-white hover:bg-opacity-50 rounded transition-colors">
                  <Plus className="w-4 h-4" />
                </button>
                {level > 0 && (
                  <button className="p-2 hover:bg-red-100 rounded transition-colors text-red-600">
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>

        {hasChildren && isExpanded && (
          <div className="border-l-2 border-gray-300 ml-4 pl-2">
            {node.children!.map(child => renderNode(child, level + 1))}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 mb-2">
            Organograma
          </h1>
          <p className="text-gray-600">
            Estrutura hierárquica: Governo → Secretarias → Unidades
          </p>
        </div>
        <button className="px-4 py-2 bg-[#1A73E8] text-white rounded-lg font-medium hover:bg-[#1557B0] transition-colors flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Novo Governo
        </button>
      </div>

      {/* Legend */}
      <div className="bg-white rounded-lg border border-gray-200 p-4 mb-6">
        <h3 className="font-medium text-gray-900 mb-3">Legenda:</h3>
        <div className="flex flex-wrap gap-4">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-purple-100 border-2 border-purple-300 rounded"></div>
            <span className="text-sm text-gray-700">Governo</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-blue-100 border-2 border-blue-300 rounded"></div>
            <span className="text-sm text-gray-700">Secretaria</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-green-100 border-2 border-green-300 rounded"></div>
            <span className="text-sm text-gray-700">Unidade</span>
          </div>
        </div>
      </div>

      {/* Organogram Tree */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        {renderNode(organograma)}
      </div>
    </div>
  );
}
