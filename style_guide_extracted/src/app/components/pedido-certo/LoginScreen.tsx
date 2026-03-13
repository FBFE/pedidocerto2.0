import { useState } from 'react';
import { useNavigate } from 'react-router';
import { Mail, Lock, ArrowRight } from 'lucide-react';

export default function LoginScreen() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    // Simulando login
    navigate('/pc/usuarios');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#1A73E8] to-[#0D47A1] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo/Header */}
        <div className="text-center mb-8">
          <div className="bg-white w-16 h-16 rounded-2xl mx-auto mb-4 flex items-center justify-center shadow-lg">
            <div className="text-2xl font-bold text-[#1A73E8]">PC</div>
          </div>
          <h1 className="text-3xl font-bold text-white mb-2">Pedido Certo</h1>
          <p className="text-blue-100">Sistema de Gestão Hospitalar</p>
        </div>

        {/* Login Card */}
        <div className="bg-white rounded-2xl shadow-2xl p-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">Entrar no sistema</h2>
          
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                E-mail
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Mail className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none transition-colors"
                  placeholder="seu.email@exemplo.com"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Senha
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="password"
                  value={senha}
                  onChange={(e) => setSenha(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#1A73E8] focus:border-[#1A73E8] outline-none transition-colors"
                  placeholder="••••••••"
                  required
                />
              </div>
            </div>

            <div className="flex items-center justify-between text-sm">
              <label className="flex items-center gap-2 text-gray-600">
                <input type="checkbox" className="rounded border-gray-300 text-[#1A73E8] focus:ring-[#1A73E8]" />
                Lembrar-me
              </label>
              <a href="#" className="text-[#1A73E8] hover:underline">
                Esqueceu a senha?
              </a>
            </div>

            <button
              type="submit"
              className="w-full bg-[#1A73E8] text-white py-3 rounded-lg font-medium hover:bg-[#1557B0] transition-colors flex items-center justify-center gap-2 group"
            >
              Entrar
              <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              Não tem uma conta?{' '}
              <a href="#" className="text-[#1A73E8] font-medium hover:underline">
                Criar conta
              </a>
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-6 text-center text-blue-100 text-sm">
          <p>Sistema desenvolvido para gestão hospitalar</p>
          <p className="mt-1 opacity-75">© 2026 Pedido Certo</p>
        </div>
      </div>
    </div>
  );
}
