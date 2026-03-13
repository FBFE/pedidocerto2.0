import { Outlet, Link, useLocation } from 'react-router';
import { BookOpen, Component, Smartphone } from 'lucide-react';

export default function Root() {
  const location = useLocation();
  
  const isActive = (path: string) => {
    if (path === '/' && location.pathname === '/') return true;
    if (path !== '/' && location.pathname.startsWith(path)) return true;
    return false;
  };

  return (
    <div className="min-h-screen bg-[#F5F5F5]">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-semibold text-gray-900">
              AppSheet Style Guide
            </h1>
            <div className="text-sm text-gray-500">
              Flutter Design System
            </div>
          </div>
        </div>
      </header>

      {/* Navigation Tabs */}
      <nav className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-8">
            <Link
              to="/"
              className={`flex items-center gap-2 px-1 py-4 border-b-2 transition-colors ${
                isActive('/') && location.pathname === '/'
                  ? 'border-[#1A73E8] text-[#1A73E8]'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <BookOpen className="w-4 h-4" />
              <span className="text-sm font-medium">Guia de Estilo</span>
            </Link>
            <Link
              to="/components"
              className={`flex items-center gap-2 px-1 py-4 border-b-2 transition-colors ${
                isActive('/components')
                  ? 'border-[#1A73E8] text-[#1A73E8]'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Component className="w-4 h-4" />
              <span className="text-sm font-medium">Componentes</span>
            </Link>
            <Link
              to="/demo"
              className={`flex items-center gap-2 px-1 py-4 border-b-2 transition-colors ${
                isActive('/demo')
                  ? 'border-[#1A73E8] text-[#1A73E8]'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Smartphone className="w-4 h-4" />
              <span className="text-sm font-medium">Demo Interativo</span>
            </Link>
          </div>
        </div>
      </nav>

      {/* Content */}
      <main>
        <Outlet />
      </main>
    </div>
  );
}
