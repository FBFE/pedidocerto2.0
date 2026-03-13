import 'package:flutter/material.dart';

/// Diálogo com campo de busca e lista agrupada por seções para facilitar localização.
/// Cada seção tem um título em destaque e uma lista de opções.
class SeletorBuscaDialog extends StatefulWidget {
  const SeletorBuscaDialog({
    super.key,
    required this.titulo,
    required this.secoes,
    this.valorAtual,
    this.alturaMaxima = 480,
  });

  final String titulo;

  /// Lista de (título da seção, opções). Ex.: [('Governo', ['Governo: ...']), ('Secretaria', [...])]
  final List<({String titulo, List<String> opcoes})> secoes;
  final String? valorAtual;
  final double alturaMaxima;

  @override
  State<SeletorBuscaDialog> createState() => _SeletorBuscaDialogState();
}

class _SeletorBuscaDialogState extends State<SeletorBuscaDialog> {
  final _buscaController = TextEditingController();
  final _buscaFocus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _buscaFocus.requestFocus());
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _buscaFocus.dispose();
    super.dispose();
  }

  List<({String titulo, List<String> opcoes})> get _secoesFiltradas {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.secoes;
    }
    return widget.secoes
        .map((s) {
          final opcoes =
              s.opcoes.where((o) => o.toLowerCase().contains(q)).toList();
          return (titulo: s.titulo, opcoes: opcoes);
        })
        .where((s) => s.opcoes.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secoes = _secoesFiltradas;

    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: double.maxFinite,
        height: widget.alturaMaxima,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _buscaController,
              focusNode: _buscaFocus,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: secoes.isEmpty
                  ? Center(
                      child: Text(
                        _query.trim().isEmpty
                            ? 'Nenhuma opção disponível.'
                            : 'Nenhum resultado para "$_query".',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.outline),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final sec in secoes) ...[
                          _CabecalhoSecao(titulo: sec.titulo),
                          ...sec.opcoes.map((opcao) {
                            final selecionado = opcao == widget.valorAtual;
                            return ListTile(
                              title: Text(
                                opcao,
                                style: TextStyle(
                                  fontWeight:
                                      selecionado ? FontWeight.w600 : null,
                                  color: selecionado
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                              trailing: selecionado
                                  ? Icon(Icons.check_circle,
                                      color: theme.colorScheme.primary,
                                      size: 22)
                                  : null,
                              onTap: () => Navigator.of(context).pop(opcao),
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _CabecalhoSecao extends StatelessWidget {
  const _CabecalhoSecao({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        titulo,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
