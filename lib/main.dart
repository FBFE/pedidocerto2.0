import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'modules/usuarios/models/usuario_model.dart';
import 'modules/usuarios/repositories/usuario_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/nova_senha_screen.dart';
import 'screens/configuracoes/configuracoes_screen.dart';
import 'screens/profile/atualizar_dados_screen.dart';
import 'screens/organograma/organograma_screen.dart';
import 'screens/unidades/unidades_hospitalares_screen.dart';
import 'screens/usuarios/usuarios_screen.dart';
import 'services/background_preference_service.dart';
import 'theme/pedido_certo_theme.dart';
import 'widgets/constrained_content.dart';

/// True quando o usuário entrou pelo link "Redefinir senha" do e-mail (web).
bool _pendingPasswordRecovery = false;
bool get pendingPasswordRecovery => _pendingPasswordRecovery;
void clearPendingPasswordRecovery() {
  _pendingPasswordRecovery = false;
}

/// Inicialização assíncrona do app. Usado por web_entrypoint para aguardar
/// antes do bootstrap encerrar, evitando tela branca na web.
Future<void> runPedidoCerto() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Detectar link de redefinição de senha (antes do Supabase processar a URL)
  if (kIsWeb) {
    final uri = Uri.base;
    if (uri.fragment.contains('type=recovery') ||
        uri.queryParameters['type'] == 'recovery') {
      _pendingPasswordRecovery = true;
    }
  }

  try {
    await Supabase.initialize(
      url: 'https://bwdyzdhguwknbcagdado.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3ZHl6ZGhndXdrbmJjYWdkYWRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMjc4MTIsImV4cCI6MjA4NzcwMzgxMn0.K8r2jN4b9AH6fev9zUfQ5yJa7hb42MvepC78dPAkXtw',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  } catch (e, stack) {
    runApp(_ErroInicializacaoApp(erro: e, stack: stack));
    return;
  }

  runApp(const PedidoCertoApp());
}

void main() async {
  await runPedidoCerto();
}

/// Mostra o erro na tela quando a inicialização (ex.: Supabase) falha.
class _ErroInicializacaoApp extends StatelessWidget {
  const _ErroInicializacaoApp({required this.erro, this.stack});

  final Object erro;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Erro ao iniciar o app',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(erro.toString()),
                  if (stack != null) ...[
                    const SizedBox(height: 16),
                    Text(stack.toString(),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PedidoCertoApp extends StatelessWidget {
  const PedidoCertoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedido Certo',
      theme: PedidoCertoTheme.theme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}

/// Exibe Login ou Criar conta; após login redireciona para atualizar dados.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showRegister = false;

  void _goToLoggedIn() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && pendingPasswordRecovery) {
      return NovaSenhaScreen(
        onSucesso: () {
          clearPendingPasswordRecovery();
          setState(() {});
        },
      );
    }
    if (session != null) {
      return LoggedInWrapper(onSair: _goToLoggedIn);
    }
    if (_showRegister) {
      return RegisterScreen(
        onNavigateToLogin: () => setState(() => _showRegister = false),
        onRegisterSuccess: _goToLoggedIn,
      );
    }
    return LoginScreen(
      onNavigateToRegister: () => setState(() => _showRegister = true),
      onLoginSuccess: _goToLoggedIn,
    );
  }
}

/// Após login: carrega perfil do usuário. Pendente de aprovação só vê "Meus dados"; aprovados acessam o painel.
class LoggedInWrapper extends StatefulWidget {
  const LoggedInWrapper({super.key, required this.onSair});

  final VoidCallback onSair;

  @override
  State<LoggedInWrapper> createState() => _LoggedInWrapperState();
}

class _LoggedInWrapperState extends State<LoggedInWrapper> {
  UsuarioModel? _usuarioLogado;
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      setState(() => _carregandoPerfil = false);
      return;
    }
    try {
      final u = await UsuarioRepository().getUsuarioByEmail(email);
      if (mounted) {
        setState(() {
          _usuarioLogado = u;
          _carregandoPerfil = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregandoPerfil = false);
    }
  }

  bool get _podeAcessarPainel {
    if (_usuarioLogado == null) return false;
    return !_usuarioLogado!.isPendenteAprovacao;
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoPerfil) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_podeAcessarPainel) {
      return UsuariosScreen(
        usuarioLogado: _usuarioLogado,
        onSair: widget.onSair,
        onPerfilAtualizado: _carregarPerfil,
      );
    }
    return AtualizarDadosScreen(
      podeAcessarPainel: false,
      onIrParaPainel: () {},
      onSair: widget.onSair,
      onPerfilAtualizado: _carregarPerfil,
    );
  }
}

class TesteUsuariosPage extends StatefulWidget {
  const TesteUsuariosPage({
    super.key,
    this.usuarioLogado,
    this.onAbrirMeusDados,
    this.onSair,
    this.onPerfilAtualizado,
  });

  final UsuarioModel? usuarioLogado;
  final VoidCallback? onAbrirMeusDados;
  final VoidCallback? onSair;
  final VoidCallback? onPerfilAtualizado;

  @override
  State<TesteUsuariosPage> createState() => _TesteUsuariosPageState();
}

class _TesteUsuariosPageState extends State<TesteUsuariosPage> {
  final _repository = UsuarioRepository();
  List<UsuarioModel> _usuarios = [];
  List<UsuarioModel> _pendentes = [];
  String? _erro;
  bool _carregando = true;
  String? _backgroundPath;

  bool get _ehAdmin => widget.usuarioLogado?.isAdministrador ?? false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido Certo'),
        actions: [
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
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrganogramaScreen(
                    onAbrirMeusDados: widget.onAbrirMeusDados,
                    onSair: widget.onSair,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.business),
            tooltip: 'Unidades Hospitalares',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UnidadesHospitalaresScreen(
                    usuarioLogado: widget.usuarioLogado,
                    onAbrirMeusDados: widget.onAbrirMeusDados,
                    onSair: widget.onSair,
                  ),
                ),
              );
            },
          ),
          if (widget.onAbrirMeusDados != null)
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Meus dados',
              onPressed: widget.onAbrirMeusDados,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregando ? null : _carregar,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                widget.onSair?.call();
                final state =
                    context.findAncestorStateOfType<_AuthWrapperState>();
                state?.setState(() {});
              }
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
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao conectar',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _erro!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildBodyConteudo(context),
        ],
      ),
    );
  }

  Widget _buildBodyConteudo(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final nome = user?.userMetadata?['nome'] as String? ?? email;

    return ConstrainedContent(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(kContentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra do usuário (estilo sistema profissional)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nome,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Acesso rápido
            Text(
              'Acesso rápido',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 400;
                return Row(
                  children: [
                    Expanded(
                      child: _CardAcesso(
                        icon: Icons.account_tree,
                        label: 'Organograma',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OrganogramaScreen(
                                onAbrirMeusDados: widget.onAbrirMeusDados,
                                onSair: widget.onSair,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (isWide) const SizedBox(width: 12),
                    Expanded(
                      child: _CardAcesso(
                        icon: Icons.business,
                        label: 'Unidades Hospitalares',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UnidadesHospitalaresScreen(
                                usuarioLogado: widget.usuarioLogado,
                                onAbrirMeusDados: widget.onAbrirMeusDados,
                                onSair: widget.onSair,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_ehAdmin && _pendentes.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Pendentes de aprovação',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _pendentes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = _pendentes[i];
                    return ListTile(
                      title: Text(u.nome),
                      subtitle: Text(u.email ?? '—'),
                      trailing: FilledButton.icon(
                        onPressed: () => _aprovar(u),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Aprovar'),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Usuários do sistema',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (_usuarios.isEmpty && _erro == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum usuário carregado',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _carregar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recarregar'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _usuarios.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = _usuarios[i];
                    final parts = <String>[
                      if (u.email != null && u.email!.isNotEmpty) u.email!,
                      if (u.cargo != null && u.cargo!.isNotEmpty) u.cargo!,
                    ];
                    return ListTile(
                      title: Text(u.nome),
                      subtitle: Text(parts.isEmpty ? '—' : parts.join(' · ')),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardAcesso extends StatelessWidget {
  const _CardAcesso({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              Icon(icon,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
