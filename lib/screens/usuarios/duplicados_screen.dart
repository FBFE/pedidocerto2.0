import 'package:flutter/material.dart';
import '../../modules/usuarios/models/usuario_model.dart';
import '../../modules/usuarios/repositories/usuario_repository.dart';

class DuplicadosScreen extends StatefulWidget {
  const DuplicadosScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<DuplicadosScreen> createState() => _DuplicadosScreenState();
}

class _DuplicadosScreenState extends State<DuplicadosScreen> {
  final _repository = UsuarioRepository();
  bool _carregando = true;
  String? _erro;

  // Grupos de usuários duplicados
  List<List<UsuarioModel>> _gruposDuplicados = [];

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
      final todos = await _repository.getUsuarios();

      // Agrupar por nome ou email (ignorando case)
      final gruposPorNome = <String, List<UsuarioModel>>{};

      for (final u in todos) {
        final key = u.nome.trim().toLowerCase();
        gruposPorNome.putIfAbsent(key, () => []).add(u);
      }

      final duplicados =
          gruposPorNome.values.where((g) => g.length > 1).toList();

      setState(() {
        _gruposDuplicados = duplicados;
        _carregando = false;
      });
    } catch (e, st) {
      setState(() {
        _erro = '$e\n$st';
        _carregando = false;
      });
    }
  }

  Future<void> _excluir(UsuarioModel u) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Usuário'),
        content: Text(
            'Tem certeza que deseja excluir o usuário ${u.nome}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      if (u.id != null) {
        await _repository.deleteUsuario(u.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário excluído com sucesso')),
          );
          _carregar();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        title: const Text('Usuários Duplicados'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text('Erro: $_erro'))
              : _gruposDuplicados.isEmpty
                  ? const Center(
                      child: Text('Nenhum usuário duplicado encontrado.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _gruposDuplicados.length,
                      itemBuilder: (context, index) {
                        final grupo = _gruposDuplicados[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Grupo ${index + 1}: ${grupo.first.nome}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const Divider(),
                                ...grupo.map((u) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(u.nome),
                                      subtitle: Text(
                                          '${u.email ?? "Sem email"} - Perfil: ${u.perfilSistema ?? "Sem perfil"}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _excluir(u),
                                        tooltip: 'Excluir usuário',
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
