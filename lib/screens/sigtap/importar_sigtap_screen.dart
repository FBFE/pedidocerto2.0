import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/constrained_content.dart';

class ImportarSigtapScreen extends StatefulWidget {
  const ImportarSigtapScreen({super.key});

  @override
  State<ImportarSigtapScreen> createState() => _ImportarSigtapScreenState();
}

class _ImportarSigtapScreenState extends State<ImportarSigtapScreen> {
  final _supabase = Supabase.instance.client;
  bool _processando = false;
  String _status = '';
  double _progresso = 0.0;

  final List<String> _logs = [];

  void _addLog(String msg) {
    setState(() {
      _logs.add(msg);
      _status = msg;
    });
  }

  Future<void> _selecionarEProcessarZip() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
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
        _progresso = 0.1;
        _logs.clear();
      });

      _addLog('Descompactando arquivo ZIP...');
      // Pequeno delay para a UI atualizar
      await Future.delayed(const Duration(milliseconds: 100));

      final archive = ZipDecoder().decodeBytes(bytes);

      _addLog('Arquivo descompactado. Procurando tabelas...');

      // Procurar os arquivos necessários
      ArchiveFile? tbProcedimento;
      ArchiveFile? tbGrupo;
      ArchiveFile? tbSubGrupo;
      ArchiveFile? tbFormaOrganizacao;
      ArchiveFile? rlCompativel;
      ArchiveFile? tbDescricao;

      for (var file in archive) {
        if (file.isFile) {
          final name = file.name.toLowerCase();
          if (name.endsWith('tb_procedimento.txt')) tbProcedimento = file;
          if (name.endsWith('tb_grupo.txt')) tbGrupo = file;
          if (name.endsWith('tb_sub_grupo.txt')) tbSubGrupo = file;
          if (name.endsWith('tb_forma_organizacao.txt')) {
            tbFormaOrganizacao = file;
          }
          if (name.endsWith('rl_procedimento_compativel.txt')) {
            rlCompativel = file;
          }
          if (name.endsWith('tb_descricao.txt')) tbDescricao = file;
        }
      }

      // Inicia direto de onde falta se quiser retomar, mas como Upsert é seguro,
      // podemos passar por todos. Para evitar travamento, vamos usar await Future.delayed
      // e atualizar a UI gradativamente.

      if (tbProcedimento != null) {
        await _processarProcedimentos(tbProcedimento);
      } else {
        _addLog('AVISO: tb_procedimento.txt não encontrado no ZIP.');
      }
      if (!mounted) return;
      setState(() => _progresso = 0.2);

      if (tbDescricao != null) {
        await _processarDescricoes(tbDescricao);
      } else {
        _addLog('AVISO: tb_descricao.txt não encontrado no ZIP.');
      }
      if (!mounted) return;
      setState(() => _progresso = 0.4);

      if (tbGrupo != null) {
        await _processarGrupos(tbGrupo);
      } else {
        _addLog('AVISO: tb_grupo.txt não encontrado no ZIP.');
      }
      if (!mounted) return;
      setState(() => _progresso = 0.5);

      if (tbSubGrupo != null) {
        await _processarSubGrupos(tbSubGrupo);
      } else {
        _addLog('AVISO: tb_sub_grupo.txt não encontrado no ZIP.');
      }
      if (!mounted) return;
      setState(() => _progresso = 0.7);

      if (tbFormaOrganizacao != null) {
        await _processarFormaOrganizacao(tbFormaOrganizacao);
      } else {
        _addLog('AVISO: tb_forma_organizacao.txt não encontrado no ZIP.');
      }
      if (!mounted) return;
      setState(() => _progresso = 0.85);

      if (rlCompativel != null) {
        await _processarCompativeis(rlCompativel);
      } else {
        _addLog('AVISO: rl_procedimento_compativel.txt não encontrado no ZIP.');
      }
      if (!mounted) return;
      setState(() => _progresso = 1.0);

      _addLog('IMPORTAÇÃO CONCLUÍDA COM SUCESSO!');
    } catch (e, st) {
      _addLog('ERRO CRÍTICO: $e');
      _addLog(st.toString());
    } finally {
      setState(() {
        _processando = false;
      });
    }
  }

  List<String> _getLines(ArchiveFile file) {
    final bytes = file.content as List<int>;
    final text = latin1.decode(bytes);
    return text.split('\n');
  }

  Future<void> _processarProcedimentos(ArchiveFile file) async {
    _addLog('Lendo tb_procedimento.txt...');
    await Future.delayed(const Duration(milliseconds: 50));

    final lines = _getLines(file);
    Map<String, Map<String, dynamic>> batchMap = {};
    int count = 0;
    int totalLines = lines.length;

    for (int i = 0; i < totalLines; i++) {
      String line = lines[i];
      if (line.trim().isEmpty) continue;

      try {
        final coProcedimento = line.substring(0, 10).trim();
        final noProcedimento = line.substring(10, 260).trim();
        final tpComplexidade = line.substring(260, 261).trim();
        final tpSexo = line.substring(261, 262).trim();
        final qtMaximaExecucao =
            int.tryParse(line.substring(262, 266).trim()) ?? 0;
        final qtDiasPermanencia =
            int.tryParse(line.substring(266, 270).trim()) ?? 0;
        final qtPontos = int.tryParse(line.substring(270, 274).trim()) ?? 0;
        final vlIdadeMinima =
            int.tryParse(line.substring(274, 278).trim()) ?? 0;
        final vlIdadeMaxima =
            int.tryParse(line.substring(278, 282).trim()) ?? 0;
        final vlSh =
            (double.tryParse(line.substring(282, 294).trim()) ?? 0.0) / 100;
        final vlSa =
            (double.tryParse(line.substring(294, 306).trim()) ?? 0.0) / 100;
        final vlSp =
            (double.tryParse(line.substring(306, 318).trim()) ?? 0.0) / 100;
        final coFinanciamento = line.substring(318, 320).trim();
        final coRubrica = line.substring(320, 326).trim();
        final qtTempoPermanencia =
            int.tryParse(line.substring(326, 330).trim()) ?? 0;
        final dtCompetencia = line.substring(330, 336).trim();

        batchMap[coProcedimento] = {
          'co_procedimento': coProcedimento,
          'no_procedimento': noProcedimento,
          'tp_complexidade': tpComplexidade,
          'tp_sexo': tpSexo,
          'qt_maxima_execucao': qtMaximaExecucao,
          'qt_dias_permanencia': qtDiasPermanencia,
          'qt_pontos': qtPontos,
          'vl_idade_minima': vlIdadeMinima,
          'vl_idade_maxima': vlIdadeMaxima,
          'vl_sh': vlSh,
          'vl_sa': vlSa,
          'vl_sp': vlSp,
          'co_financiamento': coFinanciamento,
          'co_rubrica': coRubrica,
          'qt_tempo_permanencia': qtTempoPermanencia,
          'dt_competencia': dtCompetencia,
        };

        if (batchMap.length >= 500) {
          try {
            await _supabase
                .from('procedimentos_sigtap')
                .upsert(batchMap.values.toList());
            count += batchMap.length;

            if (mounted) {
              setState(() {
                _progresso = 0.1 + (0.2 * (i / totalLines));
              });
            }

            _addLog('Enviados $count procedimentos...');
          } catch (e) {
            _addLog('Erro no lote de procedimentos: $e');
          } finally {
            batchMap.clear();
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      } catch (e) {
        // ignora linha mal formatada
      }
    }

    if (batchMap.isNotEmpty) {
      try {
        await _supabase
            .from('procedimentos_sigtap')
            .upsert(batchMap.values.toList());
        count += batchMap.length;
      } catch (e) {
        _addLog('Erro no lote final de procedimentos: $e');
      }
    }
    _addLog('Procedimentos finalizados: $count inseridos/atualizados.');
  }

  Future<void> _processarDescricoes(ArchiveFile file) async {
    _addLog('Lendo tb_descricao.txt...');
    await Future.delayed(const Duration(milliseconds: 50));
    final lines = _getLines(file);
    Map<String, Map<String, dynamic>> batchMap = {};
    int count = 0;
    int totalLines = lines.length;

    for (int i = 0; i < totalLines; i++) {
      String line = lines[i];
      if (line.trim().isEmpty) continue;

      try {
        final coProcedimento = line.substring(0, 10).trim();
        batchMap[coProcedimento] = {
          'co_procedimento': coProcedimento,
          'ds_procedimento': line.substring(10, 4010).trim(),
          'dt_competencia': line.substring(4010, 4016).trim(),
        };

        if (batchMap.length >= 200) {
          // Lotes menores pq descrição é texto grande
          try {
            await _supabase
                .from('sigtap_descricao')
                .upsert(batchMap.values.toList());
            count += batchMap.length;
            if (mounted) {
              setState(() {
                _progresso =
                    0.5 + (0.15 * (i / totalLines)); // Atualiza barra visual
              });
            }
          } catch (e) {
            _addLog('Erro no lote de descrições: $e');
          } finally {
            batchMap.clear();
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      } catch (e) {
        // ignora erro de parse na linha
      }
    }

    if (batchMap.isNotEmpty) {
      try {
        await _supabase
            .from('sigtap_descricao')
            .upsert(batchMap.values.toList());
        count += batchMap.length;
      } catch (e) {
        _addLog('Erro final descrições: $e');
      }
    }
    _addLog('Descrições inseridas: $count');
  }

  Future<void> _processarGrupos(ArchiveFile file) async {
    _addLog('Lendo tb_grupo.txt...');
    await Future.delayed(const Duration(milliseconds: 50));
    final lines = _getLines(file);
    Map<String, Map<String, dynamic>> batchMap = {};

    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final coGrupo = line.substring(0, 2).trim();
        batchMap[coGrupo] = {
          'co_grupo': coGrupo,
          'no_grupo': line.substring(2, 102).trim(),
          'dt_competencia': line.substring(102, 108).trim(),
        };
      } catch (e) {
        // ignora erro de parse na linha
      }
    }
    if (batchMap.isNotEmpty) {
      try {
        await _supabase.from('sigtap_grupo').upsert(batchMap.values.toList());
        _addLog('Grupos inseridos: ${batchMap.length}');
      } catch (e) {
        _addLog('Erro ao inserir grupos: $e');
      }
    }
  }

  Future<void> _processarSubGrupos(ArchiveFile file) async {
    _addLog('Lendo tb_sub_grupo.txt...');
    await Future.delayed(const Duration(milliseconds: 50));
    final lines = _getLines(file);
    Map<String, Map<String, dynamic>> batchMap = {};
    int count = 0;

    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final coGrupo = line.substring(0, 2).trim();
        final coSubGrupo = line.substring(2, 4).trim();
        final key = '${coGrupo}_$coSubGrupo';

        batchMap[key] = {
          'co_grupo': coGrupo,
          'co_sub_grupo': coSubGrupo,
          'no_sub_grupo': line.substring(4, 104).trim(),
          'dt_competencia': line.substring(104, 110).trim(),
        };
        if (batchMap.length >= 500) {
          try {
            await _supabase.from('sigtap_sub_grupo').upsert(
                batchMap.values.toList(),
                onConflict: 'co_grupo, co_sub_grupo');
            count += batchMap.length;
          } catch (e) {
            _addLog('Erro no lote de subgrupos: $e');
          } finally {
            batchMap.clear();
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      } catch (e) {
        // ignora erro de parse na linha
      }
    }
    if (batchMap.isNotEmpty) {
      try {
        await _supabase.from('sigtap_sub_grupo').upsert(
            batchMap.values.toList(),
            onConflict: 'co_grupo, co_sub_grupo');
        count += batchMap.length;
      } catch (e) {
        _addLog('Erro final subgrupos: $e');
      }
    }
    _addLog('Sub-grupos inseridos: $count');
  }

  Future<void> _processarFormaOrganizacao(ArchiveFile file) async {
    _addLog('Lendo tb_forma_organizacao.txt...');
    await Future.delayed(const Duration(milliseconds: 50));
    final lines = _getLines(file);
    Map<String, Map<String, dynamic>> batchMap = {};
    int count = 0;

    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final coGrupo = line.substring(0, 2).trim();
        final coSubGrupo = line.substring(2, 4).trim();
        final coForma = line.substring(4, 6).trim();
        final key = '${coGrupo}_${coSubGrupo}_$coForma';

        batchMap[key] = {
          'co_grupo': coGrupo,
          'co_sub_grupo': coSubGrupo,
          'co_forma_organizacao': coForma,
          'no_forma_organizacao': line.substring(6, 106).trim(),
          'dt_competencia': line.substring(106, 112).trim(),
        };
        if (batchMap.length >= 500) {
          try {
            await _supabase.from('sigtap_forma_organizacao').upsert(
                batchMap.values.toList(),
                onConflict: 'co_grupo, co_sub_grupo, co_forma_organizacao');
            count += batchMap.length;
          } catch (e) {
            _addLog('Erro no lote forma org: $e');
          } finally {
            batchMap.clear();
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      } catch (e) {
        // ignora erro de parse na linha
      }
    }
    if (batchMap.isNotEmpty) {
      try {
        await _supabase.from('sigtap_forma_organizacao').upsert(
            batchMap.values.toList(),
            onConflict: 'co_grupo, co_sub_grupo, co_forma_organizacao');
        count += batchMap.length;
      } catch (e) {
        _addLog('Erro final forma org: $e');
      }
    }
    _addLog('Formas de organização inseridas: $count');
  }

  Future<void> _processarCompativeis(ArchiveFile file) async {
    _addLog('Lendo rl_procedimento_compativel.txt...');
    await Future.delayed(const Duration(milliseconds: 50));
    final lines = _getLines(file);

    // Usar um Map para o lote garante que não enviaremos chaves duplicadas no mesmo lote
    Map<String, Map<String, dynamic>> batchMap = {};
    int count = 0;
    int totalLines = lines.length;

    // Processar em lotes menores e com pequenos atrasos para não travar a UI/Navegador
    for (int i = 0; i < totalLines; i++) {
      String line = lines[i];
      if (line.trim().isEmpty) continue;

      try {
        final principal = line.substring(0, 10).trim();
        final compativel = line.substring(12, 22).trim();
        final key = '${principal}_$compativel';

        batchMap[key] = {
          'co_procedimento_principal': principal,
          'co_registro_principal': line.substring(10, 12).trim(),
          'co_procedimento_compativel': compativel,
          'co_registro_compativel': line.substring(22, 24).trim(),
          'tp_compatibilidade': line.substring(24, 25).trim(),
          'qt_permitida': int.tryParse(line.substring(25, 29).trim()) ?? 0,
          'dt_competencia': line.substring(29, 35).trim(),
        };

        // Lote de 500 para evitar timeout
        if (batchMap.length >= 500) {
          try {
            await _supabase.from('sigtap_procedimento_compativel').upsert(
                  batchMap.values.toList(),
                  onConflict:
                      'co_procedimento_principal, co_procedimento_compativel',
                );
            count += batchMap.length;

            if (mounted) {
              setState(() {
                _progresso = 0.85 + (0.15 * (i / totalLines));
              });
            }

            _addLog('Enviados $count compatíveis...');
          } catch (e) {
            _addLog('Erro em um lote de compatíveis (ignorado): $e');
          } finally {
            batchMap.clear();
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      } catch (e) {
        // ignora erro de parse na linha
      }
    }

    if (batchMap.isNotEmpty) {
      try {
        await _supabase.from('sigtap_procedimento_compativel').upsert(
              batchMap.values.toList(),
              onConflict:
                  'co_procedimento_principal, co_procedimento_compativel',
            );
        count += batchMap.length;
      } catch (e) {
        _addLog('Erro no lote final de compatíveis: $e');
      }
    }
    _addLog('Compatíveis finalizados: $count inseridos/atualizados.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Base SIGTAP'),
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
                      const Icon(Icons.drive_folder_upload,
                          size: 64, color: Colors.blueGrey),
                      const SizedBox(height: 16),
                      Text(
                        'Importação Direta da SIGTAP (Arquivo .ZIP)',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecione o arquivo "TabelaUnificada_XXXXXX.zip" baixado do Datasus.\nO sistema irá extrair e alimentar a base de dados automaticamente, ignorando duplicidades (via Upsert).',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Selecionar e Importar .ZIP'),
                        onPressed:
                            _processando ? null : _selecionarEProcessarZip,
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
