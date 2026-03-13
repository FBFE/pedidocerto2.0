class SecretariaAdjuntaModel {
  final String? id;
  final String secretariaId;
  final String nome;
  final String? sigla;
  final String? descricao;

  SecretariaAdjuntaModel({
    this.id,
    required this.secretariaId,
    required this.nome,
    this.sigla,
    this.descricao,
  });

  factory SecretariaAdjuntaModel.fromJson(Map<String, dynamic> json) {
    return SecretariaAdjuntaModel(
      id: json['id'] as String?,
      secretariaId: json['secretaria_id'] as String,
      nome: json['nome'] as String,
      sigla: json['sigla'] as String?,
      descricao: json['descricao'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'secretaria_id': secretariaId,
        'nome': nome,
        'sigla': sigla,
        'descricao': descricao,
      };
}
