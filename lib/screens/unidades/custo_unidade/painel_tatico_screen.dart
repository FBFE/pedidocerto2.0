import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../modules/custo_unidade/models/custo_unidade_importacao_model.dart';
import '../../../modules/custo_unidade/repositories/custo_unidade_importacao_repository.dart';
import '../../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';
import '../../../widgets/constrained_content.dart';

/// Painel Tático: dashboard com KPIs, gráfico e tabela por ano. Tela externa para todas as informações.
class PainelTaticoScreen extends StatefulWidget {
  const PainelTaticoScreen({
    super.key,
    required this.unidade,
  });

  final UnidadeHospitalarModel unidade;

  @override
  State<PainelTaticoScreen> createState() => _PainelTaticoScreenState();
}

/// Opacidade dos itens do painel (5% de transparência = 95% opaco).
const _kOpacidadePainel = 0.95;

/// Opacidade da logo em marca d'água (75% de transparência = 25% opaco).
const _kOpacidadeMarcaDagua = 0.25;

class _PainelTaticoScreenState extends State<PainelTaticoScreen> {
  final _repo = CustoUnidadeImportacaoRepository();
  final _unidadeRepo = UnidadeHospitalarRepository();
  List<CustoUnidadeImportacaoModel> _importacoes = [];
  CustoUnidadeImportacaoModel? _selecionada;
  bool _carregando = true;
  String? _erro;
  bool _comCustosDetalhados = false;

  /// true = Com RH (todos os dados); false = Sem RH (exclui Pessoal e subitens).
  bool _comRh = true;

  /// Índices dos meses visíveis na tabela (0..11). Vazio = todos visíveis.
  Set<int> _mesesVisiveis = {};

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

  static final _fmtMoeda =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

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

  double _totalGeralAno(CustoUnidadeImportacaoModel imp) {
    for (final l in imp.linhasResumido) {
      if (l.itemCusto.toUpperCase().contains('TOTAL GERAL')) return l.total;
    }
    return 0;
  }

  double _valorCategoriaAno(CustoUnidadeImportacaoModel imp, String nome) {
    final nomeNorm = _norm(nome);
    for (final l in imp.linhasResumido) {
      if (_norm(l.itemCusto) == nomeNorm) return l.total;
    }
    return 0;
  }

  String _norm(String s) {
    return s.trim().replaceAll('η', 'ç').replaceAll('α', 'á');
  }

  List<double> _totaisMensais(CustoUnidadeImportacaoModel imp) {
    final totalGeral = imp.linhasResumido.cast<LinhaCustoModel?>().firstWhere(
          (l) => l!.itemCusto.toUpperCase().contains('TOTAL GERAL'),
          orElse: () => null,
        );
    if (totalGeral == null) return List.filled(12, 0.0);
    return _meses.map((m) => totalGeral.valoresMensais[m] ?? 0.0).toList();
  }

  /// Verifica se a linha é de RH (Pessoal ou Remuneração a Pessoal).
  static bool _isRh(LinhaCustoModel l) {
    final t = l.itemCusto.trim().toLowerCase();
    if (t == 'pessoal') return true;
    if (t.contains('remuneração') && t.contains('pessoal')) return true;
    return false;
  }

  /// Totais mensais considerando filtro RH: Sem RH = soma só Material, Serviços, Despesas.
  List<double> _totaisMensaisFiltrados(CustoUnidadeImportacaoModel imp) {
    if (_comRh) return _totaisMensais(imp);
    final material = _valorCategoriaAno(imp, 'Material de Consumo');
    final servicos = _valorCategoriaAno(imp, 'Serviços de Terceiros');
    final despesas = _valorCategoriaAno(imp, 'Despesas Gerais');
    if (material == 0 && servicos == 0 && despesas == 0) {
      return List.filled(12, 0.0);
    }
    final linhasResumido = imp.linhasResumido;
    LinhaCustoModel? getLinha(String nome) {
      final n = _norm(nome);
      for (final l in linhasResumido) {
        if (_norm(l.itemCusto) == n) return l;
      }
      return null;
    }

    final mL = getLinha('Material de Consumo');
    final sL = getLinha('Serviços de Terceiros');
    final dL = getLinha('Despesas Gerais');
    return List.generate(12, (i) {
      final m = _meses[i];
      return (mL?.valoresMensais[m] ?? 0) +
          (sL?.valoresMensais[m] ?? 0) +
          (dL?.valoresMensais[m] ?? 0);
    });
  }

  /// Total geral do ano considerando filtro: Sem RH = Material + Serviços + Despesas.
  double _totalGeralAnoFiltrado(CustoUnidadeImportacaoModel imp) {
    if (_comRh) return _totalGeralAno(imp);
    return _valorCategoriaAno(imp, 'Material de Consumo') +
        _valorCategoriaAno(imp, 'Serviços de Terceiros') +
        _valorCategoriaAno(imp, 'Despesas Gerais');
  }

  /// Valor da categoria considerando filtro: Sem RH e Pessoal = 0.
  double _valorCategoriaAnoFiltrado(
      CustoUnidadeImportacaoModel imp, String nome) {
    if (!_comRh && _norm(nome) == _norm('Pessoal')) return 0;
    return _valorCategoriaAno(imp, nome);
  }

  /// Linhas para exibição (tabela/relatório): Sem RH exclui Pessoal e subitens e recalcula o total.
  List<LinhaCustoModel> _linhasFiltradas(CustoUnidadeImportacaoModel imp) {
    if (_comRh) return _comCustosDetalhados ? imp.linhas : imp.linhasResumido;
    final base = _comCustosDetalhados ? imp.linhas : imp.linhasResumido;
    var semRh = base.where((l) => !_isRh(l)).toList();
    semRh = semRh
        .where((l) => !l.itemCusto.toUpperCase().contains('TOTAL GERAL'))
        .toList();
    final valoresMensais = <String, double>{};
    for (var i = 0; i < _meses.length; i++) {
      valoresMensais[_meses[i]] = _totaisMensaisFiltrados(imp)[i];
    }
    semRh.add(LinhaCustoModel(
        itemCusto: 'Total (sem RH)', valoresMensais: valoresMensais));
    return semRh;
  }

  /// Linhas resumido para gráficos (pizza/barras): Sem RH = 3 categorias + total.
  List<({String nome, double valor})> _dadosCategoriasFiltrados(
      CustoUnidadeImportacaoModel imp) {
    final totalAno = _totalGeralAnoFiltrado(imp);
    if (totalAno <= 0) return [];
    final pessoal = _valorCategoriaAnoFiltrado(imp, 'Pessoal');
    final material = _valorCategoriaAnoFiltrado(imp, 'Material de Consumo');
    final servicos = _valorCategoriaAnoFiltrado(imp, 'Serviços de Terceiros');
    final despesas = _valorCategoriaAnoFiltrado(imp, 'Despesas Gerais');
    final dados = <({String nome, double valor})>[];
    if (pessoal > 0) dados.add((nome: 'Pessoal', valor: pessoal));
    if (material > 0) dados.add((nome: 'Material de Consumo', valor: material));
    if (servicos > 0) {
      dados.add((nome: 'Serviços de Terceiros', valor: servicos));
    }
    if (despesas > 0) dados.add((nome: 'Despesas Gerais', valor: despesas));
    return dados;
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_erro != null) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: ConstrainedContent(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                SelectableText(_erro!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }
    if (_importacoes.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: ConstrainedContent(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart,
                    size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma importação para esta unidade',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Importe planilhas de custo em "Dados da unidade" para ver o painel.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final imp = _selecionada!;
    final totaisMensais = _totaisMensaisFiltrados(imp);
    final totalAno = _totalGeralAnoFiltrado(imp);
    final pessoal = _valorCategoriaAnoFiltrado(imp, 'Pessoal');
    final material = _valorCategoriaAnoFiltrado(imp, 'Material de Consumo');
    final servicos = _valorCategoriaAnoFiltrado(imp, 'Serviços de Terceiros');
    final despesas = _valorCategoriaAnoFiltrado(imp, 'Despesas Gerais');

    final logoUrl =
        widget.unidade.logoUrl != null && widget.unidade.logoUrl!.isNotEmpty
            ? _unidadeRepo.logoPublicUrl(widget.unidade.logoUrl)
            : null;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (logoUrl != null && logoUrl.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: _kOpacidadeMarcaDagua,
                  child: Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ConstrainedContent(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSeletorAno(context),
                    const SizedBox(height: 28),
                    Text(
                      'KPIs - Ano ${imp.anoCompetencia}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossCount = constraints.maxWidth > 900
                            ? 5
                            : (constraints.maxWidth > 600 ? 3 : 2);
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.2,
                          children: [
                            _kpiCard(context, 'Total Geral', totalAno,
                                Icons.account_balance_wallet),
                            _kpiCard(context, 'Pessoal', pessoal, Icons.people),
                            _kpiCard(context, 'Material de Consumo', material,
                                Icons.inventory_2),
                            _kpiCard(context, 'Serviços de Terceiros', servicos,
                                Icons.build),
                            _kpiCard(context, 'Despesas Gerais', despesas,
                                Icons.receipt_long),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Custo mensal (TOTAL GERAL)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _panelWrap(
                      context,
                      child: SizedBox(
                        height: 260,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (totaisMensais.isEmpty
                                    ? 1.0
                                    : (totaisMensais
                                            .reduce((a, b) => a > b ? a : b) *
                                        1.1))
                                .clamp(1.0, double.infinity)
                                .toDouble(),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, meta) {
                                    final i = v.toInt();
                                    if (i >= 0 && i < _mesesLabel.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(_mesesLabel[i],
                                            style:
                                                const TextStyle(fontSize: 10)),
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
                            gridData: const FlGridData(
                                show: true, drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(12, (i) {
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: totaisMensais[i],
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 18,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: (totaisMensais.isEmpty
                                          ? 1.0
                                          : totaisMensais.reduce(
                                                  (a, b) => a > b ? a : b) *
                                              1.1),
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
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) =>
                                        BarTooltipItem(
                                  _fmtMoeda.format(rod.toY),
                                  TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          swapAnimationDuration:
                              const Duration(milliseconds: 200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Dashboard - Relatório visual',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 800;
                        return isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: _buildGraficoPizza(context, imp)),
                                  const SizedBox(width: 24),
                                  Expanded(
                                      child:
                                          _buildBarrasCategorias(context, imp)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildGraficoPizza(context, imp),
                                  const SizedBox(height: 24),
                                  _buildBarrasCategorias(context, imp),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 28),
                    _panelWrap(
                      context,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _buildToggleRelatorio(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTabelaResumo(context, imp),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Envolve um item do painel com fundo semi-transparente (5% transparência).
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Painel Tático'),
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
    );
  }

  void _abrirFiltrosColunasMeses() {
    final selecionados = _mesesVisiveis.isEmpty
        ? Set<int>.from(List.generate(12, (i) => i))
        : Set<int>.from(_mesesVisiveis);
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Filtros de colunas (meses)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  12,
                  (i) => CheckboxListTile(
                        title: Text(_mesesLabel[i]),
                        value: selecionados.contains(i),
                        onChanged: (v) {
                          if (v == true) {
                            selecionados.add(i);
                          } else {
                            selecionados.remove(i);
                          }
                          setDialog(() {});
                        },
                      )),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                selecionados.clear();
                selecionados.addAll(List.generate(12, (i) => i));
                setDialog(() {});
              },
              child: const Text('Marcar todos'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => _mesesVisiveis = Set.from(selecionados));
                Navigator.of(context).pop();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  List<int> _indicesMesesVisiveis() {
    if (_mesesVisiveis.isEmpty) return List.generate(12, (i) => i);
    return _mesesVisiveis.toList()..sort();
  }

  Widget _buildSeletorAno(BuildContext context) {
    return _panelWrap(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Ano competência:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: _selecionada?.anoCompetencia,
              items: _importacoes
                  .map((i) => DropdownMenuItem(
                      value: i.anoCompetencia,
                      child: Text('${i.anoCompetencia}')))
                  .toList(),
              onChanged: (ano) {
                if (ano == null) return;
                setState(() => _selecionada =
                    _importacoes.firstWhere((e) => e.anoCompetencia == ano));
              },
            ),
            const SizedBox(width: 20),
            Text('RH:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: true,
                    label: Text('Com RH'),
                    icon: Icon(Icons.people, size: 18)),
                ButtonSegment(
                    value: false,
                    label: Text('Sem RH'),
                    icon: Icon(Icons.person_off, size: 18)),
              ],
              selected: {_comRh},
              onSelectionChanged: (s) => setState(() => _comRh = s.first),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _abrirFiltrosColunasMeses,
              tooltip: 'Filtros de colunas (meses)',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.unidade.nome,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(
      BuildContext context, String label, double valor, IconData icon) {
    return _panelWrap(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 22, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
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
            const SizedBox(height: 12),
            Text(
              _fmtMoeda.format(valor),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRelatorio(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
              value: false,
              label: Text('Resumido'),
              icon: Icon(Icons.summarize)),
          ButtonSegment(
              value: true,
              label: Text('Completo'),
              icon: Icon(Icons.table_chart)),
        ],
        selected: {_comCustosDetalhados},
        onSelectionChanged: (s) =>
            setState(() => _comCustosDetalhados = s.first),
      ),
    );
  }

  static const _coresCategorias = [
    Color(0xFF1B4965),
    Color(0xFF2E6B8A),
    Color(0xFF5FA8D3),
    Color(0xFF78B6D4),
  ];

  Widget _buildGraficoPizza(
      BuildContext context, CustoUnidadeImportacaoModel imp) {
    final totalAno = _totalGeralAnoFiltrado(imp);
    if (totalAno <= 0) return const SizedBox.shrink();
    final dados = _dadosCategoriasFiltrados(imp);
    if (dados.isEmpty) return const SizedBox.shrink();
    final secao = dados
        .asMap()
        .entries
        .map((e) => PieChartSectionData(
              value: e.value.valor,
              title: '${(e.value.valor / totalAno * 100).toStringAsFixed(0)}%',
              color: _coresCategorias[e.key % _coresCategorias.length],
              radius: 60,
              titleStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ))
        .toList();
    return _panelWrap(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição por categoria',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: secao,
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 350),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                          dados.length,
                          (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                            color: _coresCategorias[
                                                i % _coresCategorias.length],
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(dados[i].nome,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                            overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              )),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarrasCategorias(
      BuildContext context, CustoUnidadeImportacaoModel imp) {
    final dados = _dadosCategoriasFiltrados(imp);
    if (dados.isEmpty) return const SizedBox.shrink();
    final maxVal = dados
        .map((d) => d.valor)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);
    return _panelWrap(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparativo por categoria (R\$)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...List.generate(dados.length, (i) {
              final item = dados[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.nome,
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(_fmtMoeda.format(item.valor),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxVal > 0 ? (item.valor / maxVal) : 0,
                        minHeight: 20,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _coresCategorias[i % _coresCategorias.length]),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaResumo(
      BuildContext context, CustoUnidadeImportacaoModel imp) {
    final linhas = _linhasFiltradas(imp);
    final indicesMeses = _indicesMesesVisiveis();

    return _panelWrap(
      context,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest),
          columns: [
            DataColumn(
              label: SizedBox(
                width: 220,
                child: Text('Item Custo',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            ...indicesMeses.map((i) => DataColumn(
                label:
                    Text(_mesesLabel[i], style: const TextStyle(fontSize: 11)),
                numeric: true)),
            const DataColumn(
                label: Text('Total', style: TextStyle(fontSize: 11)),
                numeric: true),
          ],
          rows: linhas.map((l) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      l.itemCusto,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight:
                              l.itemCusto.toUpperCase().contains('TOTAL')
                                  ? FontWeight.bold
                                  : null),
                    ),
                  ),
                ),
                ...indicesMeses.map((i) => DataCell(Text(
                    _fmtMoeda.format(l.valoresMensais[_meses[i]] ?? 0),
                    textAlign: TextAlign.end))),
                DataCell(Text(_fmtMoeda.format(l.total),
                    textAlign: TextAlign.end,
                    style: l.itemCusto.toUpperCase().contains('TOTAL')
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
