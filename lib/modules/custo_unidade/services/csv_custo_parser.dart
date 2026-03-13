import '../models/custo_unidade_importacao_model.dart';

/// Parser do CSV do Relatório Custo Total da Unidade (Apurasus).
/// Formato: separador ";", linha 1 = nome hospital, linha 2 = datas (01/01/YYYY;01/12/YYYY), linha 6 = header, depois linhas de dados.
class CsvCustoParser {
  CsvCustoParser._();

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

  /// Extrai o ano de competência da linha 2 (ex: "01/01/2025;01/12/2025" -> 2025).
  static int? extrairAnoCompetencia(List<String> linhas) {
    if (linhas.length < 2) return null;
    final linha2 = linhas[1].trim();
    final partes = linha2.split(';');
    if (partes.isEmpty) return null;
    final data = partes[0].trim(); // DD/MM/YYYY
    final d = data.split('/');
    if (d.length >= 3) {
      final ano = int.tryParse(d[2]);
      if (ano != null && ano >= 2000 && ano <= 2100) return ano;
    }
    return null;
  }

  /// Extrai o nome da unidade da primeira linha (antes do primeiro ";").
  static String? extrairNomeUnidade(List<String> linhas) {
    if (linhas.isEmpty) return null;
    final s = linhas[0].split(';').first.trim();
    return s.isEmpty ? null : s;
  }

  /// Converte valor brasileiro (1.234,56) para double.
  static double _parseValor(String s) {
    s = s.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
  }

  /// Parse do CSV completo. Retorna linhas de custo (item + 12 meses).
  /// Assume que a linha de header com "Item Custo" e jan/25 ... dez/25 existe.
  static List<LinhaCustoModel> parseLinhas(List<String> linhas) {
    List<LinhaCustoModel> resultado = [];
    int headerIndex = -1;
    for (int i = 0; i < linhas.length; i++) {
      final row = linhas[i];
      if (row.contains('Item Custo') && row.contains('jan')) {
        headerIndex = i;
        break;
      }
    }
    if (headerIndex < 0) return resultado;

    for (int i = headerIndex + 1; i < linhas.length; i++) {
      final cells = linhas[i].split(';');
      if (cells.length < 2) continue;
      final item = cells[0].trim();
      if (item.isEmpty) continue;

      final valores = <String, double>{};
      for (int m = 0; m < _meses.length && m + 1 < cells.length; m++) {
        valores[_meses[m]] = _parseValor(cells[m + 1]);
      }
      resultado.add(LinhaCustoModel(itemCusto: item, valoresMensais: valores));
    }
    return resultado;
  }

  /// Parse completo: ano, nome e linhas a partir do texto do CSV.
  static ({int? ano, String? nomeUnidade, List<LinhaCustoModel> linhas}) parse(
      String csvText) {
    final linhas = csvText
        .replaceAll('\r\n', '\n')
        .split('\n')
        .where((s) => s.isNotEmpty)
        .toList();
    final ano = extrairAnoCompetencia(linhas);
    final nome = extrairNomeUnidade(linhas);
    final linhasCusto = parseLinhas(linhas);
    return (ano: ano, nomeUnidade: nome, linhas: linhasCusto);
  }
}
