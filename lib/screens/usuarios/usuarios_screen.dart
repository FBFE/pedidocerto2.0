import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/pedido_certo_theme.dart';
import '../../modules/usuarios/models/usuario_model.dart';
import '../../modules/usuarios/repositories/usuario_repository.dart';
import '../../services/background_preference_service.dart';
import '../../widgets/constrained_content.dart';
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
import 'duplicados_screen.dart';

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
  List<UsuarioModel> _usuarios = [];
  List<UsuarioModel> _pendentes = [];
  String? _erro;
  bool _carregando = true;

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
      final futures = <Future>[_repository.getUsuarios()];
      if (_ehAdmin) futures.add(_repository.getUsuariosPendentes());
      final results = await Future.wait(futures);
      final lista = results[0] as List<UsuarioModel>;
      setState(() {
        _usuarios = lista;
        _pendentes = results.length > 1 ? results[1] as List<UsuarioModel> : [];
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

  void _abrirMeusDados() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AtualizarDadosScreen(
              podeAcessarPainel: true,
              onIrParaPainel: () => Navigator.of(context).pop(),
              onSair: widget.onSair,
              onPerfilAtualizado: () {
                widget.onPerfilAtualizado?.call();
                Navigator.of(context).pop();
              },
            ),
          ),
        )
        .then((_) => setState(() {}));
  }

  void _abrirEditarOutro(UsuarioModel u) {
    if (u.id == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AtualizarDadosScreen(
              editingUserId: u.id,
              podeAcessarPainel: true,
              onIrParaPainel: () => Navigator.of(context).pop(),
              onSair: widget.onSair,
              onPerfilAtualizado: () {
                widget.onPerfilAtualizado?.call();
                _carregar();
              },
            ),
          ),
        )
        .then((_) => setState(() {}));
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

  @override
  Widget build(BuildContext context) {
    const mainBg = Color(0xFFF5F5F5);
    const sidebarBg = Color(0xFFE8E8E8);
    const cardAccent = PedidoCertoTheme.primaryBlue;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final leadingWidth = (screenWidth < 600) ? 200.0 : 280.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: PedidoCertoTheme.white,
        foregroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
        title: null,
        leadingWidth: leadingWidth,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: PedidoCertoTheme.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  (widget.usuarioLogado?.nome.isNotEmpty == true
                          ? widget.usuarioLogado!.nome[0]
                          : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF1A73E8), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido Certo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((widget.usuarioLogado?.email ?? '').isNotEmpty)
                      Text(
                        widget.usuarioLogado!.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              final availWidth = MediaQuery.sizeOf(context).width - leadingWidth;
              final w = (constraints.maxWidth.isFinite && constraints.maxWidth > 0)
                  ? constraints.maxWidth
                  : availWidth.clamp(0.0, double.infinity);
              if (w <= 0) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                width: w,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Configurações',
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ConfiguracoesScreen(
                                isAdmin: _ehAdmin,
                                onBackgroundChanged: _loadBackground,
                              ),
                            ),
                          );
                          _loadBackground();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.account_tree),
                        tooltip: 'Organograma',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OrganogramaScreen(
                              onAbrirMeusDados: _abrirMeusDados,
                              onSair: widget.onSair,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.assignment_outlined),
                        tooltip: 'DFD',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                DfdListScreen(usuarioLogado: widget.usuarioLogado),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.business),
                        tooltip: 'Unidades Hospitalares',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UnidadesHospitalaresScreen(
                              onAbrirMeusDados: _abrirMeusDados,
                              onSair: widget.onSair,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.medical_services_outlined),
                        tooltip: 'Procedimentos SIGTAP',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProcedimentosScreen(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.medication),
                        tooltip: 'Medicamentos CATMED',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CatmedScreen(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.precision_manufacturing),
                        tooltip: 'Equipamentos RENEM',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RenemScreen(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.gavel),
                        tooltip: 'Banco de Atas',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AtasScreen(usuarioLogado: widget.usuarioLogado),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.store),
                        tooltip: 'Fornecedores',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FornecedoresScreen(),
                          ),
                        ),
                      ),
                      if (_ehAdmin)
                        IconButton(
                          icon: const Icon(Icons.group_remove),
                          tooltip: 'Usuários Duplicados',
                          onPressed: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) => const DuplicadosScreen(),
                                ),
                              )
                              .then((_) => _carregar()),
                        ),
                      IconButton(
                        icon: const Icon(Icons.person),
                        tooltip: 'Meus dados',
                        onPressed: _abrirMeusDados,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Atualizar',
                        onPressed: _carregando ? null : _carregar,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: 'Sair',
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) widget.onSair();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
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
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final useColumn = width < PedidoCertoTheme.breakpointSidebarStack;
                        final mainContent = Container(
                          color: mainBg,
                          child: ConstrainedContent(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(kContentPadding),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
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
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String?>(
                                    initialValue: _filtroCategoria,
                                    decoration: const InputDecoration(
                                      labelText: 'Filtrar por categoria',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                    ),
                                    items: _opcoesCategoria
                                        .map((e) => DropdownMenuItem(
                                            value: e.$1.isEmpty ? null : e.$1,
                                            child: Text(e.$2)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _filtroCategoria = v),
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
                                  _buildListaUsuarios(context),
                                ],
                              ),
                            ),
                          ),
                        );
                        final sidebarContent = Container(
                          color: sidebarBg,
                          child: LayoutBuilder(
                            builder: (context, sidebarConstraints) {
                              final sidebarWidth = sidebarConstraints.maxWidth;
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: sidebarWidth),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildPendentesCards(context, cardAccent, sidebarWidth),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 2,
                                child: mainContent,
                              ),
                              Expanded(
                                flex: 1,
                                child: sidebarContent,
                              ),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: mainContent,
                            ),
                            Expanded(
                              flex: 1,
                              child: sidebarContent,
                            ),
                          ],
                        );
                      },
                    ),
        ],
      ),
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
