/// Marca ou fabricante (banco único; auditoria de cadastro).
class MarcaFabricanteModel {
  final String? id;
  final String nome;
  final String? usuarioCadastrouNome;
  final String? usuarioCadastrouMatricula;
  final DateTime? dataHoraRegistro;
  final DateTime? createdAt;

  MarcaFabricanteModel({
    this.id,
    required this.nome,
    this.usuarioCadastrouNome,
    this.usuarioCadastrouMatricula,
    this.dataHoraRegistro,
    this.createdAt,
  });

  factory MarcaFabricanteModel.fromJson(Map<String, dynamic> json) {
    return MarcaFabricanteModel(
      id: json['id'] as String?,
      nome: json['nome'] as String? ?? '',
      usuarioCadastrouNome: json['usuario_cadastrou_nome'] as String?,
      usuarioCadastrouMatricula: json['usuario_cadastrou_matricula'] as String?,
      dataHoraRegistro: json['data_hora_registro'] != null ? DateTime.tryParse(json['data_hora_registro'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome.trim(),
      'usuario_cadastrou_nome': usuarioCadastrouNome,
      'usuario_cadastrou_matricula': usuarioCadastrouMatricula,
      'data_hora_registro': dataHoraRegistro?.toUtc().toIso8601String(),
    };
  }
}
