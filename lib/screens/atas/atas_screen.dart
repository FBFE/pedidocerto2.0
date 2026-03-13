import 'package:flutter/material.dart';

import '../../theme/pedido_certo_theme.dart';
import '../../modules/atas/models/ata_model.dart';
import '../../modules/atas/repositories/ata_repository.dart';
import '../../modules/usuarios/models/usuario_model.dart';
import 'cadastro_manual_ata_screen.dart';
import 'detalhe_ata_screen.dart';

/// Lista de atas registradas no banco e entrada para cadastro manual de ata.
class AtasScreen extends StatefulWidget {
  const AtasScreen({super.key, this.usuarioLogado, this.onBack});

  final UsuarioModel? usuarioLogado;
  final VoidCallback? onBack;

  @override
  State<AtasScreen> createState() => _AtasScreenState();
}

class _AtasScreenState extends State<AtasScreen> {
  final _repository = AtaRepository();
  bool _carregando = true;
  String? _erro;
  List<AtaModel> _atas = [];

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
      final list = await _repository.getAtas();
      setState(() {
        _atas = list;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = '$e';
        _carregando = false;
      });
    }
  }

  void _abrirCadastroManual() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CadastroManualAtaScreen(usuarioLogado: widget.usuarioLogado),
      ),
    );
    if (mounted) _carregar();
  }

  void _abrirDetalhe(AtaModel ata) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalheAtaScreen(ata: ata, onExcluido: _carregar),
      ),
    ).then((_) {
      if (mounted) _carregar();
    });
  }

  Future<void> _excluir(AtaModel ata) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ata'),
        content: Text(
            'Tem certeza que deseja excluir esta ata do banco?\n\n${ata.numeroExibicao}'),
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
    if (confirm != true || ata.id == null) return;
    try {
      await _repository.deleteAta(ata.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ata excluída.')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')));
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
        title: const Text('Banco de Atas'),
        backgroundColor: PedidoCertoTheme.white,
        foregroundColor: const Color(0xFF1F2937),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Cadastrar ata (manual)',
            onPressed: _abrirCadastroManual,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregando ? null : _carregar,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                            onPressed: _carregar,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : _atas.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.description_outlined,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.7)),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma ata registrada',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Toque em "Cadastrar ata" para registrar uma nova ata manualmente.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _abrirCadastroManual,
                              icon: const Icon(Icons.add),
                              label: const Text('Cadastrar ata (manual)'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _atas.length,
                      itemBuilder: (context, index) {
                        final ata = _atas[index];
                        final vigencia = (ata.vigenciaInicio != null ||
                                ata.vigenciaFim != null)
                            ? '${ata.vigenciaInicio ?? '?'} a ${ata.vigenciaFim ?? '?'}'
                            : null;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title: Text(
                              ata.numeroExibicao,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ata.orgao != null &&
                                    ata.orgao!.isNotEmpty)
                                  Text(ata.orgao!),
                                if (ata.objeto != null &&
                                    ata.objeto!.isNotEmpty)
                                  Text(
                                    ata.objeto!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (vigencia != null)
                                  Text(
                                    'Vigência: $vigencia',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                    value: 'detalhe',
                                    child: Text('Ver detalhes')),
                                const PopupMenuItem(
                                    value: 'excluir',
                                    child: Text('Excluir')),
                              ],
                              onSelected: (v) {
                                if (v == 'detalhe') _abrirDetalhe(ata);
                                if (v == 'excluir') _excluir(ata);
                              },
                            ),
                            onTap: () => _abrirDetalhe(ata),
                          ),
                        );
                      },
                    ),
    );
  }
}
