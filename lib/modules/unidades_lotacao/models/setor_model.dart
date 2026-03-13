class SetorModel {
  final String? id;
  final String nome;
  final String? sigla;
  final String? descricao;
  final String? secretariaAdjuntaId;
  final String? unidadeHospitalarId;

  SetorModel({
    this.id,
    required this.nome,
    this.sigla,
    this.descricao,
    this.secretariaAdjuntaId,
    this.unidadeHospitalarId,
  }) : assert(
          (secretariaAdjuntaId != null && unidadeHospitalarId == null) ||
              (secretariaAdjuntaId == null && unidadeHospitalarId != null),
          'Setor deve ser vinculado à Secretaria Adjunta OU à Unidade Hospitalar',
        );

  factory SetorModel.fromJson(Map<String, dynamic> json) {
    return SetorModel(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      sigla: json['sigla'] as String?,
      descricao: json['descricao'] as String?,
      secretariaAdjuntaId: json['secretaria_adjunta_id'] as String?,
      unidadeHospitalarId: json['unidade_hospitalar_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nome': nome,
        'sigla': sigla,
        'descricao': descricao,
        'secretaria_adjunta_id': secretariaAdjuntaId,
        'unidade_hospitalar_id': unidadeHospitalarId,
      };

  bool get vinculadoASecretariaAdjunta => secretariaAdjuntaId != null;
  bool get vinculadoAUnidadeHospitalar => unidadeHospitalarId != null;
}
