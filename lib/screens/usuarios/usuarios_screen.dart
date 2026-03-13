import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/pedido_certo_theme.dart';
import '../../modules/usuarios/models/usuario_model.dart';
import '../../modules/usuarios/repositories/usuario_repository.dart';
import '../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';
import '../../modules/dfd/repositories/dfd_repository.dart';
import '../../modules/atas/repositories/ata_repository.dart';
import '../../modules/fornecedores/repositories/fornecedor_repository.dart';
import '../../modules/catmed/repositories/catmed_repository.dart';
import '../../modules/renem/repositories/renem_repository.dart';
import '../../modules/sigtap/repositories/procedimento_repository.dart';
import '../../services/background_preference_service.dart';
import '../../widgets/admin_sidebar_menu.dart';
import '../../widgets/constrained_content.dart';
import '../../widgets/dashboard_kpis.dart';
import '../../widgets/sidebar_calendar.dart';
import '../configuracoes/configuracoes_screen.dart';
import '../atas/atas_screen.dart';
import '../fornecedores/fornecedores_screen.dart';
import '../dfd/dfd_list_screen.dart';
import '../organograma/organograma_screen.dart';
import '../profile/atualizar_dados_screen.dart';
import '../sigtap/procedimentos_screen.dart';
import '../catmed/catmed_screen.dart';
import '../renem/renem_screen.dart';
import '../unidades/unidades_hospitalares_screen.dart';
import '../admin/gabinete_unidades_screen.dart';
import 'duplicados_screen.dart';

/// Dados do painel expostos para as rotas do Navigator de conteúdo (dashboard/usuários atualizam).
class _ContentScope extends InheritedWidget {
  const _ContentScope({
    required this.totalUnidades,
    required this.totalUsuarios,
    required this.carregando,
    required this.childForUsuarios,
    required this.totalDfd,
    required this.totalAtas,
    required this.totalFornecedores,
    required this.totalEquipamentos,
    required this.totalMedicamentos,
    required this.totalProcedimentos,
    required super.child,
  });

  final int totalUnidades;
  final int totalUsuarios;
  final bool carregando;
  final Widget childForUsuarios;
  final int totalDfd;
  final int totalAtas;
  final int totalFornecedores;
  final int totalEquipamentos;
  final int totalMedicamentos;
  final int totalProcedimentos;

  static _ContentScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ContentScope>();
    assert(scope != null, 'ContentScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(_ContentScope old) =>
      totalUnidades != old.totalUnidades ||
      totalUsuarios != old.totalUsuarios ||
      carregando != old.carregando ||
      childForUsuarios != old.childForUsuarios ||
      totalDfd != old.totalDfd ||
      totalAtas != old.totalAtas ||
      totalFornecedores != old.totalFornecedores ||
      totalEquipamentos != old.totalEquipamentos ||
      totalMedicamentos != old.totalMedicamentos ||
      totalProcedimentos != old.totalProcedimentos;
}

/// Tela de usuários: menu próprio, filtro por categoria, sem exclusão.
/// Só a própria pessoa ou administrador pode editar.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({
    super.key,
    required this.usuarioLogado,
    required this.onSair,
    this.onPerfilAtualizado,
  });

  final UsuarioModel? usuarioLogado;
  final VoidCallback onSair;
  final VoidCallback? onPerfilAtualizado;

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _repository = UsuarioRepository();
  final _unidadeRepo = UnidadeHospitalarRepository();
  List<UsuarioModel> _usuarios = [];
  List<UsuarioModel> _pendentes = [];
  String? _erro;
  bool _carregando = true;
  /// Tela inicial: 'dashboard'. Menu 'Usuários do sistema': 'usuarios'.
  String? _selectedMenuId = 'dashboard';
  int _totalUnidades = 0;
  int _totalDfd = 0;
  int _totalAtas = 0;
  int _totalFornecedores = 0;
  int _totalEquipamentos = 0;
  int _totalMedicamentos = 0;
  int _totalProcedimentos = 0;
  /// Menu lateral expandido (true) ou recolhido (false, só ícones).
  bool _sidebarExpanded = true;

  /// Navigator da área de conteúdo: formulários e detalhes abrem aqui (menu continua visível).
  final GlobalKey<NavigatorState> _contentNavKey = GlobalKey<NavigatorState>();

  /// Filtro por categoria (perfil_sistema). null = Todos.
  String? _filtroCategoria;

  static const _opcoesCategoria = [
    ('', 'Todos'),
    ('pendente_aprovacao', 'Pendente de aprovação'),
    ('usuario', 'Usuário'),
    ('administrador', 'Administrador'),
  ];

  bool get _ehAdmin => widget.usuarioLogado?.isAdministrador ?? false;
  String? get _meuId => widget.usuarioLogado?.id;

  String? _backgroundPath;

  @override
  void initState() {
    super.initState();
    _carregar();
    _loadBackground();
  }

  Future<void> _loadBackground() async {
    final path = await BackgroundPreferenceService.getBackgroundPath();
    if (mounted) setState(() => _backgroundPath = path);
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final futures = <Future>[
        _repository.getUsuarios(),
        _unidadeRepo.getAll(),
        DfdRepository().getDfds(),
        AtaRepository().getAtas(),
        FornecedorRepository().getAll(),
        CatmedRepository().getCount(),
        RenemRepository().getCount(),
        ProcedimentoRepository().getCount(),
      ];
      if (_ehAdmin) futures.add(_repository.getUsuariosPendentes());
      final results = await Future.wait(futures);
      final lista = results[0] as List<UsuarioModel>;
      final unidades = results[1] as List;
      final dfds = results[2] as List;
      final atas = results[3] as List;
      final fornecedores = results[4] as List;
      final countCatmed = results[5] as int;
      final countRenem = results[6] as int;
      final countSigtap = results[7] as int;
      setState(() {
        _usuarios = lista;
        _totalUnidades = unidades.length;
        _totalDfd = dfds.length;
        _totalAtas = atas.length;
        _totalFornecedores = fornecedores.length;
        _totalEquipamentos = countRenem;
        _totalMedicamentos = countCatmed;
        _totalProcedimentos = countSigtap;
        _pendentes = _ehAdmin ? results[8] as List<UsuarioModel> : [];
        _carregando = false;
      });
    } catch (e, st) {
      setState(() {
        _erro = '$e\n$st';
        _carregando = false;
      });
    }
  }

  List<UsuarioModel> get _usuariosFiltrados {
    if (_filtroCategoria == null || _filtroCategoria!.isEmpty) return _usuarios;
    return _usuarios.where((u) => u.perfilSistema == _filtroCategoria).toList();
  }

  /// Lista da coluna principal: exclui pendentes (eles só aparecem na sidebar).
  List<UsuarioModel> get _listaPrincipalUsuarios {
    return _usuariosFiltrados
        .where((u) => u.perfilSistema != 'pendente_aprovacao')
        .toList();
  }

  Future<void> _aprovar(UsuarioModel u) async {
    try {
      await _repository.updateUsuario(u.copyWith(perfilSistema: 'usuario'));
      if (mounted) {
        widget.onPerfilAtualizado?.call();
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao aprovar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _podeEditar(UsuarioModel u) {
    if (_meuId != null && u.id == _meuId) return true;
    return _ehAdmin;
  }

  /// Navegador da área de conteúdo (mantém o menu visível). Se null, usa o root.
  NavigatorState? get _contentNavigator => _contentNavKey.currentState;

  void _abrirMeusDados() {
    final nav = _contentNavigator ?? Navigator.of(context);
    nav.push(
      MaterialPageRoute(
        builder: (context) => AtualizarDadosScreen(
          podeAcessarPainel: true,
          onIrParaPainel: () => nav.pop(),
          onSair: widget.onSair,
          onPerfilAtualizado: () {
            widget.onPerfilAtualizado?.call();
            nav.pop();
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _abrirEditarOutro(UsuarioModel u) {
    if (u.id == null) return;
    final nav = _contentNavigator ?? Navigator.of(context);
    nav.push(
      MaterialPageRoute(
        builder: (context) => AtualizarDadosScreen(
          editingUserId: u.id,
          podeAcessarPainel: true,
          onIrParaPainel: () => nav.pop(),
          onSair: widget.onSair,
          onPerfilAtualizado: () {
            widget.onPerfilAtualizado?.call();
            _carregar();
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

  String _labelCategoria(String? p) {
    if (p == null || p.isEmpty) return '—';
    switch (p) {
      case 'pendente_aprovacao':
        return 'Pendente de aprovação';
      case 'usuario':
        return 'Usuário';
      case 'administrador':
        return 'Administrador';
      default:
        return p;
    }
  }

  String _routeFor(String? id) =>
      id == null || id == 'dashboard' ? '/' : '/$id';

  void _navigateTo(String id) {
    setState(() {
      _selectedMenuId = id;
      if (id == 'duplicados') _carregar();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentNavKey.currentState?.pushReplacementNamed(_routeFor(id));
    });
  }

  List<SidebarMenuBlock> _buildMenuBlocks() {
    return [
      SidebarMenuBlock(
        title: 'Início',
        items: [
          SidebarMenuItem(
            id: 'dashboard',
            label: 'Visão geral',
            icon: Icons.dashboard_outlined,
            onTap: () => _navigateTo('dashboard'),
          ),
        ],
      ),
      SidebarMenuBlock(
        title: 'Gestão de Pessoas',
        items: [
          SidebarMenuItem(
            id: 'organograma',
            label: 'Organograma',
            icon: Icons.account_tree,
            onTap: () => _navigateTo('organograma'),
          ),
        ],
      ),
      SidebarMenuBlock(
        title: 'Processos',
        items: [
          SidebarMenuItem(
            id: 'dfd',
            label: 'DFD',
            icon: Icons.assignment_outlined,
            onTap: () => _navigateTo('dfd'),
          ),
          SidebarMenuItem(
            id: 'sigtap',
            label: 'Procedimentos SIGTAP',
            icon: Icons.medical_services_outlined,
            onTap: () => _navigateTo('sigtap'),
          ),
          SidebarMenuItem(
            id: 'catmed',
            label: 'Medicamentos CATMED',
            icon: Icons.medication,
            onTap: () => _navigateTo('catmed'),
          ),
          SidebarMenuItem(
            id: 'renem',
            label: 'Equipamentos RENEM',
            icon: Icons.precision_manufacturing,
            onTap: () => _navigateTo('renem'),
          ),
          SidebarMenuItem(
            id: 'atas',
            label: 'Banco de Atas',
            icon: Icons.gavel,
            onTap: () => _navigateTo('atas'),
          ),
          SidebarMenuItem(
            id: 'fornecedores',
            label: 'Fornecedores',
            icon: Icons.store,
            onTap: () => _navigateTo('fornecedores'),
          ),
          SidebarMenuItem(
            id: 'unidades',
            label: 'Unidades Hospitalares',
            icon: Icons.business,
            onTap: () => _navigateTo('unidades'),
          ),
        ],
      ),
      SidebarMenuBlock(
        title: 'Administradores do sistema',
        items: [
          SidebarMenuItem(
            id: 'usuarios',
            label: 'Usuários do sistema',
            icon: Icons.people_outline,
            onTap: () => _navigateTo('usuarios'),
            visible: _ehAdmin,
          ),
          SidebarMenuItem(
            id: 'duplicados',
            label: 'Usuários duplicados',
            icon: Icons.group_remove,
            onTap: () => _navigateTo('duplicados'),
            visible: _ehAdmin,
          ),
          SidebarMenuItem(
            id: 'gabinete-unidades',
            label: 'Unidades do Gabinete (Gestão Hospitalar)',
            icon: Icons.business_center,
            onTap: () => _navigateTo('gabinete-unidades'),
            visible: _ehAdmin,
          ),
        ],
      ),
    ];
  }

  static const double kContentPadding = 24;

  void _voltarParaDashboard() => _navigateTo('dashboard');

  Route<void> _onGenerateContentRoute(RouteSettings settings) {
    final name = settings.name ?? '/';
    const mainBg = Color(0xFFF5F5F5);
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (ctx) {
        if (name == '/') {
          final scope = _ContentScope.of(ctx);
          return Container(
            color: mainBg,
            child: SingleChildScrollView(
              child: DashboardKpis(
                totalUnidades: scope.totalUnidades,
                totalUsuarios: scope.totalUsuarios,
                onlineCount: null,
                ultimosAcessos: null,
                loading: scope.carregando,
                totalDfd: scope.totalDfd,
                totalAtas: scope.totalAtas,
                totalFornecedores: scope.totalFornecedores,
                totalEquipamentos: scope.totalEquipamentos,
                totalMedicamentos: scope.totalMedicamentos,
                totalProcedimentos: scope.totalProcedimentos,
              ),
            ),
          );
        }
        if (name == '/usuarios') return _ContentScope.of(ctx).childForUsuarios;
        final id = name.startsWith('/') ? name.substring(1) : name;
        return _buildEmbeddedContentForRoute(id);
      },
    );
  }

  Widget _buildEmbeddedContentForRoute(String id) {
    switch (id) {
      case 'organograma':
        return OrganogramaScreen(
          onAbrirMeusDados: _abrirMeusDados,
          onSair: widget.onSair,
          onBack: _voltarParaDashboard,
        );
      case 'dfd':
        return DfdListScreen(
          usuarioLogado: widget.usuarioLogado,
          onBack: _voltarParaDashboard,
        );
      case 'sigtap':
        return ProcedimentosScreen(onBack: _voltarParaDashboard);
      case 'catmed':
        return CatmedScreen(onBack: _voltarParaDashboard);
      case 'renem':
        return RenemScreen(onBack: _voltarParaDashboard);
      case 'atas':
        return AtasScreen(
          usuarioLogado: widget.usuarioLogado,
          onBack: _voltarParaDashboard,
        );
      case 'fornecedores':
        return FornecedoresScreen(onBack: _voltarParaDashboard);
      case 'unidades':
        return UnidadesHospitalaresScreen(
          usuarioLogado: widget.usuarioLogado,
          onAbrirMeusDados: _abrirMeusDados,
          onSair: widget.onSair,
          onBack: _voltarParaDashboard,
        );
      case 'duplicados':
        return DuplicadosScreen(onBack: _voltarParaDashboard);
      case 'gabinete-unidades':
        return GabineteUnidadesScreen(onBack: _voltarParaDashboard);
      default:
        return _buildEmbeddedContent();
    }
  }

  /// Conteúdo das telas que abrem na área principal (ao lado do menu).
  Widget _buildEmbeddedContent() {
    switch (_selectedMenuId) {
      case 'organograma':
        return OrganogramaScreen(
          onAbrirMeusDados: _abrirMeusDados,
          onSair: widget.onSair,
          onBack: _voltarParaDashboard,
        );
      case 'dfd':
        return DfdListScreen(
          usuarioLogado: widget.usuarioLogado,
          onBack: _voltarParaDashboard,
        );
      case 'sigtap':
        return ProcedimentosScreen(onBack: _voltarParaDashboard);
      case 'catmed':
        return CatmedScreen(onBack: _voltarParaDashboard);
      case 'renem':
        return RenemScreen(onBack: _voltarParaDashboard);
      case 'atas':
        return AtasScreen(
          usuarioLogado: widget.usuarioLogado,
          onBack: _voltarParaDashboard,
        );
      case 'fornecedores':
        return FornecedoresScreen(onBack: _voltarParaDashboard);
      case 'unidades':
        return UnidadesHospitalaresScreen(
          usuarioLogado: widget.usuarioLogado,
          onAbrirMeusDados: _abrirMeusDados,
          onSair: widget.onSair,
          onBack: _voltarParaDashboard,
        );
      case 'duplicados':
        return DuplicadosScreen(
          onBack: _voltarParaDashboard,
        );
      case 'gabinete-unidades':
        return GabineteUnidadesScreen(onBack: _voltarParaDashboard);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainBg = Color(0xFFF5F5F5);
    const sidebarBg = Color(0xFFE8E8E8);
    const cardAccent = PedidoCertoTheme.primaryBlue;

    return Scaffold(
      body: Stack(
        children: [
          if (_backgroundPath != null && _backgroundPath!.isNotEmpty) ...[
            Positioned.fill(
              child: _backgroundPath!.startsWith('http')
                  ? Image.network(
                      _backgroundPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    )
                  : Image.asset(
                      _backgroundPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
            ),
            Positioned.fill(
              child: Container(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.92),
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSidebarMenu(
                selectedId: _selectedMenuId,
                menuBlocks: _buildMenuBlocks(),
                userName: widget.usuarioLogado?.nome ?? 'Usuário',
                userEmail: widget.usuarioLogado?.email ?? '',
                onConfiguracoesUsuario: _abrirMeusDados,
                onSair: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) widget.onSair();
                },
                appTitle: 'Pedido Certo',
                expanded: _sidebarExpanded,
                onToggleExpand: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
              ),
              Expanded(
                child: _erro != null
                    ? ConstrainedContent(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Erro ao conectar',
                                  style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: SelectableText(_erro!,
                                      style: const TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _ContentScope(
                        totalUnidades: _totalUnidades,
                        totalUsuarios: _usuarios.length,
                        carregando: _carregando,
                        childForUsuarios: _buildUsuariosLayout(mainBg, sidebarBg, cardAccent),
                        totalDfd: _totalDfd,
                        totalAtas: _totalAtas,
                        totalFornecedores: _totalFornecedores,
                        totalEquipamentos: _totalEquipamentos,
                        totalMedicamentos: _totalMedicamentos,
                        totalProcedimentos: _totalProcedimentos,
                        child: Navigator(
                          key: _contentNavKey,
                          initialRoute: '/',
                          onGenerateRoute: _onGenerateContentRoute,
                        ),
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUsuariosLayout(Color mainBg, Color sidebarBg, Color cardAccent) {
    return LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final useColumn =
                                  width < PedidoCertoTheme.breakpointSidebarStack;
                              final mainContent = Container(
                                color: mainBg,
                                child: ConstrainedContent(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(kContentPadding),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Usuários do sistema',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.settings),
                                              tooltip: 'Configurações',
                                              onPressed: () async {
                                                final nav = _contentNavigator ?? Navigator.of(context);
                                                await nav.push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ConfiguracoesScreen(
                                                      isAdmin: _ehAdmin,
                                                      onBackgroundChanged:
                                                          _loadBackground,
                                                    ),
                                                  ),
                                                );
                                                _loadBackground();
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.refresh),
                                              tooltip: 'Atualizar',
                                              onPressed:
                                                  _carregando ? null : _carregar,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String?>(
                                          value: _filtroCategoria,
                                          decoration: const InputDecoration(
                                            labelText: 'Filtrar por categoria',
                                            border: OutlineInputBorder(),
                                            filled: true,
                                          ),
                                          items: _opcoesCategoria
                                              .map((e) => DropdownMenuItem(
                                                  value: e.$1.isEmpty
                                                      ? null
                                                      : e.$1,
                                                  child: Text(e.$2)))
                                              .toList(),
                                          onChanged: (v) => setState(
                                              () => _filtroCategoria = v),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'Lista de usuários',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .outline,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        _carregando
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : _buildListaUsuarios(context),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                              final sidebarContent = Container(
                                color: sidebarBg,
                                child: LayoutBuilder(
                                  builder: (context, sidebarConstraints) {
                                    final sidebarWidth =
                                        sidebarConstraints.maxWidth;
                                    return SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxWidth: sidebarWidth),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            const SidebarCalendar(),
                                            if (_ehAdmin) ...[
                                              const SizedBox(height: 20),
                                              Text(
                                                'Pendentes de aprovação',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                              _buildPendentesCards(context,
                                                  cardAccent, sidebarWidth),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                              if (useColumn) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 2, child: mainContent),
                                    Expanded(flex: 1, child: sidebarContent),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 2, child: mainContent),
                                  Expanded(flex: 1, child: sidebarContent),
                                ],
                              );
                            },
                          );
  }

  Widget _buildPendentesCards(BuildContext context, Color accentColor, [double? availableWidth]) {
    if (_pendentes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Nenhum pendente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      );
    }
    final narrow = (availableWidth ?? 400) < 220;
    return Column(
      children: _pendentes.map((u) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: accentColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        u.nome,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        u.email ?? '—',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (narrow)
                  IconButton.filled(
                    onPressed: () => _aprovar(u),
                    icon: const Icon(Icons.check, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                    tooltip: 'Aprovar',
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _aprovar(u),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprovar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListaUsuarios(BuildContext context) {
    final lista = _listaPrincipalUsuarios;
    if (lista.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              _filtroCategoria == 'pendente_aprovacao'
                  ? 'Pendentes de aprovação aparecem na barra lateral ao lado.'
                  : _filtroCategoria == null || _filtroCategoria!.isEmpty
                      ? 'Nenhum usuário carregado'
                      : 'Nenhum usuário nesta categoria',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: lista.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final u = lista[i];
          final podeEditar = _podeEditar(u);
          return ListTile(
            title: Text(u.nome),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (u.email != null && u.email!.isNotEmpty) Text(u.email!),
                Text(
                  _labelCategoria(u.perfilSistema),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
            trailing: podeEditar
                ? TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Editar'),
                    onPressed: () {
                      if (u.id == _meuId) {
                        _abrirMeusDados();
                      } else {
                        _abrirEditarOutro(u);
                      }
                    },
                  )
                : null,
          );
        },
      ),
    );
  }
}
