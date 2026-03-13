class UnidadeHospitalarModel {
  final String? id;
  final String secretariaId;
  final String? cnes;
  final String nome;
  final String? cnpj;
  final String? nomeEmpresarial;
  final String? naturezaJuridica;
  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? bairro;
  final String? municipio;
  final String? uf;
  final String? complemento;
  final String? classificacaoEstabelecimento;
  final String? gestao;
  final String? tipoEstrutura;
  final String? latitude;
  final String? longitude;
  final String? responsavelTecnico;
  final String? telefone;
  final String? email;
  final DateTime? cadastradoEm;
  final DateTime? atualizacaoBaseLocal;
  final DateTime? ultimaAtualizacaoNacional;
  final String? horarioFuncionamento;
  final DateTime? dataDesativacao;
  final String? motivoDesativacao;
  final String? logoUrl;
  final String? sigla;
  final String? descricao;

  UnidadeHospitalarModel({
    this.id,
    required this.secretariaId,
    this.cnes,
    required this.nome,
    this.cnpj,
    this.nomeEmpresarial,
    this.naturezaJuridica,
    this.cep,
    this.logradouro,
    this.numero,
    this.bairro,
    this.municipio,
    this.uf,
    this.complemento,
    this.classificacaoEstabelecimento,
    this.gestao,
    this.tipoEstrutura,
    this.latitude,
    this.longitude,
    this.responsavelTecnico,
    this.telefone,
    this.email,
    this.cadastradoEm,
    this.atualizacaoBaseLocal,
    this.ultimaAtualizacaoNacional,
    this.horarioFuncionamento,
    this.dataDesativacao,
    this.motivoDesativacao,
    this.logoUrl,
    this.sigla,
    this.descricao,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  factory UnidadeHospitalarModel.fromJson(Map<String, dynamic> json) {
    return UnidadeHospitalarModel(
      id: json['id'] as String?,
      secretariaId: json['secretaria_id'] as String,
      cnes: json['cnes'] as String?,
      nome: json['nome'] as String,
      cnpj: json['cnpj'] as String?,
      nomeEmpresarial: json['nome_empresarial'] as String?,
      naturezaJuridica: json['natureza_juridica'] as String?,
      cep: json['cep'] as String?,
      logradouro: json['logradouro'] as String?,
      numero: json['numero'] as String?,
      bairro: json['bairro'] as String?,
      municipio: json['municipio'] as String?,
      uf: json['uf'] as String?,
      complemento: json['complemento'] as String?,
      classificacaoEstabelecimento:
          json['classificacao_estabelecimento'] as String?,
      gestao: json['gestao'] as String?,
      tipoEstrutura: json['tipo_estrutura'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      responsavelTecnico: json['responsavel_tecnico'] as String?,
      telefone: json['telefone'] as String?,
      email: json['email'] as String?,
      cadastradoEm: _parseDate(json['cadastrado_em']),
      atualizacaoBaseLocal: _parseDate(json['atualizacao_base_local']),
      ultimaAtualizacaoNacional:
          _parseDate(json['ultima_atualizacao_nacional']),
      horarioFuncionamento: json['horario_funcionamento'] as String?,
      dataDesativacao: _parseDate(json['data_desativacao']),
      motivoDesativacao: json['motivo_desativacao'] as String?,
      logoUrl: json['logo_url'] as String?,
      sigla: json['sigla'] as String?,
      descricao: json['descricao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'secretaria_id': secretariaId,
      'cnes': cnes,
      'nome': nome,
      'cnpj': cnpj,
      'nome_empresarial': nomeEmpresarial,
      'natureza_juridica': naturezaJuridica,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'bairro': bairro,
      'municipio': municipio,
      'uf': uf,
      'complemento': complemento,
      'classificacao_estabelecimento': classificacaoEstabelecimento,
      'gestao': gestao,
      'tipo_estrutura': tipoEstrutura,
      'latitude': latitude,
      'longitude': longitude,
      'responsavel_tecnico': responsavelTecnico,
      'telefone': telefone,
      'email': email,
      'cadastrado_em': cadastradoEm?.toIso8601String().split('T')[0],
      'atualizacao_base_local':
          atualizacaoBaseLocal?.toIso8601String().split('T')[0],
      'ultima_atualizacao_nacional':
          ultimaAtualizacaoNacional?.toIso8601String().split('T')[0],
      'horario_funcionamento': horarioFuncionamento,
      'data_desativacao': dataDesativacao?.toIso8601String().split('T')[0],
      'motivo_desativacao': motivoDesativacao,
      'logo_url': logoUrl,
      'sigla': sigla,
      'descricao': descricao,
    };
  }
}
