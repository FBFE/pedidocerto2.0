import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../modules/custo_unidade/models/custo_unidade_importacao_model.dart';
import '../../../modules/custo_unidade/repositories/custo_unidade_importacao_repository.dart';
import '../../../modules/indicasus/models/indicasus_importacao_model.dart';
import '../../../modules/indicasus/repositories/indicasus_importacao_repository.dart';
import '../../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../../widgets/constrained_content.dart';
import 'importar_custo_screen.dart';
import 'importar_indicasus_screen.dart';
import 'painel_sgs_screen.dart';
import 'painel_tatico_screen.dart';
import 'relatorio_custo_screen.dart';

/// Menu "Dados da unidade": lista importações e permite importar nova planilha.
class DadosUnidadeScreen extends StatefulWidget {
  const DadosUnidadeScreen({
    super.key,
    required this.unidade,
    this.onAtualizado,
  });

  final UnidadeHospitalarModel unidade;
  final VoidCallback? onAtualizado;

  @override
  State<DadosUnidadeScreen> createState() => _DadosUnidadeScreenState();
}

class _DadosUnidadeScreenState extends State<DadosUnidadeScreen> {
  final _repo = CustoUnidadeImportacaoRepository();
  final _repoIndicasus = IndicasusImportacaoRepository();
  List<CustoUnidadeImportacaoModel> _lista = [];
  List<IndicasusImportacaoModel> _listaIndicasus = [];
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
      final listIndicasus =
          await _repoIndicasus.getByUnidadeId(widget.unidade.id!);
      setState(() {
        _lista = list;
        _listaIndicasus = listIndicasus;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _abrirImportar() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ImportarCustoScreen(
          unidade: widget.unidade,
          onImportado: _carregar,
        ),
      ),
    );
    if (ok == true && mounted) _carregar();
  }

  Future<void> _abrirImportarIndicasus() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ImportarIndicasusScreen(
          unidade: widget.unidade,
          onImportado: _carregar,
        ),
      ),
    );
    if (ok == true && mounted) _carregar();
  }

  Future<void> _abrirRelatorio(CustoUnidadeImportacaoModel imp) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RelatorioCustoScreen(importacao: imp),
      ),
    );
  }

  Future<void> _abrirPainelTatico() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PainelTaticoScreen(unidade: widget.unidade),
      ),
    );
  }

  Future<void> _abrirPainelSgs() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PainelSgsScreen(unidade: widget.unidade),
      ),
    );
  }

  Future<void> _mostrarHistoricoIndicasus(IndicasusImportacaoModel imp) async {
    if (imp.id == null) return;
    List<HistoricoIndicasusModel> historico = [];
    try {
      historico = await _repoIndicasus.getHistorico(imp.id!);
    } catch (_) {}
    if (!mounted) return;
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Histórico - Ano competência ${imp.anoReferencia} (SGS)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: historico.isEmpty
                  ? const Center(child: Text('Nenhum registro no histórico.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: historico.length,
                      itemBuilder: (context, i) {
                        final h = historico[i];
                        final tipoLabel = h.tipo == 'criacao'
                            ? 'Importação'
                            : (h.tipo == 'reimportacao'
                                ? 'Reimportação'
                                : 'Edição');
                        return ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              h.tipo == 'criacao'
                                  ? Icons.upload
                                  : (h.tipo == 'reimportacao'
                                      ? Icons.refresh
                                      : Icons.edit),
                              size: 20,
                            ),
                          ),
                          title: Text(tipoLabel),
                          subtitle: Text(
                            '${fmt.format(h.ocorridoEm)}${h.usuarioEmail != null ? '\n${h.usuarioEmail}' : ''}',
                          ),
                          trailing: h.descricao != null
                              ? Text(h.descricao!,
                                  style: Theme.of(context).textTheme.bodySmall)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarHistorico(CustoUnidadeImportacaoModel imp) async {
    if (imp.id == null) return;
    List<HistoricoImportacaoModel> historico = [];
    try {
      historico = await _repo.getHistorico(imp.id!);
    } catch (_) {}
    if (!mounted) return;
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Histórico de modificações - Ano ${imp.anoCompetencia}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: historico.isEmpty
                  ? const Center(child: Text('Nenhum registro no histórico.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: historico.length,
                      itemBuilder: (context, i) {
                        final h = historico[i];
                        final tipoLabel = h.tipo == 'criacao'
                            ? 'Importação'
                            : (h.tipo == 'edicao' ? 'Edição' : 'Reimportação');
                        return ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                                h.tipo == 'criacao' ? Icons.upload : Icons.edit,
                                size: 20),
                          ),
                          title: Text(tipoLabel),
                          subtitle: Text(
                              '${fmt.format(h.ocorridoEm)}${h.usuarioEmail != null ? '\n${h.usuarioEmail}' : ''}'),
                          trailing: h.descricao != null
                              ? Text(h.descricao!,
                                  style: Theme.of(context).textTheme.bodySmall)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados da unidade'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar planilha',
            onPressed: widget.unidade.id == null ? null : _abrirImportar,
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
              : ConstrainedContent(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // ——— APURASUS ———
                      Row(
                        children: [
                          Icon(Icons.account_balance,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Apurasus',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading:
                              const CircleAvatar(child: Icon(Icons.bar_chart)),
                          title: const Text('Painel Tático'),
                          subtitle: const Text(
                            'Dashboard com KPIs, gráficos e relatório por ano (custo)',
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _lista.isEmpty ? null : _abrirPainelTatico,
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.table_chart)),
                          title:
                              const Text('Importar relatório de custo (CSV)'),
                          subtitle: const Text(
                            'Planilha Relatório Custo Total da Unidade (Apurasus) - ano competência será detectado (ex.: 2025)',
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _abrirImportar,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Importações Apurasus',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_lista.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.folder_open,
                                      size: 48,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma importação Apurasus ainda',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: _abrirImportar,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text(
                                        'Importar primeira planilha'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ..._lista.map(
                          (imp) {
                            final fmtData = DateFormat('dd/MM/yyyy', 'pt_BR');
                            final importadoEm = imp.createdAt != null
                                ? fmtData.format(imp.createdAt!)
                                : null;
                            final alteradoEm = imp.updatedAt != null
                                ? fmtData.format(imp.updatedAt!)
                                : null;
                            return Card(
                              child: ListTile(
                                title: Text('Ano ${imp.anoCompetencia}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (imp.nomeUnidadePlanilha != null &&
                                        imp.nomeUnidadePlanilha!.isNotEmpty)
                                      Text(imp.nomeUnidadePlanilha!),
                                    if (importadoEm != null)
                                      Text('Importado em $importadoEm',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    if (alteradoEm != null)
                                      Text('Última alteração em $alteradoEm',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.history),
                                      tooltip: 'Histórico de modificações',
                                      onPressed: () => _mostrarHistorico(imp),
                                    ),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                  ],
                                ),
                                onTap: () => _abrirRelatorio(imp),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 28),
                      const Divider(height: 1),
                      const SizedBox(height: 20),
                      // ——— SGS (Indicasus) ———
                      Row(
                        children: [
                          Icon(Icons.analytics,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'SGS (Indicasus)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.dashboard_customize)),
                          title: const Text('Painel SGS'),
                          subtitle: const Text(
                            'Dashboard dos indicadores Indicasus por ano',
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap:
                              _listaIndicasus.isEmpty ? null : _abrirPainelSgs,
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.upload_file)),
                          title:
                              const Text('Importar relatório Indicasus (XLS)'),
                          subtitle: const Text(
                            'Planilha Indicasus da unidade - ano de referência detectado (ex.: Relatorio - Alta Floresta 2018.xlsx)',
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _abrirImportarIndicasus,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Importações SGS',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_listaIndicasus.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.analytics_outlined,
                                      size: 48,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma importação SGS ainda',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: _abrirImportarIndicasus,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text(
                                        'Importar planilha Indicasus'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ..._listaIndicasus.map(
                          (imp) {
                            final fmtData = DateFormat('dd/MM/yyyy', 'pt_BR');
                            final importadoEm = imp.createdAt != null
                                ? fmtData.format(imp.createdAt!)
                                : null;
                            return Card(
                              child: ListTile(
                                title: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                    children: [
                                      const TextSpan(text: 'Ano competência: '),
                                      TextSpan(
                                        text: '${imp.anoReferencia}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (imp.nomeUnidadePlanilha != null &&
                                        imp.nomeUnidadePlanilha!.isNotEmpty)
                                      Text(imp.nomeUnidadePlanilha!),
                                    if (importadoEm != null)
                                      Text('Importado em $importadoEm',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    if (imp.updatedAt != null)
                                      Text(
                                        'Última alteração em ${fmtData.format(imp.updatedAt!)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                    Text('${imp.linhas.length} indicadores',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.history),
                                      tooltip: 'Histórico de modificações',
                                      onPressed: () =>
                                          _mostrarHistoricoIndicasus(imp),
                                    ),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                  ],
                                ),
                                onTap: _abrirPainelSgs,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}
