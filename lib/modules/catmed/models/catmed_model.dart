class CatmedModel {
  final String codigoSiag;
  final String? descritivoTecnico;
  final String? unidade;
  final String? exemplos;
  final String? embalagem;
  final String? cap;
  final String? tipo;
  final String? cb;
  final String? ce;
  final String? pe;
  final String? hosp;
  final String? ex;
  final String? codigoAtc;
  final String? atc;
  final String? obs;
  final String status;
  final DateTime? dataAtualizacao;

  CatmedModel({
    required this.codigoSiag,
    this.descritivoTecnico,
    this.unidade,
    this.exemplos,
    this.embalagem,
    this.cap,
    this.tipo,
    this.cb,
    this.ce,
    this.pe,
    this.hosp,
    this.ex,
    this.codigoAtc,
    this.atc,
    this.obs,
    this.status = 'ativo',
    this.dataAtualizacao,
  });

  factory CatmedModel.fromJson(Map<String, dynamic> json) {
    return CatmedModel(
      codigoSiag: json['codigo_siag'],
      descritivoTecnico: json['descritivo_tecnico'],
      unidade: json['unidade'],
      exemplos: json['exemplos'],
      embalagem: json['embalagem'],
      cap: json['cap'],
      tipo: json['tipo'],
      cb: json['cb'],
      ce: json['ce'],
      pe: json['pe'],
      hosp: json['hosp'],
      ex: json['ex'],
      codigoAtc: json['codigo_atc'],
      atc: json['atc'],
      obs: json['obs'],
      status: json['status'] ?? 'ativo',
      dataAtualizacao: json['data_atualizacao'] != null
          ? DateTime.parse(json['data_atualizacao'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo_siag': codigoSiag,
      'descritivo_tecnico': descritivoTecnico,
      'unidade': unidade,
      'exemplos': exemplos,
      'embalagem': embalagem,
      'cap': cap,
      'tipo': tipo,
      'cb': cb,
      'ce': ce,
      'pe': pe,
      'hosp': hosp,
      'ex': ex,
      'codigo_atc': codigoAtc,
      'atc': atc,
      'obs': obs,
      'status': status,
      if (dataAtualizacao != null)
        'data_atualizacao': dataAtualizacao!.toIso8601String(),
    };
  }
}
