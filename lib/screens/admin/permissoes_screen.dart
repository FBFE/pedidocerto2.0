import 'package:flutter/material.dart';

import '../../modules/permissoes/models/usuario_permissao_model.dart';
import '../../modules/permissoes/repositories/usuario_permissao_repository.dart';
import '../../modules/usuarios/models/usuario_model.dart';
import '../../modules/usuarios/repositories/usuario_repository.dart';
import '../../widgets/constrained_content.dart';

/// Tela de atribuição de permissões: grid de usuários agrupados por unidade e setor.
class PermissoesScreen extends StatefulWidget {
  const PermissoesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<PermissoesScreen> createState() => _PermissoesScreenState();
}

class _PermissoesScreenState extends State<PermissoesScreen> {
  final _usuarioRepo = UsuarioRepository();
  final _permissaoRepo = UsuarioPermissaoRepository();

  List<UsuarioModel> _usuarios = [];
  bool _carregando = true;
  String? _erro;

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
      final lista = await _usuarioRepo.getUsuarios();
      final apenasAprovados = lista.where((u) => u.perfilSistema != 'pendente_aprovacao').toList();
      if (mounted) {
        setState(() {
          _usuarios = apenasAprovados;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _carregando = false;
        });
      }
    }
  }

  /// Agrupa usuários por (unidade, setor).
  Map<String, List<UsuarioModel>> get _grupos {
    final map = <String, List<UsuarioModel>>{};
    for (final u in _usuarios) {
      final unidade = u.unidadeLotacao?.trim().isEmpty == true ? 'Sem unidade' : (u.unidadeLotacao ?? 'Sem unidade');
      final setor = u.setorLotacao?.trim().isEmpty == true ? 'Sem setor' : (u.setorLotacao ?? 'Sem setor');
      final chave = '$unidade|$setor';
      map.putIfAbsent(chave, () => []).add(u);
    }
    for (final lista in map.values) {
      lista.sort((a, b) => (a.nome).compareTo(b.nome));
    }
    final chaves = map.keys.toList()..sort();
    return Map.fromEntries(chaves.map((k) => MapEntry(k, map[k]!)));
  }

  Future<void> _mostrarDetalhesUsuario(UsuarioModel usuario) async {
    if (usuario.id == null) return;
    List<UsuarioPermissaoModel> permissoes = await _permissaoRepo.getByUsuarioId(usuario.id!);
    final map = {for (var p in permissoes) p.modulo: p};
    for (final modulo in ModulosPermissao.todos) {
      map.putIfAbsent(modulo, () => UsuarioPermissaoModel(usuarioId: usuario.id!, modulo: modulo));
    }
    permissoes = ModulosPermissao.todos.map((m) => map[m]!).toList();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _DialogDetalhesUsuario(
        usuario: usuario,
        permissoes: permissoes,
        onEditarAtribuicoes: () {
          Navigator.of(context).pop();
          _abrirAtribuicoes(usuario);
        },
      ),
    );
  }

  Future<void> _abrirAtribuicoes(UsuarioModel usuario) async {
    if (usuario.id == null) return;
    List<UsuarioPermissaoModel> permissoes = await _permissaoRepo.getByUsuarioId(usuario.id!);
    final map = {for (var p in permissoes) p.modulo: p};
    for (final modulo in ModulosPermissao.todos) {
      map.putIfAbsent(modulo, () => UsuarioPermissaoModel(usuarioId: usuario.id!, modulo: modulo));
    }
    permissoes = ModulosPermissao.todos.map((m) => map[m]!).toList();

    if (!mounted) return;
    final listaSalva = await showDialog<List<UsuarioPermissaoModel>>(
      context: context,
      builder: (context) => _DialogPermissoes(
        usuario: usuario,
        permissoesIniciais: permissoes,
        onSalvar: (lista) async {
          await _permissaoRepo.setPermissoes(usuario.id!, lista);
          if (context.mounted) Navigator.of(context).pop(lista);
        },
      ),
    );
    final salvo = listaSalva != null;
    if (salvo == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
            : null,
        title: const Text('Permissões dos usuários'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregando ? null : _carregar, tooltip: 'Atualizar'),
        ],
      ),
      body: ConstrainedContent(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(onPressed: _carregar, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
                      ],
                    ),
                  )
                : _usuarios.isEmpty
                    ? const Center(child: Text('Nenhum usuário aprovado para exibir.'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Usuários agrupados por unidade e setor. Toque no usuário para ver detalhes e permissões; use "Atribuições" para alterar.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 24),
                            ..._grupos.entries.map((e) {
                              final parts = e.key.split('|');
                              final unidade = parts.isNotEmpty ? parts[0] : '';
                              final setor = parts.length > 1 ? parts[1] : '';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 20),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.business, color: Theme.of(context).colorScheme.primary, size: 22),
                                          const SizedBox(width: 8),
                                          Text(
                                            unidade,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      if (setor.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 30),
                                          child: Text('Setor: $setor', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      ...e.value.map((u) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(u.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                                            subtitle: Text(u.email ?? '—', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                            onTap: () => _mostrarDetalhesUsuario(u),
                                            trailing: FilledButton.tonalIcon(
                                              icon: const Icon(Icons.security, size: 18),
                                              label: const Text('Atribuições'),
                                              onPressed: () => _abrirAtribuicoes(u),
                                              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
      ),
    );
  }
}

/// Diálogo que exibe detalhes do usuário e suas permissões (somente leitura).
class _DialogDetalhesUsuario extends StatelessWidget {
  const _DialogDetalhesUsuario({
    required this.usuario,
    required this.permissoes,
    required this.onEditarAtribuicoes,
  });

  final UsuarioModel usuario;
  final List<UsuarioPermissaoModel> permissoes;
  final VoidCallback onEditarAtribuicoes;

  @override
  Widget build(BuildContext context) {
    final unidade = usuario.unidadeLotacao?.trim().isEmpty == true ? 'Sem unidade' : (usuario.unidadeLotacao ?? 'Sem unidade');
    final setor = usuario.setorLotacao?.trim().isEmpty == true ? 'Sem setor' : (usuario.setorLotacao ?? 'Sem setor');
    final ehAdmin = usuario.isAdministrador;

    return AlertDialog(
      title: const Text('Detalhes do usuário'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _linha(context, 'Nome', usuario.nome),
              _linha(context, 'E-mail', usuario.email ?? '—'),
              _linha(context, 'Unidade', unidade),
              _linha(context, 'Setor', setor),
              _linha(context, 'Perfil', ehAdmin ? 'Administrador' : 'Usuário'),
              const SizedBox(height: 16),
              if (ehAdmin) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Administrador: acesso total a todas as funcionalidades.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Permissões por funcionalidade:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...permissoes.map((p) {
                  final ad = p.adicionar ? 'Adicionar ✓' : 'Adicionar —';
                  final ed = p.editar ? 'Editar ✓' : 'Editar —';
                  final ex = p.excluir ? 'Excluir ✓' : 'Excluir —';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 160,
                          child: Text(
                            ModulosPermissao.label(p.modulo),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$ad · $ed · $ex',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        FilledButton.icon(
          icon: const Icon(Icons.security, size: 18),
          label: const Text('Atribuições'),
          onPressed: () => onEditarAtribuicoes(),
        ),
      ],
    );
  }

  Widget _linha(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _DialogPermissoes extends StatefulWidget {
  const _DialogPermissoes({
    required this.usuario,
    required this.permissoesIniciais,
    required this.onSalvar,
  });

  final UsuarioModel usuario;
  final List<UsuarioPermissaoModel> permissoesIniciais;
  final Future<void> Function(List<UsuarioPermissaoModel> lista) onSalvar;

  @override
  State<_DialogPermissoes> createState() => _DialogPermissoesState();
}

class _DialogPermissoesState extends State<_DialogPermissoes> {
  late List<UsuarioPermissaoModel> _permissoes;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _permissoes = widget.permissoesIniciais.map((p) => p.copyWith()).toList();
  }

  void _atualizar(String modulo, {bool? adicionar, bool? editar, bool? excluir}) {
    setState(() {
      final i = _permissoes.indexWhere((e) => e.modulo == modulo);
      if (i < 0) return;
      _permissoes[i] = _permissoes[i].copyWith(
        adicionar: adicionar ?? _permissoes[i].adicionar,
        editar: editar ?? _permissoes[i].editar,
        excluir: excluir ?? _permissoes[i].excluir,
      );
    });
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await widget.onSalvar(_permissoes);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Atribuições de permissão'),
          const SizedBox(height: 4),
          Text(
            widget.usuario.nome,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Marque as ações permitidas para cada funcionalidade:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ..._permissoes.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ModulosPermissao.label(p.modulo), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 24,
                            runSpacing: 4,
                            children: [
                              SizedBox(
                                width: 140,
                                child: CheckboxListTile(
                                  value: p.adicionar,
                                  onChanged: (v) => _atualizar(p.modulo, adicionar: v),
                                  title: const Text('Adicionar', style: TextStyle(fontSize: 14)),
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  dense: true,
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: CheckboxListTile(
                                  value: p.editar,
                                  onChanged: (v) => _atualizar(p.modulo, editar: v),
                                  title: const Text('Editar', style: TextStyle(fontSize: 14)),
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  dense: true,
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: CheckboxListTile(
                                  value: p.excluir,
                                  onChanged: (v) => _atualizar(p.modulo, excluir: v),
                                  title: const Text('Excluir', style: TextStyle(fontSize: 14)),
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
        ),
      ],
    );
  }
}
