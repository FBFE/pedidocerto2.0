import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../modules/custo_unidade/models/custo_unidade_importacao_model.dart';
import '../../../widgets/constrained_content.dart';

/// Exibe o relatório de custo com opção: resumido (sem custos detalhados) ou completo (com custos).
class RelatorioCustoScreen extends StatefulWidget {
  const RelatorioCustoScreen({super.key, required this.importacao});

  final CustoUnidadeImportacaoModel importacao;

  @override
  State<RelatorioCustoScreen> createState() => _RelatorioCustoScreenState();
}

class _RelatorioCustoScreenState extends State<RelatorioCustoScreen> {
  /// false = Resumido (sem custos detalhados); true = Completo (com custos).
  bool _comCustosDetalhados = false;

  static const _meses = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez'
  ];
  static const _mesesLabel = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez'
  ];

  List<LinhaCustoModel> get _linhasExibidas => _comCustosDetalhados
      ? widget.importacao.linhas
      : widget.importacao.linhasResumido;

  static final _fmtMoeda =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

  String _formatarValor(double v) => _fmtMoeda.format(v);

  @override
  Widget build(BuildContext context) {
    final linhas = _linhasExibidas;
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório ${widget.importacao.anoCompetencia}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ConstrainedContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de relatório',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Resumido (sem custos detalhados)'),
                            icon: Icon(Icons.summarize),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Completo (com custos)'),
                            icon: Icon(Icons.table_chart),
                          ),
                        ],
                        selected: {_comCustosDetalhados},
                        onSelectionChanged: (Set<bool> sel) {
                          setState(() => _comCustosDetalhados = sel.first);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _comCustosDetalhados
                            ? 'Exibindo todos os itens de custo (sintético e analítico).'
                            : 'Exibindo apenas: Pessoal, Material de Consumo, Serviços de Terceiros, Despesas Gerais e TOTAL GERAL.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (linhas.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Nenhuma linha para exibir.')),
                  ),
                )
              else
                Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      columns: [
                        DataColumn(
                          label: SizedBox(
                            width: 220,
                            child: Text(
                              'Item Custo',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        ...List.generate(
                          _meses.length,
                          (i) => DataColumn(
                            label: Text(_mesesLabel[i],
                                style: const TextStyle(fontSize: 12)),
                            numeric: true,
                          ),
                        ),
                        const DataColumn(
                          label: Text('Total', style: TextStyle(fontSize: 12)),
                          numeric: true,
                        ),
                      ],
                      rows: linhas.map((linha) {
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  linha.itemCusto,
                                  style: TextStyle(
                                    fontWeight: linha.itemCusto
                                            .toUpperCase()
                                            .contains('TOTAL')
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            ...List.generate(
                              _meses.length,
                              (i) {
                                final mes = _meses[i];
                                final v = linha.valoresMensais[mes] ?? 0.0;
                                return DataCell(Text(_formatarValor(v),
                                    textAlign: TextAlign.end));
                              },
                            ),
                            DataCell(
                              Text(
                                _formatarValor(linha.total),
                                textAlign: TextAlign.end,
                                style: linha.itemCusto
                                        .toUpperCase()
                                        .contains('TOTAL')
                                    ? const TextStyle(
                                        fontWeight: FontWeight.bold)
                                    : null,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
