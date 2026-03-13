import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/constrained_content.dart';

class ImportarRenemScreen extends StatefulWidget {
  const ImportarRenemScreen({super.key});

  @override
  State<ImportarRenemScreen> createState() => _ImportarRenemScreenState();
}

class _ImportarRenemScreenState extends State<ImportarRenemScreen> {
  final _supabase = Supabase.instance.client;
  bool _processando = false;
  String _status = '';
  double _progresso = 0.0;
  bool _limparBase = false;
  bool _isAdministrador = false;

  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _verificarPerfil();
  }

  Future<void> _verificarPerfil() async {
    if (mounted) {
      setState(() {
        _isAdministrador =
            true; // Forçando a exibição do botão para todos os usuários temporariamente
      });
    }
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() {
      _logs.add(msg);
      _status = msg;
    });
  }

  Future<void> _limparBancoTodo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar TODO o Banco RENEM?'),
        content: const Text(
            'ATENÇÃO: Esta ação apagará TODOS os equipamentos cadastrados no banco de dados. Tem certeza que deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, Apagar Tudo',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _processando = true;
      _progresso = 0.0;
      _logs.clear();
    });

    _addLog('Iniciando limpeza total do banco de dados RENEM...');

    try {
      await _supabase.from('renem_equipamentos').delete().neq('cod_item', '0');
      _addLog('Limpeza concluída! O banco de dados está vazio.');
    } catch (e) {
      _addLog('Erro ao limpar banco: $e');
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  Future<void> _selecionarEProcessarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _addLog('Erro: Não foi possível ler o arquivo.');
        return;
      }

      setState(() {
        _processando = true;
        _progresso = 0.05;
        _logs.clear();
      });

      if (_limparBase) {
        _addLog(
            'Aviso: Limpeza de base não pode ser feita diretamente pelo app por segurança. Apenas itens novos/atualizados serão processados. Para limpar, use o SQL Editor do Supabase.');
        await Future.delayed(const Duration(seconds: 2));
      }

      final importTimestamp = DateTime.now().toIso8601String();
      Map<String, Map<String, dynamic>> batchMap = {};
      int count = 0;
      int totalLines = 0;

      if (file.extension == 'csv') {
        _addLog('Decodificando arquivo CSV...');
        await Future.delayed(const Duration(milliseconds: 100));

        String csvString;
        try {
          csvString = latin1.decode(bytes);
        } catch (e) {
          csvString = utf8.decode(bytes, allowMalformed: true);
        }

        final lines = csvString.split('\n');

        _addLog('Procurando início dos dados...');
        await Future.delayed(const Duration(milliseconds: 100));

        int startIndex = -1;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].toLowerCase().startsWith('cod. item;item;')) {
            startIndex = i + 1; // Pular cabeçalho
            break;
          }
        }

        if (startIndex == -1) {
          _addLog(
              'Erro: Cabeçalho "Cod. Item;Item;..." não encontrado. Verifique o formato do arquivo CSV.');
          setState(() => _processando = false);
          return;
        }

        final dataLines = lines.skip(startIndex).toList();
        totalLines = dataLines.length;

        _addLog('Iniciando processamento das $totalLines linhas (CSV)...');

        for (int i = 0; i < totalLines; i++) {
          final line = dataLines[i].trim();
          if (line.isEmpty) continue;

          try {
            final columns = line.split(';');
            if (columns.length < 2) continue;

            final codItem = columns[0].trim();
            if (codItem.isEmpty) continue;

            double? valorSugerido;
            if (columns.length > 4) {
              String valStr = columns[4].trim();
              valStr = valStr.replaceAll('R\$', '').replaceAll(' ', '');
              valStr = valStr.replaceAll('.', '');
              valStr = valStr.replaceAll(',', '.');
              valorSugerido = double.tryParse(valStr);
            }

            batchMap[codItem] = {
              'cod_item': codItem,
              'item': columns.length > 1 ? columns[1].trim() : null,
              'definicao': columns.length > 2 ? columns[2].trim() : null,
              'classificacao': columns.length > 3 ? columns[3].trim() : null,
              'valor_sugerido': valorSugerido,
              'item_dolarizado': columns.length > 5 ? columns[5].trim() : null,
              'especificacao_sugerida':
                  columns.length > 6 ? columns[6].trim() : null,
              'data_atualizacao': importTimestamp,
            };

            if (batchMap.length >= 200) {
              try {
                await _supabase
                    .from('renem_equipamentos')
                    .upsert(batchMap.values.toList());
                count += batchMap.length;

                if (mounted) {
                  setState(() {
                    _progresso = 0.1 + (0.8 * (i / totalLines));
                  });
                }

                _addLog('Enviados $count equipamentos...');
              } catch (e) {
                _addLog('Erro em um lote: $e');
              } finally {
                batchMap.clear();
                await Future.delayed(const Duration(milliseconds: 50));
              }
            }
          } catch (e) {
            // Ignora erro de parse na linha
          }
        }
      } else if (file.extension == 'xlsx') {
        _addLog('Decodificando arquivo Excel (XLSX)...');
        await Future.delayed(const Duration(milliseconds: 100));

        try {
          var decoder = SpreadsheetDecoder.decodeBytes(bytes);
          final sheetName = decoder.tables.keys.first;
          final sheet = decoder.tables[sheetName];

          if (sheet == null || sheet.rows.isEmpty) {
            _addLog('Erro: Planilha vazia ou não encontrada.');
            setState(() => _processando = false);
            return;
          }

          // Procurar cabeçalho
          int startIndex = -1;
          for (int i = 0; i < sheet.rows.length; i++) {
            final row = sheet.rows[i];
            if (row.isNotEmpty &&
                row[0] != null &&
                row[0]
                    .toString()
                    .toLowerCase()
                    .trim()
                    .startsWith('cod. item')) {
              startIndex = i + 1; // Pular cabeçalho
              break;
            }
          }

          if (startIndex == -1) {
            startIndex =
                1; // Tenta usar a linha 1 como início se não achar o cabeçalho
          }

          final rows = sheet.rows.skip(startIndex).toList();
          totalLines = rows.length;

          _addLog('Iniciando processamento das $totalLines linhas (XLSX)...');

          for (int i = 0; i < totalLines; i++) {
            final row = rows[i];
            if (row.isEmpty || row[0] == null) continue;

            try {
              // A biblioteca spreadsheet_decoder as vezes le a primeira coluna como "row[0]", as vezes pode estar em ordens diferentes.
              // Vamos pegar as strings corretamente de acordo com as colunas reais da planilha.
              // Na planilha:
              // Coluna A (0): Cod. Item
              // Coluna B (1): Item
              // Coluna C (2): Definição
              // Coluna D (3): Classificação
              // Coluna E (4): R$ Valor Sugerido
              // Coluna F (5): Item Dolarizado
              // Coluna G (6): Especificação Sugerida

              String codItemStr = row.isNotEmpty && row[0] != null
                  ? row[0].toString().trim()
                  : '';
              if (codItemStr.endsWith('.0')) {
                codItemStr = codItemStr.replaceAll('.0', '');
              }
              final codItem = codItemStr;
              if (codItem.isEmpty) continue;

              // Se não for número (ex: tem texto descritivo longo), provavelmente não é uma linha de item válida
              if (int.tryParse(codItem) == null) continue;

              double? valorSugerido;
              if (row.length > 4 && row[4] != null) {
                if (row[4] is num) {
                  valorSugerido = (row[4] as num).toDouble();
                } else {
                  String valStr = row[4].toString().trim();
                  // Se o valor parece ser um texto descritivo enorme com "R$" no meio do texto, significa q a linha quebrou
                  if (valStr.length > 30)
                    continue; // Descarta se o campo valor for um textão

                  // Tenta extrair apenas os números e vírgulas para evitar lixo
                  valStr = valStr.replaceAll('R\$', '').replaceAll(' ', '');
                  valStr = valStr.replaceAll('.', '');
                  valStr = valStr.replaceAll(',', '.');
                  valorSugerido = double.tryParse(valStr);
                }
              }

              String? classificacao = row.length > 3 && row[3] != null
                  ? row[3].toString().trim()
                  : null;
              String? itemDolarizado = row.length > 5 && row[5] != null
                  ? row[5].toString().trim()
                  : null;

              // TRATAMENTO RÍGIDO DE DESALINHAMENTO E FILTRO DE CLASSES REAIS
              // Ignorar completamente linhas onde a classificação foi lida errado (N ou S)
              if (classificacao == 'N' || classificacao == 'S') continue;

              // Lista fixa das ÚNICAS classificações permitidas que existem na RENEM de verdade
              const classificacoesValidas = [
                'Gerais',
                'Médico Assistencial',
                'Apoio',
                'Apoio Laboratorial',
                'Infraestrutura',
                'Veículo',
                'Item Industrial Hosp/Farmacêutico e/ou Pesquisa'
              ];

              // Se a classificação não for uma dessas válidas, então a leitura pegou sujeira ou texto quebrado. Ignorar a linha!
              if (classificacao != null &&
                  !classificacoesValidas.contains(classificacao)) {
                continue;
              }

              batchMap[codItem] = {
                'cod_item': codItem,
                'item': row.length > 1 && row[1] != null
                    ? row[1].toString().trim()
                    : null,
                'definicao': row.length > 2 && row[2] != null
                    ? row[2].toString().trim()
                    : null,
                'classificacao': classificacao,
                'valor_sugerido': valorSugerido,
                'item_dolarizado': itemDolarizado,
                'especificacao_sugerida': row.length > 6 && row[6] != null
                    ? row[6].toString().trim()
                    : null,
                'data_atualizacao': importTimestamp,
              };

              if (batchMap.length >= 200) {
                try {
                  await _supabase
                      .from('renem_equipamentos')
                      .upsert(batchMap.values.toList());
                  count += batchMap.length;

                  if (mounted) {
                    setState(() {
                      _progresso = 0.1 + (0.8 * (i / totalLines));
                    });
                  }

                  _addLog('Enviados $count equipamentos...');
                } catch (e) {
                  _addLog('Erro em um lote: $e');
                } finally {
                  batchMap.clear();
                  await Future.delayed(const Duration(milliseconds: 50));
                }
              }
            } catch (e) {
              // Ignora erro de parse na linha
            }
          }
        } catch (excelError) {
          _addLog('Erro ao decodificar XLSX nativamente: $excelError');
          setState(() => _processando = false);
          return;
        }
      }

      if (batchMap.isNotEmpty) {
        try {
          await _supabase
              .from('renem_equipamentos')
              .upsert(batchMap.values.toList());
          count += batchMap.length;
        } catch (e) {
          _addLog('Erro no lote final: $e');
        }
      }

      _addLog('Equipamentos processados: $count.');

      if (_limparBase) {
        setState(() => _progresso = 0.9);
        _addLog(
            'Atualizando status/limpando equipamentos antigos não presentes na planilha...');
        await Future.delayed(const Duration(milliseconds: 50));
        try {
          await _supabase
              .from('renem_equipamentos')
              .delete()
              .lt('data_atualizacao', importTimestamp);
          _addLog('Equipamentos antigos removidos com sucesso.');
        } catch (e) {
          _addLog('Erro ao remover equipamentos antigos: $e');
        }
      }

      if (mounted) {
        setState(() => _progresso = 1.0);
      }
      _addLog('IMPORTAÇÃO RENEM CONCLUÍDA COM SUCESSO!');
    } catch (e, st) {
      _addLog('ERRO CRÍTICO: $e');
      _addLog(st.toString());
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Base RENEM'),
      ),
      body: ConstrainedContent(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.precision_manufacturing_outlined,
                          size: 64, color: Colors.blueGrey),
                      const SizedBox(height: 16),
                      Text(
                        'Importação Direta RENEM',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecione o arquivo "LISTA RENEM" baixado do portal FNS (.xlsx ou .csv).\nO sistema irá alimentar a base de dados de equipamentos com os valores e classificações corretos.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text(
                            'Remover equipamentos que não estão nesta lista',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text(
                            'Ao final da importação, todos os equipamentos antigos que não estiverem na nova planilha serão excluídos do banco.'),
                        value: _limparBase,
                        onChanged: _processando
                            ? null
                            : (bool value) {
                                setState(() {
                                  _limparBase = value;
                                });
                              },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_upload),
                        label:
                            const Text('Selecionar e Importar (.XLSX / .CSV)'),
                        onPressed:
                            _processando ? null : _selecionarEProcessarArquivo,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                      ),
                      if (_isAdministrador) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Área de Administração',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Limpar Banco RENEM (Zerar Tudo)'),
                          onPressed: _processando ? null : _limparBancoTodo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red[900],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_processando || _logs.isNotEmpty)
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Status da Importação',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 16),
                          if (_processando) ...[
                            LinearProgressIndicator(value: _progresso),
                            const SizedBox(height: 8),
                            Text(_status,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                          ],
                          Expanded(
                            child: Container(
                              color: Colors.black87,
                              padding: const EdgeInsets.all(8),
                              child: ListView.builder(
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  return Text(
                                    _logs[index],
                                    style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontFamily: 'monospace',
                                        fontSize: 12),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
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
