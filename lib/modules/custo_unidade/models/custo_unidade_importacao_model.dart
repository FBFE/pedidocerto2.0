/// Uma linha do relatório de custo (item + valores mensais).
class LinhaCustoModel {
  LinhaCustoModel({
    required this.itemCusto,
    required this.valoresMensais,
  });

  final String itemCusto;

  /// Chaves: jan, fev, mar, abr, mai, jun, jul, ago, set, out, nov, dez
  final Map<String, double> valoresMensais;

  double get total => valoresMensais.values.fold(0.0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
        'itemCusto': itemCusto,
        'valoresMensais': valoresMensais,
      };

  static LinhaCustoModel fromJson(Map<String, dynamic> json) {
    final Map<String, double> vals = {};
    final v = json['valoresMensais'];
    if (v is Map) {
      for (final e in v.entries) {
        final n = e.value;
        vals[e.key as String] =
            n is num ? n.toDouble() : double.tryParse('$n') ?? 0;
      }
    }
    return LinhaCustoModel(
      itemCusto: json['itemCusto'] as String? ?? '',
      valoresMensais: vals,
    );
  }
}

/// Registro do histórico de modificação de uma importação.
class HistoricoImportacaoModel {
  HistoricoImportacaoModel({
    this.id,
    required this.importacaoId,
    required this.ocorridoEm,
    required this.tipo,
    this.descricao,
    this.usuarioEmail,
  });

  final String? id;
  final String importacaoId;
  final DateTime ocorridoEm;
  final String tipo; // 'criacao', 'edicao', 'reimportacao'
  final String? descricao;
  final String? usuarioEmail;

  static HistoricoImportacaoModel fromJson(Map<String, dynamic> json) {
    final ocorridoEm = json['ocorrido_em'];
    return HistoricoImportacaoModel(
      id: json['id'] as String?,
      importacaoId: json['importacao_id'] as String? ?? '',
      ocorridoEm: ocorridoEm != null
          ? DateTime.tryParse(ocorridoEm as String) ?? DateTime.now()
          : DateTime.now(),
      tipo: json['tipo'] as String? ?? 'edicao',
      descricao: json['descricao'] as String?,
      usuarioEmail: json['usuario_email'] as String?,
    );
  }
}

/// Importação de um relatório de custo (CSV) para uma unidade.
class CustoUnidadeImportacaoModel {
  CustoUnidadeImportacaoModel({
    this.id,
    required this.unidadeId,
    required this.anoCompetencia,
    this.nomeUnidadePlanilha,
    required this.linhas,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String unidadeId;
  final int anoCompetencia;
  final String? nomeUnidadePlanilha;
  final List<LinhaCustoModel> linhas;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Categorias consideradas "resumo" (relatório sem custos detalhados).
  static const Set<String> itensResumido = {
    'Pessoal',
    'Material de Consumo',
    'Serviços de Terceiros',
    'Despesas Gerais',
    'TOTAL GERAL',
  };

  static String _normalizar(String s) {
    return s
        .trim()
        .replaceAll('η', 'ç')
        .replaceAll('α', 'á')
        .replaceAll('ι', 'í')
        .replaceAll('ν', 'ú')
        .replaceAll('σ', 'ó')
        .replaceAll('β', 'â')
        .replaceAll('ϊ', 'ã')
        .replaceAll('Σ', 'Ó');
  }

  /// Retorna apenas linhas do resumo: Pessoal, Material de Consumo, Serviços de Terceiros, Despesas Gerais, TOTAL GERAL.
  List<LinhaCustoModel> get linhasResumido {
    final setNorm = itensResumido.map(_normalizar).toSet();
    return linhas
        .where((l) => setNorm.contains(_normalizar(l.itemCusto)))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'unidade_id': unidadeId,
        'ano_competencia': anoCompetencia,
        'nome_unidade_planilha': nomeUnidadePlanilha,
        'dados_json': linhas.map((e) => e.toJson()).toList(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  static CustoUnidadeImportacaoModel fromJson(Map<String, dynamic> json) {
    final dados = json['dados_json'];
    List<LinhaCustoModel> linhas = [];
    if (dados is List) {
      for (final e in dados) {
        if (e is Map<String, dynamic>) linhas.add(LinhaCustoModel.fromJson(e));
      }
    }
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    return CustoUnidadeImportacaoModel(
      id: json['id'] as String?,
      unidadeId: json['unidade_id'] as String? ?? '',
      anoCompetencia: json['ano_competencia'] as int? ?? 0,
      nomeUnidadePlanilha: json['nome_unidade_planilha'] as String?,
      linhas: linhas,
      createdAt:
          createdAt != null ? DateTime.tryParse(createdAt as String) : null,
      updatedAt:
          updatedAt != null ? DateTime.tryParse(updatedAt as String) : null,
    );
  }
}
