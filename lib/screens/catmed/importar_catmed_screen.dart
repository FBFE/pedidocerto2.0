import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/constrained_content.dart';

class ImportarCatmedScreen extends StatefulWidget {
  const ImportarCatmedScreen({super.key});

  @override
  State<ImportarCatmedScreen> createState() => _ImportarCatmedScreenState();
}

class _ImportarCatmedScreenState extends State<ImportarCatmedScreen> {
  final _supabase = Supabase.instance.client;
  bool _processando = false;
  String _status = '';
  double _progresso = 0.0;

  final List<String> _logs = [];

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() {
      _logs.add(msg);
      _status = msg;
    });
  }

  Future<void> _selecionarEProcessarExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        _addLog('Erro: Não foi possível ler o arquivo.');
        return;
      }

      setState(() {
        _processando = true;
        _progresso = 0.05;
        _logs.clear();
      });

      _addLog('Decodificando arquivo Excel...');
      await Future.delayed(const Duration(milliseconds: 100));

      final excel = Excel.decodeBytes(bytes);
      final importTimestamp = DateTime.now().toIso8601String();

      // Assumimos que os dados estão na primeira planilha
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        _addLog('Erro: Planilha vazia ou não encontrada.');
        setState(() => _processando = false);
        return;
      }

      _addLog('Iniciando processamento das linhas...');
      await Future.delayed(const Duration(milliseconds: 100));

      // Ignorar cabeçalho (linha 0)
      final rows = sheet.rows.skip(1).toList();
      final totalRows = rows.length;

      Map<String, Map<String, dynamic>> batchMap = {};
      int count = 0;

      for (int i = 0; i < totalRows; i++) {
        final row = rows[i];
        if (row.isEmpty || row[0] == null) continue;

        try {
          // O CÓDIGO_SIAG geralmente é o primeiro item
          final codigoSiag = row[0]?.value?.toString().trim();
          if (codigoSiag == null || codigoSiag.isEmpty) continue;

          batchMap[codigoSiag] = {
            'codigo_siag': codigoSiag,
            'descritivo_tecnico': row.length > 1 ? row[1]?.value?.toString().trim() : null,
            'unidade': row.length > 2 ? row[2]?.value?.toString().trim() : null,
            'exemplos': row.length > 3 ? row[3]?.value?.toString().trim() : null,
            'embalagem': row.length > 4 ? row[4]?.value?.toString().trim() : null,
            'cap': row.length > 5 ? row[5]?.value?.toString().trim() : null,
            'tipo': row.length > 6 ? row[6]?.value?.toString().trim() : null,
            'cb': row.length > 7 ? row[7]?.value?.toString().trim() : null,
            'ce': row.length > 8 ? row[8]?.value?.toString().trim() : null,
            'pe': row.length > 9 ? row[9]?.value?.toString().trim() : null,
            'hosp': row.length > 10 ? row[10]?.value?.toString().trim() : null,
            'ex': row.length > 11 ? row[11]?.value?.toString().trim() : null,
            'codigo_atc': row.length > 12 ? row[12]?.value?.toString().trim() : null,
            'atc': row.length > 13 ? row[13]?.value?.toString().trim() : null,
            'obs': row.length > 14 ? row[14]?.value?.toString().trim() : null,
            'status': 'ativo',
            'data_atualizacao': importTimestamp,
          };

          if (batchMap.length >= 200) {
            try {
              await _supabase.from('catmed_medicamentos').upsert(batchMap.values.toList());
              count += batchMap.length;

              if (mounted) {
                setState(() {
                  _progresso = 0.1 + (0.7 * (i / totalRows));
                });
              }

              _addLog('Enviados $count medicamentos...');
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

      if (batchMap.isNotEmpty) {
        try {
          await _supabase.from('catmed_medicamentos').upsert(batchMap.values.toList());
          count += batchMap.length;
        } catch (e) {
          _addLog('Erro no lote final: $e');
        }
      }

      _addLog('Medicamentos processados: $count.');
      
      setState(() => _progresso = 0.9);
      _addLog('Atualizando status dos medicamentos não presentes na planilha para INATIVO...');
      await Future.delayed(const Duration(milliseconds: 50));

      try {
        await _supabase
            .from('catmed_medicamentos')
            .update({'status': 'inativo'})
            .lt('data_atualizacao', importTimestamp);
        
        _addLog('Inativação concluída com sucesso.');
      } catch (e) {
        _addLog('Erro ao inativar antigos: $e');
      }

      if (mounted) {
        setState(() => _progresso = 1.0);
      }
      _addLog('IMPORTAÇÃO CATMED CONCLUÍDA COM SUCESSO!');
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
        title: const Text('Importar Base CATMED'),
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
                      const Icon(Icons.file_upload_outlined,
                          size: 64, color: Colors.teal),
                      const SizedBox(height: 16),
                      Text(
                        'Importação Direta CATMED (Arquivo .XLSX)',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecione o arquivo "CATMED - catálogo de medicamentos.xlsx".\nO sistema irá alimentar a base de dados, atualizando os existentes e inativando os que foram removidos do catálogo.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Selecionar e Importar .XLSX'),
                        onPressed:
                            _processando ? null : _selecionarEProcessarExcel,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                      ),
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
