class SecretariaModel {
  final String? id;
  final String? governoId;
  final String nome;
  final String? sigla;
  final String? descricao;

  SecretariaModel({
    this.id,
    this.governoId,
    required this.nome,
    this.sigla,
    this.descricao,
  });

  factory SecretariaModel.fromJson(Map<String, dynamic> json) {
    return SecretariaModel(
      id: json['id'] as String?,
      governoId: json['governo_id'] as String?,
      nome: json['nome'] as String,
      sigla: json['sigla'] as String?,
      descricao: json['descricao'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'governo_id': governoId,
        'nome': nome,
        'sigla': sigla,
        'descricao': descricao,
      };
}
