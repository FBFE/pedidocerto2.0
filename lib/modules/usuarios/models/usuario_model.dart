class UsuarioModel {
  final String? id;
  final String nome;
  final DateTime? nascimento;
  final String? documento;
  final String? contato;
  final String? matricula;
  final DateTime? dataPosse;
  final String? regimeContrato;
  final String? dga;
  final DateTime? dataVencimentoContrato;
  final String? cargaHoraria;
  final String? escolaridade;
  final String? formacao;
  final String? email;
  final String? unidadeLotacao;
  final String? setorLotacao;
  final String? situacao;
  final String? cargo;

  /// Perfil no sistema: 'pendente_aprovacao' | 'usuario' | 'administrador'
  final String? perfilSistema;

  UsuarioModel({
    this.id,
    required this.nome,
    this.nascimento,
    this.documento,
    this.contato,
    this.matricula,
    this.dataPosse,
    this.regimeContrato,
    this.dga,
    this.dataVencimentoContrato,
    this.cargaHoraria,
    this.escolaridade,
    this.formacao,
    this.email,
    this.unidadeLotacao,
    this.setorLotacao,
    this.situacao,
    this.cargo,
    this.perfilSistema,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as String?,
      nome: json['nome'] as String,
      nascimento: json['nascimento'] != null
          ? DateTime.parse(json['nascimento'] as String)
          : null,
      documento: json['documento'] as String?,
      contato: json['contato'] as String?,
      matricula: json['matricula'] as String?,
      dataPosse: json['data_posse'] != null
          ? DateTime.parse(json['data_posse'] as String)
          : null,
      regimeContrato: json['regime_contrato'] as String?,
      dga: json['dga'] as String?,
      dataVencimentoContrato: json['data_vencimento_contrato'] != null
          ? DateTime.parse(json['data_vencimento_contrato'] as String)
          : null,
      cargaHoraria: json['carga_horaria'] as String?,
      escolaridade: json['escolaridade'] as String?,
      formacao: json['formacao'] as String?,
      email: json['email'] as String?,
      unidadeLotacao: json['unidade_lotacao'] as String?,
      setorLotacao: json['setor_lotacao'] as String?,
      situacao: json['situacao'] as String?,
      cargo: json['cargo'] as String?,
      perfilSistema: json['perfil_sistema'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'nascimento': nascimento?.toIso8601String().split('T')[0],
      'documento': documento,
      'contato': contato,
      'matricula': matricula,
      'data_posse': dataPosse?.toIso8601String().split('T')[0],
      'regime_contrato': regimeContrato,
      'dga': dga,
      'data_vencimento_contrato':
          dataVencimentoContrato?.toIso8601String().split('T')[0],
      'carga_horaria': cargaHoraria,
      'escolaridade': escolaridade,
      'formacao': formacao,
      'email': email,
      'unidade_lotacao': unidadeLotacao,
      'setor_lotacao': setorLotacao,
      'situacao': situacao ?? 'Ativo',
      'cargo': cargo,
      if (perfilSistema != null) 'perfil_sistema': perfilSistema,
    };
  }

  UsuarioModel copyWith({
    String? id,
    String? nome,
    DateTime? nascimento,
    String? documento,
    String? contato,
    String? matricula,
    DateTime? dataPosse,
    String? regimeContrato,
    String? dga,
    DateTime? dataVencimentoContrato,
    String? cargaHoraria,
    String? escolaridade,
    String? formacao,
    String? email,
    String? unidadeLotacao,
    String? setorLotacao,
    String? situacao,
    String? cargo,
    String? perfilSistema,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      nascimento: nascimento ?? this.nascimento,
      documento: documento ?? this.documento,
      contato: contato ?? this.contato,
      matricula: matricula ?? this.matricula,
      dataPosse: dataPosse ?? this.dataPosse,
      regimeContrato: regimeContrato ?? this.regimeContrato,
      dga: dga ?? this.dga,
      dataVencimentoContrato:
          dataVencimentoContrato ?? this.dataVencimentoContrato,
      cargaHoraria: cargaHoraria ?? this.cargaHoraria,
      escolaridade: escolaridade ?? this.escolaridade,
      formacao: formacao ?? this.formacao,
      email: email ?? this.email,
      unidadeLotacao: unidadeLotacao ?? this.unidadeLotacao,
      setorLotacao: setorLotacao ?? this.setorLotacao,
      situacao: situacao ?? this.situacao,
      cargo: cargo ?? this.cargo,
      perfilSistema: perfilSistema ?? this.perfilSistema,
    );
  }

  bool get isPendenteAprovacao => perfilSistema == 'pendente_aprovacao';
  bool get isAdministrador => perfilSistema == 'administrador';
}
