import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/pedido_certo_theme.dart';
import '../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';
import '../../widgets/constrained_content.dart';
import 'unidade_hospitalar_detalhe_screen.dart';
import 'unidade_hospitalar_form_screen.dart';

class UnidadesHospitalaresScreen extends StatefulWidget {
  const UnidadesHospitalaresScreen({
    super.key,
    this.onAbrirMeusDados,
    this.onSair,
    this.onBack,
  });

  final VoidCallback? onAbrirMeusDados;
  final VoidCallback? onSair;
  /// Quando preenchido, o botão voltar chama este callback (ex.: tela embarcada no dashboard).
  final VoidCallback? onBack;

  @override
  State<UnidadesHospitalaresScreen> createState() =>
      _UnidadesHospitalaresScreenState();
}

class _UnidadesHospitalaresScreenState
    extends State<UnidadesHospitalaresScreen> {
  final _repo = UnidadeHospitalarRepository();
  List<UnidadeHospitalarModel> _lista = [];
  String? _erro;
  bool _carregando = true;
  /// true = grid, false = lista (toggle como na referência).
  bool _useGridView = true;

  /// Nome e e-mail do usuário logado (Supabase Auth) para o header.
  String get _nomeUsuario {
    final user = Supabase.instance.client.auth.currentUser;
    final nome = user?.userMetadata?['nome'] as String?;
    if (nome != null && nome.toString().trim().isNotEmpty) return nome.trim();
    return user?.email ?? 'Usuário';
  }

  static const _nomePagina = 'Unidades Hospitalares';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await _repo.getAll();
      setState(() {
        _lista = lista;
        _carregando = false;
      });
    } catch (e, st) {
      setState(() {
        _erro = '$e\n$st';
        _carregando = false;
      });
    }
  }

  Future<void> _abrirDetalhe(UnidadeHospitalarModel unidade) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => UnidadeHospitalarDetalheScreen(
          unidade: unidade,
          onAtualizado: _carregar,
        ),
      ),
    );
    if (context.mounted) _carregar();
  }

  Future<void> _abrirFormulario({UnidadeHospitalarModel? unidade}) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => UnidadeHospitalarFormScreen(
          unidade: unidade,
          onSaved: () => _carregar(),
        ),
      ),
    );
    if (ok == true && context.mounted) _carregar();
  }

  void _mostrarMenuUnidade(UnidadeHospitalarModel u) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _abrirFormulario(unidade: u);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmarExcluir(u);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExcluir(UnidadeHospitalarModel u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir unidade'),
        content: Text(
          'Excluir "${u.nome}"? A logo também será removida do armazenamento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      if (u.id == null) return;
      await _repo.delete(u.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidade excluída')),
        );
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  static const _mainBg = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mainBg,
      appBar: AppBar(
        backgroundColor: PedidoCertoTheme.white,
        foregroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
        title: null,
        leadingWidth: 280,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: PedidoCertoTheme.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  _nomeUsuario.isNotEmpty ? _nomeUsuario[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: PedidoCertoTheme.primaryBlue, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nomeUsuario,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _nomePagina,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
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
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
          if (_lista.isNotEmpty)
            IconButton(
              icon: Icon(_useGridView ? Icons.view_list : Icons.grid_view),
              tooltip: _useGridView ? 'Exibir como lista' : 'Exibir em grid',
              onPressed: () => setState(() => _useGridView = !_useGridView),
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
          if (widget.onSair != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                widget.onSair?.call();
              },
            ),
        ],
      ),
      body: _carregando
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
                        Text('Erro ao carregar',
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
              : _lista.isEmpty
                  ? ConstrainedContent(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma unidade cadastrada',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: () => _abrirFormulario(),
                              icon: const Icon(Icons.add),
                              label: const Text('Cadastrar primeira unidade'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ConstrainedContent(
                      child: _useGridView
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = constraints.maxWidth;
                                  final crossAxisCount = width > 1200
                                      ? 4
                                      : (width > 800 ? 3 : (width > 500 ? 2 : 1));
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 1.2,
                                    ),
                                    itemCount: _lista.length,
                                    itemBuilder: (context, i) {
                                      final u = _lista[i];
                                      final logoUrl =
                                          u.logoUrl != null && u.logoUrl!.isNotEmpty
                                              ? _repo.logoPublicUrl(u.logoUrl)
                                              : null;
                                      return _GridUnidadeCard(
                                        unidade: u,
                                        logoUrl: logoUrl,
                                        onTap: () => _abrirDetalhe(u),
                                        onLongPress: () => _mostrarMenuUnidade(u),
                                      );
                                    },
                                  );
                                },
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(24),
                              itemCount: _lista.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final u = _lista[i];
                                final logoUrl =
                                    u.logoUrl != null && u.logoUrl!.isNotEmpty
                                        ? _repo.logoPublicUrl(u.logoUrl)
                                        : null;
                                return _ListUnidadeTile(
                                  unidade: u,
                                  logoUrl: logoUrl,
                                  onTap: () => _abrirDetalhe(u),
                                  onLongPress: () => _mostrarMenuUnidade(u),
                                );
                              },
                            ),
                    ),
      floatingActionButton: _erro == null
          ? FloatingActionButton(
              onPressed: () => _abrirFormulario(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.grid_view),
            )
          : null,
    );
  }
}

/// Item de lista: logo + nome + descrição/sigla.
class _ListUnidadeTile extends StatelessWidget {
  const _ListUnidadeTile({
    required this.unidade,
    this.logoUrl,
    required this.onTap,
    required this.onLongPress,
  });

  final UnidadeHospitalarModel unidade;
  final String? logoUrl;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final descricao = unidade.descricao ?? unidade.sigla ?? '';
    return Material(
      color: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: logoUrl != null
                      ? Image.network(
                          logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.business,
                                  size: 32,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.6)),
                        )
                      : Icon(Icons.business,
                          size: 32,
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.6)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unidade.nome,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (descricao.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        descricao,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card do grid no estilo Figma: fundo cinza claro, ícone/logo no topo, Nome e Descrição.
class _GridUnidadeCard extends StatelessWidget {
  const _GridUnidadeCard({
    required this.unidade,
    this.logoUrl,
    required this.onTap,
    required this.onLongPress,
  });

  final UnidadeHospitalarModel unidade;
  final String? logoUrl;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final descricao = unidade.descricao ?? unidade.sigla ?? '';
    return Material(
      color: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: logoUrl != null
                      ? Image.network(
                          logoUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderIcon(context),
                        )
                      : _buildPlaceholderIcon(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                unidade.nome,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (descricao.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Icon(
      Icons.business,
      size: 48,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
    );
  }
}
