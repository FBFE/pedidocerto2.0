import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../modules/dfd/models/dfd_model.dart';
import '../../modules/dfd/repositories/dfd_repository.dart';
import '../../modules/permissoes/models/usuario_permissao_model.dart';
import '../../modules/permissoes/services/permissao_service.dart';
import '../../modules/usuarios/models/usuario_model.dart';
import 'dfd_form_screen.dart';

class DfdListScreen extends StatefulWidget {
  final UsuarioModel? usuarioLogado;
  /// Quando preenchido, o botão voltar da AppBar chama este callback (ex.: tela embarcada no dashboard).
  final VoidCallback? onBack;

  const DfdListScreen({super.key, this.usuarioLogado, this.onBack});

  @override
  State<DfdListScreen> createState() => _DfdListScreenState();
}

class _DfdListScreenState extends State<DfdListScreen> {
  final _repository = DfdRepository();
  bool _carregando = true;
  String? _erro;
  List<DfdModel> _dfds = [];
  bool _podeAdicionar = false;
  bool _podeEditar = false;
  bool _podeExcluir = false;

  @override
  void initState() {
    super.initState();
    _carregar();
    _carregarPermissoes();
  }

  Future<void> _carregarPermissoes() async {
    final add = await PermissaoService.canAdicionar(widget.usuarioLogado, ModulosPermissao.dfd);
    final edit = await PermissaoService.canEditar(widget.usuarioLogado, ModulosPermissao.dfd);
    final excl = await PermissaoService.canExcluir(widget.usuarioLogado, ModulosPermissao.dfd);
    if (mounted) setState(() {
      _podeAdicionar = add;
      _podeEditar = edit;
      _podeExcluir = excl;
    });
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dfds = await _repository.getDfds();
      setState(() {
        _dfds = dfds;
        _carregando = false;
      });
    } catch (e, st) {
      setState(() {
        _erro = '$e\n$st';
        _carregando = false;
      });
    }
  }

  Future<void> _excluir(DfdModel dfd) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir DFD'),
        content:
            Text('Tem certeza que deseja excluir o DFD do órgão ${dfd.orgao}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (dfd.id != null) {
        await _repository.deleteDfd(dfd.id!);
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }

  void _abrirForm([DfdModel? dfd]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DfdFormScreen(
            dfd: dfd, usuarioLogado: widget.usuarioLogado, onSaved: _carregar),
      ),
    );
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
        title: const Text('Documentos de Formalização de Demanda (DFD)'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text('Erro: $_erro'))
              : _dfds.isEmpty
                  ? const Center(child: Text('Nenhum DFD cadastrado.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _dfds.length,
                      itemBuilder: (context, index) {
                        final d = _dfds[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(d.orgao,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Setor: ${d.setorRequisitante}'),
                                Text(
                                    'Solicitante: ${d.responsavelDemanda} (Matrícula: ${d.matricula})'),
                                Text('Objeto: ${d.classificacaoObjeto}'),
                                if (d.createdAt != null)
                                  Text(
                                      'Criado em: ${DateFormat('dd/MM/yyyy \'às\' HH:mm').format(d.createdAt!.toLocal())}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            trailing: (_podeEditar || _podeExcluir)
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_podeEditar)
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _abrirForm(d),
                                          tooltip: 'Editar',
                                        ),
                                      if (_podeExcluir)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _excluir(d),
                                          tooltip: 'Excluir',
                                        ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
      floatingActionButton: _podeAdicionar
          ? FloatingActionButton.extended(
              onPressed: () => _abrirForm(),
              icon: const Icon(Icons.add),
              label: const Text('Novo DFD'),
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
