class GovernoModel {
  final String? id;
  final String nome;
  final String? sigla;
  final String? logoUrl;

  GovernoModel({
    this.id,
    required this.nome,
    this.sigla,
    this.logoUrl,
  });

  factory GovernoModel.fromJson(Map<String, dynamic> json) {
    return GovernoModel(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      sigla: json['sigla'] as String?,
      logoUrl: json['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nome': nome,
        'sigla': sigla,
        'logo_url': logoUrl,
      };
}
