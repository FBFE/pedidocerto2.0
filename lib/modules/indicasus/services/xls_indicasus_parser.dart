import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

/// Resultado do parse da planilha Indicasus (.xls/.xlsx).
/// Estrutura baseada em relatórios como "Relatorio - Alta Floresta 2018.xls".
class IndicasusParseResult {
  IndicasusParseResult({
    this.anoReferencia,
    this.nomeUnidade,
    required this.linhas,
  });

  final int? anoReferencia;
  final String? nomeUnidade;

  /// Cada mapa = uma linha; chaves = nomes das colunas (primeira linha da planilha), valores = celulas.
  final List<Map<String, dynamic>> linhas;
}

/// Parser para planilha Indicasus (formato Relatório - Alta Floresta / Indicasus).
/// Suporta .xlsx; para .xls antigo, salvar como .xlsx no Excel.
///
/// **Ano de competência:** identificado pela ordem: (1) cabeçalhos das colunas
/// (ex. "janeiro/2019", "fevereiro/2019" → 2019); (2) nome da aba; (3) primeira linha de dados.
/// Esse ano é o identificador único por unidade no SGS (sobrescreve só se mesmo ano).
class XlsIndicasusParser {
  XlsIndicasusParser._();

  static String _cellValue(dynamic cell) {
    if (cell == null) return '';
    if (cell is num) return cell.toString();
    return cell.toString().trim();
  }

  /// Tenta extrair ano de uma string (ex: "2018", "janeiro/2019", "Ano 2018").
  static int? _extrairAno(String s) {
    if (s.isEmpty) return null;
    final regex = RegExp(r'20\d{2}');
    final match = regex.firstMatch(s);
    if (match != null) {
      final ano = int.tryParse(match.group(0)!);
      if (ano != null && ano >= 2000 && ano <= 2100) return ano;
    }
    return null;
  }

  /// Anos encontrados nos cabeçalhos (ex.: "janeiro/2019" → 2019).
  static int? _anoDosCabecalhos(List<String> headerLabels) {
    final anos = <int>[];
    for (final label in headerLabels) {
      final a = _extrairAno(label);
      if (a != null) anos.add(a);
    }
    if (anos.isEmpty) return null;
    anos.sort();
    return anos.first;
  }

  /// Padrão para célula do tipo "mês/ano" (ex.: janeiro/2018, fevereiro/2018).
  static final _patternMesAno = RegExp(
    r'(janeiro|fevereiro|mar[cç]o|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s*/\s*(20\d{2})',
    caseSensitive: false,
  );

  /// Procura nas primeiras linhas da planilha a linha de períodos (janeiro/2018, fevereiro/2018, etc.).
  /// Esse é o ano de competência **do relatório**, não do título. Prioridade máxima.
  static int? _anoCompetenciaDoRelatorio(List<List<dynamic>> rows) {
    const maxLinhas = 10;
    for (var r = 0; r < rows.length && r < maxLinhas; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final cell = _cellValue(row[c]);
        final match = _patternMesAno.firstMatch(cell);
        if (match != null) {
          final ano = int.tryParse(match.group(2)!);
          if (ano != null && ano >= 2000 && ano <= 2100) return ano;
        }
      }
    }
    return null;
  }

  /// Parse dos bytes da planilha (.xlsx). Arquivos .xls (Excel 97-2003) não são
  /// suportados pelo pacote; o usuário deve abrir no Excel e salvar como .xlsx.
  /// Usa a primeira aba; primeira linha = cabeçalho; demais = dados.
  static IndicasusParseResult parse(List<int> bytes) {
    SpreadsheetDecoder decoder;
    try {
      decoder = SpreadsheetDecoder.decodeBytes(bytes);
    } on FormatException catch (e) {
      final msg = e.message;
      if (msg.contains('Central Directory') ||
          msg.toLowerCase().contains('zip') ||
          msg.toLowerCase().contains('invalid')) {
        throw const FormatException(
          'Este arquivo parece ser .xls (Excel 97-2003). '
          'O app só lê .xlsx. Abra a planilha no Excel e use "Salvar como" → "Pasta de trabalho do Excel (.xlsx)".',
        );
      }
      rethrow;
    }
    if (decoder.tables.isEmpty) {
      return IndicasusParseResult(linhas: []);
    }

    final tableName = decoder.tables.keys.first;
    final table = decoder.tables[tableName]!;
    final rows = table.rows;
    if (rows.isEmpty) {
      return IndicasusParseResult(linhas: []);
    }

    // Prioridade 1: ano de competência do relatório (linha com janeiro/2018, fevereiro/2018, etc.)
    int? anoReferencia = _anoCompetenciaDoRelatorio(rows);
    anoReferencia ??= _extrairAno(tableName);
    String? nomeUnidade;

    // Descobrir a linha de cabeçalho: preferir linha que tenha vários "mês/ano" (janeiro/2018, fevereiro/2018...)
    const maxLinhasBusca = 15;
    int headerRowIndex = 0;
    for (var r = 0; r < rows.length && r < maxLinhasBusca; r++) {
      final row = rows[r];
      var countMesAno = 0;
      for (var c = 0; c < row.length; c++) {
        if (_patternMesAno.hasMatch(_cellValue(row[c]))) countMesAno++;
      }
      if (countMesAno >= 3) {
        headerRowIndex = r;
        break;
      }
    }

    final headerRow = rows[headerRowIndex];
    final headers = <int, String>{};
    final headerLabels = <String>[];
    for (var c = 0; c < headerRow.length; c++) {
      final label = _cellValue(headerRow[c]);
      headerLabels.add(label);
      if (label.isEmpty) {
        headers[c] = 'Col_$c';
      } else {
        headers[c] = label;
      }
      if (anoReferencia == null) {
        final a = _extrairAno(label);
        if (a != null) anoReferencia = a;
      }
      if (nomeUnidade == null &&
          label.length > 3 &&
          !label.contains(RegExp(r'\d{4}'))) {
        nomeUnidade = label.isNotEmpty ? label : null;
      }
    }

    // Se ainda não achou, usar ano dos cabeçalhos (ex.: janeiro/2019)
    if (anoReferencia == null) {
      final anoCabecalho = _anoDosCabecalhos(headerLabels);
      if (anoCabecalho != null) anoReferencia = anoCabecalho;
    }

    // Se ainda não tem ano, procurar nas primeiras células da primeira linha de dados
    final firstDataRowIndex = headerRowIndex + 1;
    if (anoReferencia == null && rows.length > firstDataRowIndex) {
      final nextRow = rows[firstDataRowIndex];
      for (var c = 0; c < nextRow.length; c++) {
        final a = _extrairAno(_cellValue(nextRow[c]));
        if (a != null) {
          anoReferencia = a;
          break;
        }
      }
    }

    if (nomeUnidade == null && rows.isNotEmpty) {
      final firstCell = _cellValue(rows[0].isNotEmpty ? rows[0][0] : null);
      if (firstCell.isNotEmpty && firstCell.length < 200) {
        nomeUnidade = firstCell;
      }
    }

    final linhas = <Map<String, dynamic>>[];
    for (var r = firstDataRowIndex; r < rows.length; r++) {
      final row = rows[r];
      final map = <String, dynamic>{};
      for (var c = 0; c < row.length; c++) {
        final key = headers[c] ?? 'Col_$c';
        final value = row[c];
        if (value == null) {
          map[key] = '';
        } else if (value is num) {
          map[key] = value;
        } else {
          map[key] = value.toString().trim();
        }
      }
      linhas.add(map);
    }

    return IndicasusParseResult(
      anoReferencia: anoReferencia,
      nomeUnidade: nomeUnidade,
      linhas: linhas,
    );
  }
}
