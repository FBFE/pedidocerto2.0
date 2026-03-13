/// Unidade de medida (sigla, nome, detalhes, categoria).
class UnidadeMedidaModel {
  final String? id;
  final String sigla;
  final String? nome;
  final String? detalhes;
  final String? categoria;
  final String? usuarioCadastrouNome;
  final String? usuarioCadastrouMatricula;
  final DateTime? dataHoraRegistro;
  final DateTime? createdAt;

  UnidadeMedidaModel({
    this.id,
    required this.sigla,
    this.nome,
    this.detalhes,
    this.categoria,
    this.usuarioCadastrouNome,
    this.usuarioCadastrouMatricula,
    this.dataHoraRegistro,
    this.createdAt,
  });

  factory UnidadeMedidaModel.fromJson(Map<String, dynamic> json) {
    return UnidadeMedidaModel(
      id: json['id'] as String?,
      sigla: json['sigla'] as String? ?? '',
      nome: json['nome'] as String?,
      detalhes: json['detalhes'] as String?,
      categoria: json['categoria'] as String?,
      usuarioCadastrouNome: json['usuario_cadastrou_nome'] as String?,
      usuarioCadastrouMatricula: json['usuario_cadastrou_matricula'] as String?,
      dataHoraRegistro: json['data_hora_registro'] != null ? DateTime.tryParse(json['data_hora_registro'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sigla': sigla.trim(),
      'nome': nome?.trim(),
      'detalhes': detalhes?.trim(),
      'categoria': categoria?.trim(),
      'usuario_cadastrou_nome': usuarioCadastrouNome,
      'usuario_cadastrou_matricula': usuarioCadastrouMatricula,
      'data_hora_registro': dataHoraRegistro?.toUtc().toIso8601String(),
    };
  }

  String get exibicao => nome != null && nome!.isNotEmpty ? '$sigla ($nome)' : sigla;
}
