import { useState } from 'react';
import { Search, User, Home, Database, Map, BarChart3, Menu, Plus, ChevronRight, Filter, ArrowLeft } from 'lucide-react';

export default function Demo() {
  const [activeTab, setActiveTab] = useState(0);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    client: '',
    priority: 'Média',
    status: 'Pendente',
    description: '',
  });

  const projects = [
    {
      id: 1,
      title: 'Projeto Alpha - Q1 2026',
      subtitle: 'Cliente: Tech Solutions Inc.',
      date: '12/03/2026',
      status: 'Aprovado',
      statusColor: 'green',
      image: 'https://images.unsplash.com/photo-1716703432455-3045789de738?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxidXNpbmVzcyUyMG1lZXRpbmclMjB0ZWFtfGVufDF8fHx8MTc3MzMzNzc0MHww&ixlib=rb-4.1.0&q=80&w=1080',
    },
    {
      id: 2,
      title: 'Inventário Warehouse 2',
      subtitle: 'Responsável: Maria Silva',
      date: '11/03/2026',
      status: 'Pendente',
      statusColor: 'orange',
      image: 'https://images.unsplash.com/photo-1749244768351-2726dc23d26c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3YXJlaG91c2UlMjBpbnZlbnRvcnl8ZW58MXx8fHwxNzczMzczNDI5fDA&ixlib=rb-4.1.0&q=80&w=1080',
    },
    {
      id: 3,
      title: 'Construção Sede Norte',
      subtitle: 'Orçamento: R$ 2.5M',
      date: '10/03/2026',
      status: 'Atrasado',
      statusColor: 'red',
      image: 'https://images.unsplash.com/photo-1710585761854-57ff6839395c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb25zdHJ1Y3Rpb24lMjBzaXRlJTIwcHJvamVjdHxlbnwxfHx8fDE3NzM0MTAxODN8MA&ixlib=rb-4.1.0&q=80&w=1080',
    },
    {
      id: 4,
      title: 'Dashboard Analytics Q1',
      subtitle: 'Analista: João Santos',
      date: '09/03/2026',
      status: 'Em Progresso',
      statusColor: 'blue',
      image: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkYXRhJTIwYW5hbHl0aWNzJTIwZGFzaGJvYXJkfGVufDF8fHx8MTc3MzMyODE0M3ww&ixlib=rb-4.1.0&q=80&w=1080',
    },
    {
      id: 5,
      title: 'Setup Home Office',
      subtitle: 'Departamento: TI',
      date: '08/03/2026',
      status: 'Aprovado',
      statusColor: 'green',
      image: 'https://images.unsplash.com/photo-1623679072629-3aaa0192a391?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxvZmZpY2UlMjB3b3Jrc3BhY2UlMjBkZXNrfGVufDF8fHx8MTc3MzMwOTQ5Nnww&ixlib=rb-4.1.0&q=80&w=1080',
    },
  ];

  const getStatusStyle = (color: string) => {
    const styles = {
      green: 'bg-green-100 text-green-800',
      orange: 'bg-orange-100 text-orange-800',
      red: 'bg-red-100 text-red-800',
      blue: 'bg-blue-100 text-blue-800',
    };
    return styles[color as keyof typeof styles] || styles.green;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log('Form submitted:', formData);
    setShowForm(false);
    setFormData({
      name: '',
      client: '',
      priority: 'Média',
      status: 'Pendente',
      description: '',
    });
  };

  return (
    <div className="min-h-screen bg-[#F5F5F5] pb-20">
      {/* Mobile Frame */}
      <div className="max-w-md mx-auto bg-white shadow-2xl" style={{ minHeight: '100vh' }}>
        
        {/* AppBar */}
        <div className="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
          <div className="flex items-center justify-between px-4 py-3">
            {showForm ? (
              <>
                <button
                  onClick={() => setShowForm(false)}
                  className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                >
                  <ArrowLeft className="w-5 h-5 text-gray-600" />
                </button>
                <h1 className="text-lg font-medium text-gray-900">Novo Projeto</h1>
                <div className="w-9" /> {/* Spacer */}
              </>
            ) : (
              <>
                <h1 className="text-lg font-medium text-gray-900">Meus Projetos</h1>
                <div className="flex items-center gap-2">
                  <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                    <Search className="w-5 h-5 text-gray-600" />
                  </button>
                  <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                    <User className="w-5 h-5 text-gray-600" />
                  </button>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Content */}
        <div className="p-4">
          {showForm ? (
            /* Form View */
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Nome do Projeto *
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="Digite o nome do projeto"
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none transition-colors"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Cliente / Responsável
                </label>
                <input
                  type="text"
                  value={formData.client}
                  onChange={(e) => setFormData({ ...formData, client: e.target.value })}
                  placeholder="Nome do cliente ou responsável"
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none transition-colors"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Prioridade
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {['Baixa', 'Média', 'Alta'].map((priority) => (
                    <button
                      key={priority}
                      type="button"
                      onClick={() => setFormData({ ...formData, priority })}
                      className={`px-4 py-2 border-2 rounded-lg transition-colors ${
                        formData.priority === priority
                          ? 'border-[#1A73E8] bg-blue-50 text-[#1A73E8] font-medium'
                          : 'border-gray-300 hover:border-[#1A73E8] hover:bg-blue-50'
                      }`}
                    >
                      {priority}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Status
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {['Pendente', 'Aprovado', 'Em Progresso', 'Atrasado'].map((status) => (
                    <button
                      key={status}
                      type="button"
                      onClick={() => setFormData({ ...formData, status })}
                      className={`px-3 py-2 border-2 rounded-lg transition-colors text-sm ${
                        formData.status === status
                          ? 'border-[#1A73E8] bg-blue-50 text-[#1A73E8] font-medium'
                          : 'border-gray-300 hover:border-[#1A73E8] hover:bg-blue-50'
                      }`}
                    >
                      {status}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Descrição
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Adicione uma descrição detalhada do projeto"
                  rows={4}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none transition-colors resize-none"
                />
              </div>

              <div className="pt-4 space-y-2">
                <button
                  type="submit"
                  className="w-full bg-[#1A73E8] text-white py-3 rounded-lg font-medium hover:bg-[#1557B0] transition-colors"
                >
                  Salvar Projeto
                </button>
                <button
                  type="button"
                  onClick={() => setShowForm(false)}
                  className="w-full bg-white text-gray-700 py-3 rounded-lg font-medium border border-gray-300 hover:bg-gray-50 transition-colors"
                >
                  Cancelar
                </button>
              </div>
            </form>
          ) : (
            /* List View */
            <>
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-sm font-medium text-gray-500">
                  {projects.length} projetos
                </h2>
                <button className="flex items-center gap-2 text-sm text-[#1A73E8] font-medium">
                  <Filter className="w-4 h-4" />
                  Filtrar
                </button>
              </div>

              <div className="space-y-3">
                {projects.map((project) => (
                  <div
                    key={project.id}
                    className="bg-white border border-gray-200 rounded-lg p-3 shadow-sm active:shadow-md transition-shadow cursor-pointer"
                  >
                    <div className="flex gap-3">
                      <div className="w-16 h-16 bg-gray-200 rounded flex-shrink-0 overflow-hidden">
                        <img
                          src={project.image}
                          alt={project.title}
                          className="w-full h-full object-cover"
                        />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <h3 className="font-semibold text-gray-900 text-sm leading-tight">
                            {project.title}
                          </h3>
                          <span
                            className={`px-2 py-0.5 text-xs font-medium rounded-full whitespace-nowrap ${getStatusStyle(
                              project.statusColor
                            )}`}
                          >
                            {project.status}
                          </span>
                        </div>
                        <p className="text-sm text-gray-600 mt-1">{project.subtitle}</p>
                        <p className="text-xs text-gray-500 mt-0.5">
                          Atualizado: {project.date}
                        </p>
                      </div>
                      <ChevronRight className="w-5 h-5 text-gray-400 flex-shrink-0 mt-1" />
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>

        {/* FAB */}
        {!showForm && (
          <button
            onClick={() => setShowForm(true)}
            className="fixed bottom-20 right-4 w-14 h-14 bg-[#1A73E8] text-white rounded-full shadow-lg hover:bg-[#1557B0] active:scale-95 transition-all flex items-center justify-center z-40"
            style={{ maxWidth: 'calc(448px - 2rem)' }}
          >
            <Plus className="w-6 h-6" />
          </button>
        )}

        {/* Bottom Navigation */}
        <div className="fixed bottom-0 left-0 right-0 bg-white shadow-lg border-t border-gray-200 z-50" style={{ maxWidth: '448px', margin: '0 auto' }}>
          <div className="flex items-center justify-around px-2 py-2.5">
            <button
              onClick={() => setActiveTab(0)}
              className={`flex flex-col items-center gap-1 flex-1 py-1 transition-colors ${
                activeTab === 0 ? 'text-[#1A73E8]' : 'text-gray-500'
              }`}
            >
              <Home className="w-6 h-6" />
              <span className="text-xs font-medium">Home</span>
            </button>
            <button
              onClick={() => setActiveTab(1)}
              className={`flex flex-col items-center gap-1 flex-1 py-1 transition-colors ${
                activeTab === 1 ? 'text-[#1A73E8]' : 'text-gray-500'
              }`}
            >
              <Database className="w-6 h-6" />
              <span className="text-xs">Dados</span>
            </button>
            <button
              onClick={() => setActiveTab(2)}
              className={`flex flex-col items-center gap-1 flex-1 py-1 transition-colors ${
                activeTab === 2 ? 'text-[#1A73E8]' : 'text-gray-500'
              }`}
            >
              <Map className="w-6 h-6" />
              <span className="text-xs">Mapas</span>
            </button>
            <button
              onClick={() => setActiveTab(3)}
              className={`flex flex-col items-center gap-1 flex-1 py-1 transition-colors ${
                activeTab === 3 ? 'text-[#1A73E8]' : 'text-gray-500'
              }`}
            >
              <BarChart3 className="w-6 h-6" />
              <span className="text-xs">Dashboard</span>
            </button>
            <button
              onClick={() => setActiveTab(4)}
              className={`flex flex-col items-center gap-1 flex-1 py-1 transition-colors ${
                activeTab === 4 ? 'text-[#1A73E8]' : 'text-gray-500'
              }`}
            >
              <Menu className="w-6 h-6" />
              <span className="text-xs">Menu</span>
            </button>
          </div>
        </div>
      </div>

      {/* Instructions */}
      <div className="max-w-4xl mx-auto mt-8 px-4">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-3">
            Instruções de Uso
          </h3>
          <ul className="space-y-2 text-sm text-gray-600">
            <li className="flex items-start gap-2">
              <span className="text-[#1A73E8] font-bold">•</span>
              <span>Clique no botão <strong>+</strong> (FAB) para adicionar um novo projeto</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#1A73E8] font-bold">•</span>
              <span>Use os botões de seleção rápida (Enum) para escolher prioridade e status</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#1A73E8] font-bold">•</span>
              <span>A navegação inferior permite alternar entre diferentes seções do app</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#1A73E8] font-bold">•</span>
              <span>Os cards mostram status color-coded: verde (aprovado), laranja (pendente), vermelho (atrasado), azul (em progresso)</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
}
