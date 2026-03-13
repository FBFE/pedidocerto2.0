import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../modules/indicasus/models/indicasus_importacao_model.dart';
import '../../../modules/indicasus/repositories/indicasus_importacao_repository.dart';
import '../../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';
import '../../../widgets/constrained_content.dart';

/// Opacidade do fundo com logo (marca d'água).
const _kOpacidadeLogoFundo = 0.12;

/// Opacidade dos painéis (cards).
const _kOpacidadePainel = 0.97;

/// Painel SGS: dashboard profissional dos dados Indicasus (indicadores por ano de competência).
/// Layout: logo da unidade como fundo, filtro por ano competência, filtros de colunas, tabela.
class PainelSgsScreen extends StatefulWidget {
  const PainelSgsScreen({
    super.key,
    required this.unidade,
  });

  final UnidadeHospitalarModel unidade;

  @override
  State<PainelSgsScreen> createState() => _PainelSgsScreenState();
}

class _PainelSgsScreenState extends State<PainelSgsScreen> {
  final _repo = IndicasusImportacaoRepository();
  final _unidadeRepo = UnidadeHospitalarRepository();
  List<IndicasusImportacaoModel> _importacoes = [];
  IndicasusImportacaoModel? _selecionada;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (widget.unidade.id == null) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final list = await _repo.getByUnidadeId(widget.unidade.id!);
      setState(() {
        _importacoes = list;
        _selecionada = list.isNotEmpty ? list.first : null;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  List<String> _colunas(IndicasusImportacaoModel imp) {
    if (imp.linhas.isEmpty) return [];
    final primeira = imp.linhas.first;
    final ordem = <String>[];
    for (final k in primeira.keys) {
      final s = k.toString().trim();
      if (s.isNotEmpty && !ordem.contains(s)) ordem.add(s);
    }
    for (final row in imp.linhas) {
      for (final k in row.keys) {
        final s = k.toString().trim();
        if (s.isNotEmpty && !ordem.contains(s)) ordem.add(s);
      }
    }
    return ordem;
  }

  static String _cellText(dynamic v) {
    if (v == null) return '';
    if (v is num) return v.toString();
    return v.toString();
  }

  static double _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
  }

  static final _patternMesAno = RegExp(
    r'(janeiro|fevereiro|mar[cç]o|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s*/\s*\d{4}',
    caseSensitive: false,
  );

  /// Colunas que parecem mês/ano no cabeçalho (ex.: janeiro/2019).
  List<String> _colunasMeses(IndicasusImportacaoModel imp) {
    return _colunas(imp).where((c) => _patternMesAno.hasMatch(c)).toList();
  }

  /// Ordem dos meses: 1 = janeiro, 12 = dezembro. Retorna 0 se não for mês reconhecido.
  static int _indiceMes(String headerOuCelula) {
    final s = headerOuCelula.toLowerCase().trim();
    final i = s.indexOf('/');
    final mes = i >= 0 ? s.substring(0, i).trim() : s;
    const nomes = [
      'janeiro',
      'fevereiro',
      'março',
      'marco',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro'
    ];
    for (var idx = 0; idx < nomes.length; idx++) {
      if (mes.startsWith(nomes[idx])) return idx + 1;
    }
    return 0;
  }

  static const _abrevMeses = [
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

  /// Colunas de valor por período: apenas janeiro a dezembro (12 meses), ordenados, com ano competência nos rótulos.
  ({List<String> colunas, List<String> labels}) _colunasMesesComFallback(
      IndicasusImportacaoModel imp) {
    final ano = '${imp.anoReferencia % 100}'.padLeft(2, '0');
    final cols = _colunas(imp);
    final comMeses = _colunasMeses(imp);
    if (comMeses.isNotEmpty) {
      final comIndice = comMeses
          .map((c) => (col: c, idx: _indiceMes(c)))
          .where((e) => e.idx >= 1 && e.idx <= 12)
          .toList();
      comIndice.sort((a, b) => a.idx.compareTo(b.idx));
      final vistos = <int>{};
      final unicos = <String>[];
      for (final e in comIndice) {
        if (vistos.contains(e.idx)) continue;
        vistos.add(e.idx);
        unicos.add(e.col);
      }
      final labels = unicos.map((c) {
        final idx = _indiceMes(c);
        final abrev = idx >= 1 && idx <= 12
            ? _abrevMeses[idx - 1]
            : (c.length >= 3 ? c.substring(0, 3) : c);
        return ano.isNotEmpty ? '$abrev/$ano' : abrev;
      }).toList();
      return (colunas: unicos, labels: labels);
    }
    // Fallback: colunas genéricas (Col_1, Col_2...) — ordenar por mês da primeira linha, até 12.
    final totalCol = _colunaTotal(imp);
    final candidatas = cols
        .where((c) => c != totalCol && !(c.toUpperCase().contains('TOTAL')))
        .toList();
    final primeiraLinha =
        imp.linhas.isNotEmpty ? imp.linhas.first : <String, dynamic>{};
    final comIndice = <({String col, int idx})>[];
    for (final c in candidatas) {
      bool temNumero = false;
      for (final row in imp.linhas) {
        if (_parseNum(row[c]) != 0) {
          temNumero = true;
          break;
        }
      }
      if (!temNumero) continue;
      final cell = _cellText(primeiraLinha[c]);
      final idx = _patternMesAno.hasMatch(cell) ? _indiceMes(cell) : 0;
      if (idx >= 1 && idx <= 12) comIndice.add((col: c, idx: idx));
    }
    final valorColunas = <String>[];
    if (comIndice.isNotEmpty) {
      comIndice.sort((a, b) => a.idx.compareTo(b.idx));
      final vistos = <int>{};
      for (final e in comIndice) {
        if (vistos.contains(e.idx) || valorColunas.length >= 12) continue;
        vistos.add(e.idx);
        valorColunas.add(e.col);
      }
    }
    if (valorColunas.isEmpty) {
      for (final c in candidatas) {
        if (valorColunas.length >= 12) break;
        bool temNumero = false;
        for (final row in imp.linhas) {
          if (_parseNum(row[c]) != 0) {
            temNumero = true;
            break;
          }
        }
        if (temNumero) valorColunas.add(c);
      }
    }
    if (valorColunas.isEmpty) return (colunas: [], labels: []);
    final labels = valorColunas.asMap().entries.map((e) {
      final col = e.value;
      final cell = _cellText(primeiraLinha[col]);
      final idx = _patternMesAno.hasMatch(cell) ? _indiceMes(cell) : 0;
      final abrev = idx >= 1 && idx <= 12
          ? _abrevMeses[idx - 1]
          : (e.key < _abrevMeses.length ? _abrevMeses[e.key] : col);
      return ano.isNotEmpty ? '$abrev/$ano' : abrev;
    }).toList();
    return (colunas: valorColunas, labels: labels);
  }

  /// Nome da coluna Total, se existir.
  String? _colunaTotal(IndicasusImportacaoModel imp) {
    final cols = _colunas(imp);
    final t = cols.where((c) => c.toUpperCase().contains('TOTAL')).toList();
    return t.isNotEmpty ? t.first : null;
  }

  /// Totais por coluna de mês (soma dos valores numéricos da coluna em todas as linhas).
  List<double> _totaisPorColunas(
      IndicasusImportacaoModel imp, List<String> colunas) {
    return colunas.map((col) {
      double sum = 0;
      for (final row in imp.linhas) {
        sum += _parseNum(row[col]);
      }
      return sum;
    }).toList();
  }

  /// Coluna que melhor representa o nome da categoria (evita usar coluna só com códigos numéricos).
  /// Prefere coluna cujas células tenham texto descritivo (ex.: "1 - RECEITAS OPERACIONAIS...").
  String _colunaCategoriaPizza(IndicasusImportacaoModel imp) {
    final cols = _colunas(imp);
    if (cols.isEmpty) return '';
    final colTotal = _colunaTotal(imp);
    final periodoColunas = _colunasMesesComFallback(imp).colunas;
    final candidatas = cols
        .where((c) => c != colTotal && !periodoColunas.contains(c))
        .toList();
    if (candidatas.isEmpty) return cols.first;

    String? melhor;
    var melhorScore = -1;
    for (final col in candidatas) {
      var score = 0;
      for (final row in imp.linhas) {
        final t = _cellText(row[col]);
        if (t.isEmpty) continue;
        if (t.contains(' - ')) score += 3;
        if (t.length > 25) score += 2;
        if (t.length > 15) score += 1;
        if (_parseNum(t) != 0 && t.length < 15) score -= 2;
      }
      if (score > melhorScore) {
        melhorScore = score;
        melhor = col;
      }
    }
    return melhor ?? candidatas.first;
  }

  /// Dados para pizza: (rótulo, valor). Usa coluna de categoria (descrição) como rótulo e Total ou soma dos períodos como valor.
  List<({String nome, double valor})> _dadosPizza(
      IndicasusImportacaoModel imp) {
    final cols = _colunas(imp);
    if (cols.isEmpty || imp.linhas.isEmpty) return [];
    final colCategoria = _colunaCategoriaPizza(imp);
    final colTotal = _colunaTotal(imp);
    final periodoColunas = _colunasMesesComFallback(imp).colunas;
    final map = <String, double>{};
    for (final row in imp.linhas) {
      final label = _cellText(row[colCategoria]);
      if (label.isEmpty) continue;
      double val = 0;
      if (colTotal != null) val = _parseNum(row[colTotal]);
      if (val == 0 && periodoColunas.isNotEmpty) {
        for (final c in periodoColunas) {
          val += _parseNum(row[c]);
        }
      }
      map[label] = (map[label] ?? 0) + val;
    }
    return map.entries
        .map((e) => (
              nome: e.key.length > 50 ? '${e.key.substring(0, 50)}...' : e.key,
              valor: e.value
            ))
        .where((e) => e.valor > 0)
        .toList()
      ..sort((a, b) => b.valor.compareTo(a.valor));
  }

  static final _fmtMoeda =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
  static const _coresGrafico = [
    Color(0xFF1B4965),
    Color(0xFF2E6B8A),
    Color(0xFF5FA8D3),
    Color(0xFF78B6D4),
    Color(0xFF4A90A4),
    Color(0xFF6B9B9B),
  ];

  Widget _kpiCard(
      BuildContext context, String label, String valor, IconData icon) {
    return _panelWrap(
      context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoBarrasMeses(
      BuildContext context, IndicasusImportacaoModel imp) {
    final res = _colunasMesesComFallback(imp);
    if (res.colunas.isEmpty) return const SizedBox.shrink();
    final totais = _totaisPorColunas(imp, res.colunas);
    final labels = res.labels;
    final maxY = totais.isEmpty
        ? 1.0
        : (totais.reduce((a, b) => a > b ? a : b) * 1.1)
            .clamp(1.0, double.infinity);

    return _panelWrap(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Totais por período (soma dos indicadores) — Ano competência ${imp.anoReferencia}',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i >= 0 && i < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(labels[i],
                                  style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 72,
                        getTitlesWidget: (v, meta) => Text(
                          _fmtMoeda.format(v),
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData:
                      const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(totais.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: totais[i],
                          color: Theme.of(context).colorScheme.primary,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                        _fmtMoeda.format(rod.toY),
                        TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                swapAnimationDuration: const Duration(milliseconds: 200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoPizza(
      BuildContext context, IndicasusImportacaoModel imp) {
    final dados = _dadosPizza(imp);
    if (dados.isEmpty) return const SizedBox.shrink();
    final total = dados.fold<double>(0, (a, e) => a + e.valor);
    if (total <= 0) return const SizedBox.shrink();
    final top = dados.take(8).toList();
    final secao = top.asMap().entries.map((e) {
      return PieChartSectionData(
        value: e.value.valor,
        title: '${(e.value.valor / total * 100).toStringAsFixed(0)}%',
        color: _coresGrafico[e.key % _coresGrafico.length],
        radius: 52,
        titleStyle: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return _panelWrap(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Distribuição por categoria (top 8)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: secao,
                      sectionsSpace: 2,
                      centerSpaceRadius: 28,
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 350),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: top.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _coresGrafico[i % _coresGrafico.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    top[i].nome,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _fmtMoeda.format(top[i].valor),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Gráfico de linha (linha do tempo) — mesmos totais por período.
  Widget _buildGraficoLinhaTempo(
      BuildContext context, IndicasusImportacaoModel imp) {
    final res = _colunasMesesComFallback(imp);
    if (res.colunas.isEmpty) return const SizedBox.shrink();
    final totais = _totaisPorColunas(imp, res.colunas);
    if (totais.isEmpty) return const SizedBox.shrink();
    final maxY = totais.reduce((a, b) => a > b ? a : b) * 1.15;
    const minY = 0.0;
    final spots = totais
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return _panelWrap(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Linha do tempo — totais por período (${imp.anoReferencia})',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (totais.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY.clamp(1.0, double.infinity),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i >= 0 && i < res.labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(res.labels[i],
                                  style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 72,
                        getTitlesWidget: (v, meta) => Text(
                          _fmtMoeda.format(v),
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData:
                      const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: true),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final i = spot.x.toInt();
                          final label = i >= 0 && i < res.labels.length
                              ? res.labels[i]
                              : '';
                          return LineTooltipItem(
                            '$label\n${_fmtMoeda.format(spot.y)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 250),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: totais.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final label =
                      i < res.labels.length ? res.labels[i] : '${i + 1}';
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      child: Text(
                        label.length >= 2
                            ? label.substring(0, 2).toUpperCase()
                            : label.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    label: Text('$label: ${_fmtMoeda.format(totais[i])}',
                        style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelWrap(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: _kOpacidadePainel),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl =
        widget.unidade.logoUrl != null && widget.unidade.logoUrl!.isNotEmpty
            ? _unidadeRepo.logoPublicUrl(widget.unidade.logoUrl)
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel SGS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
            tooltip: 'Atualizar',
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
                        SelectableText(_erro!,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                )
              : _importacoes.isEmpty
                  ? ConstrainedContent(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 24),
                            Text(
                              'Nenhum dado SGS (Indicasus) importado',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Importe uma planilha Indicasus em "Dados da unidade" para visualizar aqui.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox.expand(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (logoUrl != null && logoUrl.isNotEmpty)
                            Positioned.fill(
                              child: Opacity(
                                opacity: _kOpacidadeLogoFundo,
                                child: Image.network(
                                  logoUrl,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ConstrainedContent(
                            child: ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 16, 20, 32),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Indicadores SGS (Indicasus)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _panelWrap(
                                  context,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ano competência',
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
                                        DropdownButtonFormField<
                                            IndicasusImportacaoModel>(
                                          initialValue: _selecionada,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                          isExpanded: true,
                                          items: _importacoes
                                              .map((imp) => DropdownMenuItem(
                                                    value: imp,
                                                    child: Text(
                                                      '${imp.anoReferencia}${imp.nomeUnidadePlanilha != null && imp.nomeUnidadePlanilha!.isNotEmpty ? ' - ${imp.nomeUnidadePlanilha}' : ''}',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ))
                                              .toList(),
                                          onChanged: (v) =>
                                              setState(() => _selecionada = v),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_selecionada != null) ...[
                                  const SizedBox(height: 16),
                                  _panelWrap(
                                    context,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Ano competência ${_selecionada!.anoReferencia} — ${_selecionada!.linhas.length} registros',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                ),
                                                if (_selecionada!.createdAt !=
                                                    null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Importado em ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_selecionada!.createdAt!)}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final colTotal =
                                          _colunaTotal(_selecionada!);
                                      final periodoColunas =
                                          _colunasMesesComFallback(
                                                  _selecionada!)
                                              .colunas;
                                      double somaGeral = 0;
                                      for (final row in _selecionada!.linhas) {
                                        if (colTotal != null) {
                                          somaGeral += _parseNum(row[colTotal]);
                                        }
                                      }
                                      if (somaGeral == 0 &&
                                          periodoColunas.isNotEmpty) {
                                        somaGeral = 0;
                                        for (final row
                                            in _selecionada!.linhas) {
                                          for (final c in periodoColunas) {
                                            somaGeral += _parseNum(row[c]);
                                          }
                                        }
                                      }
                                      return Row(
                                        children: [
                                          Expanded(
                                              child: _kpiCard(
                                                  context,
                                                  'Registros',
                                                  '${_selecionada!.linhas.length}',
                                                  Icons.table_rows)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: _kpiCard(
                                                  context,
                                                  'Soma total',
                                                  _fmtMoeda.format(somaGeral),
                                                  Icons.summarize)),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildGraficoBarrasMeses(
                                      context, _selecionada!),
                                  const SizedBox(height: 16),
                                  _buildGraficoLinhaTempo(
                                      context, _selecionada!),
                                  const SizedBox(height: 16),
                                  _buildGraficoPizza(context, _selecionada!),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
