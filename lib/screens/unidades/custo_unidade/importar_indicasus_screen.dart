import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../modules/indicasus/models/indicasus_importacao_model.dart';
import '../../../modules/indicasus/repositories/indicasus_importacao_repository.dart';
import '../../../modules/indicasus/services/xls_indicasus_parser.dart';
import '../../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../../widgets/constrained_content.dart';

/// Mensagem exibida quando o usuário seleciona .xls (formato antigo não suportado).
const String _mensagemConverterXls =
    'Arquivo .xls (Excel 97-2003) não é suportado. '
    'Abra a planilha no Excel e use "Salvar como" → tipo "Pasta de trabalho do Excel (.xlsx)", '
    'depois selecione o arquivo .xlsx aqui.';

/// Tela para importar planilha Indicasus (.xlsx; .xls deve ser convertido) da unidade.
/// Estrutura baseada em relatórios como "Relatorio - Alta Floresta 2018.xls".
class ImportarIndicasusScreen extends StatefulWidget {
  const ImportarIndicasusScreen({
    super.key,
    required this.unidade,
    required this.onImportado,
  });

  final UnidadeHospitalarModel unidade;
  final VoidCallback onImportado;

  @override
  State<ImportarIndicasusScreen> createState() =>
      _ImportarIndicasusScreenState();
}

class _ImportarIndicasusScreenState extends State<ImportarIndicasusScreen> {
  final _repo = IndicasusImportacaoRepository();
  int? _anoDetectado;
  String? _nomeUnidadePlanilha;
  List<Map<String, dynamic>> _linhas = [];
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
        allowedExtensions: ['xls', 'xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final file = result.files.single;
      if (file.bytes == null || file.bytes!.isEmpty) {
        setState(() => _erro =
            'Não foi possível ler o conteúdo do arquivo. Tente novamente.');
        return;
      }
      final isXls = file.name.toLowerCase().endsWith('.xls') &&
          !file.name.toLowerCase().endsWith('.xlsx');
      if (isXls) {
        setState(() => _erro = _mensagemConverterXls);
        return;
      }
      final parsed = XlsIndicasusParser.parse(file.bytes!);
      setState(() {
        _anoDetectado = parsed.anoReferencia;
        _nomeUnidadePlanilha = parsed.nomeUnidade;
        _linhas = parsed.linhas;
        if (parsed.linhas.isEmpty) {
          _erro =
              'Nenhuma linha de dados encontrada. Verifique se a planilha segue o formato Indicasus (ex.: Relatorio - Alta Floresta 2018.xlsx).';
        }
      });
    } on FormatException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        setState(() => _erro =
            msg.contains('Central Directory') || msg.contains('FormatError')
                ? _mensagemConverterXls
                : 'Erro ao ler a planilha: $msg');
      }
    }
  }

  Future<void> _salvar() async {
    if (widget.unidade.id == null || _linhas.isEmpty) return;
    final ano = _anoDetectado ?? DateTime.now().year;
    final anoFoiDetectadoNaPlanilha = _anoDetectado != null;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await _repo.saveOrUpdate(
        IndicasusImportacaoModel(
          unidadeId: widget.unidade.id!,
          anoReferencia: ano,
          nomeUnidadePlanilha: _nomeUnidadePlanilha,
          linhas: _linhas,
        ),
        sobrescreverSeMesmoAno: anoFoiDetectadoNaPlanilha,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              anoFoiDetectadoNaPlanilha
                  ? 'Dados do ano $ano salvos. Só sobrescreve quando já existir importação do mesmo ano de competência.'
                  : 'Novo registro criado (ano $ano). O ano não foi detectado na planilha; nunca sobrescreve por ano diferente.',
            ),
          ),
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
        title: const Text('Importar planilha Indicasus'),
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
                        'Relatório Indicasus (XLS/XLSX)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecione a planilha no formato Indicasus. Use arquivo .xlsx (ou salve .xls como .xlsx no Excel). '
                        'Ex.: Relatorio - Alta Floresta 2018.xlsx. O ano de referência é detectado automaticamente.',
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
                label: const Text('Escolher arquivo XLS ou XLSX'),
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
              if (_linhas.isNotEmpty) ...[
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
                            Icon(Icons.analytics,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              _anoDetectado != null
                                  ? 'Ano de referência detectado: $_anoDetectado'
                                  : 'Ano de referência: ${DateTime.now().year} (não detectado na planilha)',
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
                          '${_linhas.length} linhas de indicadores.',
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
                  label: Text(
                    _salvando
                        ? 'Salvando...'
                        : 'Importar dados Indicasus ${_anoDetectado != null ? "do ano $_anoDetectado" : ""}',
                  ),
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
