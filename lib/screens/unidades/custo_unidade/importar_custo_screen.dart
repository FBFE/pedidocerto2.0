import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../modules/custo_unidade/models/custo_unidade_importacao_model.dart';
import '../../../modules/custo_unidade/repositories/custo_unidade_importacao_repository.dart';
import '../../../modules/custo_unidade/services/csv_custo_parser.dart';
import '../../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../../widgets/constrained_content.dart';

/// Tela para importar planilha CSV do Relatório Custo Total da Unidade.
/// Detecta o ano de competência (ex.: 2025) da linha de datas.
class ImportarCustoScreen extends StatefulWidget {
  const ImportarCustoScreen({
    super.key,
    required this.unidade,
    required this.onImportado,
  });

  final UnidadeHospitalarModel unidade;
  final VoidCallback onImportado;

  @override
  State<ImportarCustoScreen> createState() => _ImportarCustoScreenState();
}

class _ImportarCustoScreenState extends State<ImportarCustoScreen> {
  final _repo = CustoUnidadeImportacaoRepository();
  int? _anoDetectado;
  String? _nomeUnidadePlanilha;
  List<LinhaCustoModel> _linhas = [];
  bool _salvando = false;
  String? _erro;

  Future<void> _escolherArquivo() async {
    setState(() {
      _erro = null;
      _anoDetectado = null;
      _nomeUnidadePlanilha = null;
      _linhas = [];
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final file = result.files.single;
      if (file.bytes == null || file.bytes!.isEmpty) {
        setState(() => _erro =
            'Não foi possível ler o conteúdo do arquivo. Tente usar "Escolher arquivo" novamente.');
        return;
      }
      // Planilhas exportadas no Brasil costumam vir em Latin-1 (ISO-8859-1), não UTF-8
      final text = _decodeCsvBytes(file.bytes!);
      if (text.isEmpty) {
        setState(() => _erro = 'Arquivo vazio ou não foi possível ler.');
        return;
      }
      final parsed = CsvCustoParser.parse(text);
      setState(() {
        _anoDetectado = parsed.ano;
        _nomeUnidadePlanilha = parsed.nomeUnidade;
        _linhas = parsed.linhas;
        if (parsed.ano == null && parsed.linhas.isEmpty) {
          _erro =
              'Formato não reconhecido. Use o CSV do Relatório Custo Total da Unidade.';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    }
  }

  /// Decoda bytes do CSV: tenta UTF-8; se falhar (ex.: Latin-1 do Excel), usa Latin-1.
  static String _decodeCsvBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  Future<void> _salvar() async {
    if (widget.unidade.id == null || _anoDetectado == null || _linhas.isEmpty) {
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await _repo.insert(CustoUnidadeImportacaoModel(
        unidadeId: widget.unidade.id!,
        anoCompetencia: _anoDetectado!,
        nomeUnidadePlanilha: _nomeUnidadePlanilha,
        linhas: _linhas,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Dados do ano $_anoDetectado importados com sucesso.')),
        );
        widget.onImportado();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar planilha de custo'),
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
                        'Relatório Custo Total da Unidade (CSV)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecione o arquivo CSV exportado (ex.: Relatorio_Custo_Total_da_Unidade - Alta Floresta - Apurasus.csv). '
                        'O ano de competência (ex.: 2025) será detectado automaticamente a partir das datas na planilha.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _salvando ? null : _escolherArquivo,
                icon: const Icon(Icons.folder_open),
                label: const Text('Escolher arquivo CSV'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_erro!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ),
              ],
              if (_anoDetectado != null && _linhas.isNotEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Ano de competência detectado: $_anoDetectado',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        if (_nomeUnidadePlanilha != null &&
                            _nomeUnidadePlanilha!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Unidade na planilha: $_nomeUnidadePlanilha',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${_linhas.length} linhas de custo (itens + valores mensais).',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_salvando
                      ? 'Salvando...'
                      : 'Importar dados do ano $_anoDetectado'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
