// ignore_for_file: avoid_print, empty_catches
import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  // Configuração do Supabase (mesmas chaves do app)
  const supabaseUrl = 'https://bwdyzdhguwknbcagdado.supabase.co';
  const supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3ZHl6ZGhndXdrbmJjYWdkYWRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMjc4MTIsImV4cCI6MjA4NzcwMzgxMn0.K8r2jN4b9AH6fev9zUfQ5yJa7hb42MvepC78dPAkXtw';

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  // Caminho do arquivo
  const filePath =
      r'c:\Users\fabianoeugenio\Downloads\TabelaUnificada\tb_procedimento.txt';
  final file = File(filePath);

  if (!await file.exists()) {
    print('Arquivo não encontrado: $filePath');
    return;
  }

  print('Lendo arquivo...');
  // O arquivo provavelmente está em ISO-8859-1. Vamos usar Latin1
  final lines = await file.readAsLines(encoding: latin1);
  print('Total de linhas: ${lines.length}');

  List<Map<String, dynamic>> batch = [];
  int count = 0;
  const int batchSize = 1000;

  for (String line in lines) {
    if (line.trim().isEmpty) continue;

    // Lendo as posições baseadas no layout (baseadas em 1 para 0-index)
    // CO_PROCEDIMENTO,10,1,10,VARCHAR2
    // NO_PROCEDIMENTO,250,11,260,VARCHAR2
    // TP_COMPLEXIDADE,1,261,261,VARCHAR2
    // TP_SEXO,1,262,262,VARCHAR2
    // QT_MAXIMA_EXECUCAO,4,263,266,NUMBER
    // QT_DIAS_PERMANENCIA,4,267,270,NUMBER
    // QT_PONTOS,4,271,274,NUMBER
    // VL_IDADE_MINIMA,4,275,278,NUMBER
    // VL_IDADE_MAXIMA,4,279,282,NUMBER
    // VL_SH,12,283,294,NUMBER
    // VL_SA,12,295,306,NUMBER
    // VL_SP,12,307,318,NUMBER
    // CO_FINANCIAMENTO,2,319,320,VARCHAR2
    // CO_RUBRICA,6,321,326,VARCHAR2
    // QT_TEMPO_PERMANENCIA,4,327,330,NUMBER
    // DT_COMPETENCIA,6,331,336,CHAR

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
      final vlIdadeMinima = int.tryParse(line.substring(274, 278).trim()) ?? 0;
      final vlIdadeMaxima = int.tryParse(line.substring(278, 282).trim()) ?? 0;

      // Valores monetários costumam vir em centavos ou decimais (ex: 000000000000). Vamos deixar numérico direto
      final vlSh = double.tryParse(line.substring(282, 294).trim()) ?? 0.0;
      final vlSa = double.tryParse(line.substring(294, 306).trim()) ?? 0.0;
      final vlSp = double.tryParse(line.substring(306, 318).trim()) ?? 0.0;

      final coFinanciamento = line.substring(318, 320).trim();
      final coRubrica = line.substring(320, 326).trim();
      final qtTempoPermanencia =
          int.tryParse(line.substring(326, 330).trim()) ?? 0;
      final dtCompetencia = line.substring(330, 336).trim();

      batch.add({
        'co_procedimento': coProcedimento,
        'no_procedimento': noProcedimento,
        'tp_complexidade': tpComplexidade,
        'tp_sexo': tpSexo,
        'qt_maxima_execucao': qtMaximaExecucao,
        'qt_dias_permanencia': qtDiasPermanencia,
        'qt_pontos': qtPontos,
        'vl_idade_minima': vlIdadeMinima,
        'vl_idade_maxima': vlIdadeMaxima,
        // Convertendo para reais assumindo que os últimos 2 dígitos são decimais,
        // mas vamos manter o original ou dividir por 100 dependendo de como for lido.
        // Pela documentação, geralmente é em formato 000000000000 (sem ponto).
        'vl_sh': vlSh / 100,
        'vl_sa': vlSa / 100,
        'vl_sp': vlSp / 100,
        'co_financiamento': coFinanciamento,
        'co_rubrica': coRubrica,
        'qt_tempo_permanencia': qtTempoPermanencia,
        'dt_competencia': dtCompetencia,
      });

      if (batch.length >= batchSize) {
        await supabase.from('procedimentos_sigtap').upsert(batch);
        count += batch.length;
        print('Inseridos $count registros...');
        batch.clear();
      }
    } catch (e) {
      print('Erro ao processar linha: $e');
    }
  }

  if (batch.isNotEmpty) {
    await supabase.from('procedimentos_sigtap').upsert(batch);
    count += batch.length;
  }

  print('Processo concluído! Total de registros inseridos/atualizados: $count');
  exit(0);
}
