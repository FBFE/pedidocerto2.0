/// Registro do histórico de modificação de uma importação SGS (Indicasus).
class HistoricoIndicasusModel {
  HistoricoIndicasusModel({
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

  static HistoricoIndicasusModel fromJson(Map<String, dynamic> json) {
    final ocorridoEm = json['ocorrido_em'];
    return HistoricoIndicasusModel(
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

/// Importação de planilha Indicasus (.xls/.xlsx) para uma unidade.
/// Os dados são armazenados como lista de linhas (mapas coluna -> valor).
class IndicasusImportacaoModel {
  IndicasusImportacaoModel({
    this.id,
    required this.unidadeId,
    required this.anoReferencia,
    this.nomeUnidadePlanilha,
    required this.linhas,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String unidadeId;
  final int anoReferencia;
  final String? nomeUnidadePlanilha;

  /// Cada mapa representa uma linha: chaves são nomes/índices de coluna, valores são strings ou números.
  final List<Map<String, dynamic>> linhas;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'unidade_id': unidadeId,
        'ano_referencia': anoReferencia,
        'nome_unidade_planilha': nomeUnidadePlanilha,
        'dados_json': linhas,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  static IndicasusImportacaoModel fromJson(Map<String, dynamic> json) {
    final dados = json['dados_json'];
    List<Map<String, dynamic>> linhas = [];
    if (dados is List) {
      for (final e in dados) {
        if (e is Map) linhas.add(Map<String, dynamic>.from(e));
      }
    }
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    return IndicasusImportacaoModel(
      id: json['id'] as String?,
      unidadeId: json['unidade_id'] as String? ?? '',
      anoReferencia: json['ano_referencia'] as int? ?? 0,
      nomeUnidadePlanilha: json['nome_unidade_planilha'] as String?,
      linhas: linhas,
      createdAt:
          createdAt != null ? DateTime.tryParse(createdAt as String) : null,
      updatedAt:
          updatedAt != null ? DateTime.tryParse(updatedAt as String) : null,
    );
  }
}
