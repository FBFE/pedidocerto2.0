class DfdModel {
  final String? id;
  final DateTime? createdAt;

  // 1. Identificação
  final String orgao;
  final String unidadeOrcamentaria;
  final String setorRequisitante;
  final String responsavelDemanda;
  final String matricula;
  final String email;
  final String telefone;

  // 2. Objeto
  final String classificacaoObjeto;
  final String descricaoDemanda;

  // 3. Forma de Contratação e Planejamento
  final String formaContratacaoSugerida;
  final String? numeroArp;
  final String? editalArp;
  final DateTime? dataPublicacaoArp;
  final DateTime? dataVigenciaArp;
  final bool necessidadeEtp;
  final bool? etpRetiradoManualmente;
  final String? etpNumero;
  final String? etpFileUrl;

  // 4. Justificativa e Previsão Orçamentária
  final String justificativaNecessidade;
  final String demonstracaoPrevisaoPac;
  final String recursosOrcamentarios;
  final DateTime? dataPretendidaContratacao;
  final String grauPrioridade;
  final String correlacaoPlanejamento;

  // 5. Equipe de Planejamento
  final String integranteRequisitanteNome;
  final String integranteRequisitanteMatricula;
  final String integranteRequisitanteLotacao;
  final String? integranteTecnico1Nome;
  final String? integranteTecnico1Matricula;
  final String? integranteTecnico1Lotacao;
  final String? integranteTecnico2Nome;
  final String? integranteTecnico2Matricula;
  final String? integranteTecnico2Lotacao;

  // 6. Matriz de Priorização GUT
  final String matrizItem;
  final int matrizG;
  final int matrizU;
  final int matrizT;

  // 7. Assinaturas e Localidade
  final String localizacao;
  final DateTime dataAssinatura;
  final String responsavel1;
  final String? responsavel2;
  final String? responsavel3;

  // 8. Itens do DFD
  final String? categoriaItens; // 'SIGTAP', 'RENEM', 'CATMED'
  final String? classificacaoRenem;
  final String? linkSigadoc; // Link do processo no SIGADOC (um por DFD)
  final List<dynamic> itens;

  DfdModel({
    this.id,
    this.createdAt,
    required this.orgao,
    required this.unidadeOrcamentaria,
    required this.setorRequisitante,
    required this.responsavelDemanda,
    required this.matricula,
    required this.email,
    required this.telefone,
    required this.classificacaoObjeto,
    required this.descricaoDemanda,
    required this.formaContratacaoSugerida,
    this.numeroArp,
    this.editalArp,
    this.dataPublicacaoArp,
    this.dataVigenciaArp,
    required this.necessidadeEtp,
    this.etpRetiradoManualmente,
    this.etpNumero,
    this.etpFileUrl,
    required this.justificativaNecessidade,
    required this.demonstracaoPrevisaoPac,
    required this.recursosOrcamentarios,
    this.dataPretendidaContratacao,
    required this.grauPrioridade,
    required this.correlacaoPlanejamento,
    required this.integranteRequisitanteNome,
    required this.integranteRequisitanteMatricula,
    required this.integranteRequisitanteLotacao,
    this.integranteTecnico1Nome,
    this.integranteTecnico1Matricula,
    this.integranteTecnico1Lotacao,
    this.integranteTecnico2Nome,
    this.integranteTecnico2Matricula,
    this.integranteTecnico2Lotacao,
    required this.matrizItem,
    required this.matrizG,
    required this.matrizU,
    required this.matrizT,
    required this.localizacao,
    required this.dataAssinatura,
    required this.responsavel1,
    this.responsavel2,
    this.responsavel3,
    this.categoriaItens,
    this.classificacaoRenem,
    this.linkSigadoc,
    this.itens = const [],
  });

  int get matrizResultado => matrizG * matrizU * matrizT;

  factory DfdModel.fromJson(Map<String, dynamic> json) {
    return DfdModel(
      id: json['id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      orgao: json['orgao'] as String? ?? '',
      unidadeOrcamentaria: json['unidade_orcamentaria'] as String? ?? '',
      setorRequisitante: json['setor_requisitante'] as String? ?? '',
      responsavelDemanda: json['responsavel_demanda'] as String? ?? '',
      matricula: json['matricula'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      classificacaoObjeto: json['classificacao_objeto'] as String? ?? '',
      descricaoDemanda: json['descricao_demanda'] as String? ?? '',
      formaContratacaoSugerida:
          json['forma_contratacao_sugerida'] as String? ?? '',
      numeroArp: json['numero_arp'] as String?,
      editalArp: json['edital_arp'] as String?,
      dataPublicacaoArp: json['data_publicacao_arp'] != null
          ? DateTime.parse(json['data_publicacao_arp'])
          : null,
      dataVigenciaArp: json['data_vigencia_arp'] != null
          ? DateTime.parse(json['data_vigencia_arp'])
          : null,
      necessidadeEtp: json['necessidade_etp'] as bool? ?? false,
      etpRetiradoManualmente: json['etp_retirado_manualmente'] as bool?,
      etpNumero: json['etp_numero'] as String?,
      etpFileUrl: json['etp_file_url'] as String?,
      justificativaNecessidade:
          json['justificativa_necessidade'] as String? ?? '',
      demonstracaoPrevisaoPac:
          json['demonstracao_previsao_pac'] as String? ?? '',
      recursosOrcamentarios: json['recursos_orcamentarios'] as String? ?? '',
      dataPretendidaContratacao: json['data_pretendida_contratacao'] != null
          ? DateTime.parse(json['data_pretendida_contratacao'])
          : null,
      grauPrioridade: json['grau_prioridade'] as String? ?? '',
      correlacaoPlanejamento: json['correlacao_planejamento'] as String? ?? '',
      integranteRequisitanteNome:
          json['integrante_requisitante_nome'] as String? ?? '',
      integranteRequisitanteMatricula:
          json['integrante_requisitante_matricula'] as String? ?? '',
      integranteRequisitanteLotacao:
          json['integrante_requisitante_lotacao'] as String? ?? '',
      integranteTecnico1Nome: json['integrante_tecnico_1_nome'] as String?,
      integranteTecnico1Matricula:
          json['integrante_tecnico_1_matricula'] as String?,
      integranteTecnico1Lotacao:
          json['integrante_tecnico_1_lotacao'] as String?,
      integranteTecnico2Nome: json['integrante_tecnico_2_nome'] as String?,
      integranteTecnico2Matricula:
          json['integrante_tecnico_2_matricula'] as String?,
      integranteTecnico2Lotacao:
          json['integrante_tecnico_2_lotacao'] as String?,
      matrizItem: json['matriz_item'] as String? ?? '',
      matrizG: json['matriz_g'] as int? ?? 1,
      matrizU: json['matriz_u'] as int? ?? 1,
      matrizT: json['matriz_t'] as int? ?? 1,
      localizacao: json['localizacao'] as String? ?? '',
      dataAssinatura: json['data_assinatura'] != null
          ? DateTime.parse(json['data_assinatura'])
          : DateTime.now(),
      responsavel1: json['responsavel_1'] as String? ?? '',
      responsavel2: json['responsavel_2'] as String?,
      responsavel3: json['responsavel_3'] as String?,
      categoriaItens: json['categoria_itens'] as String?,
      classificacaoRenem: json['classificacao_renem'] as String?,
      linkSigadoc: json['link_sigadoc'] as String?,
      itens: json['itens'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'orgao': orgao,
      'unidade_orcamentaria': unidadeOrcamentaria,
      'setor_requisitante': setorRequisitante,
      'responsavel_demanda': responsavelDemanda,
      'matricula': matricula,
      'email': email,
      'telefone': telefone,
      'classificacao_objeto': classificacaoObjeto,
      'descricao_demanda': descricaoDemanda,
      'forma_contratacao_sugerida': formaContratacaoSugerida,
      'numero_arp': numeroArp,
      'edital_arp': editalArp,
      'data_publicacao_arp': dataPublicacaoArp?.toIso8601String().split('T')[0],
      'data_vigencia_arp': dataVigenciaArp?.toIso8601String().split('T')[0],
      'necessidade_etp': necessidadeEtp,
      if (etpRetiradoManualmente != null)
        'etp_retirado_manualmente': etpRetiradoManualmente,
      'etp_numero': etpNumero,
      'etp_file_url': etpFileUrl,
      'justificativa_necessidade': justificativaNecessidade,
      'demonstracao_previsao_pac': demonstracaoPrevisaoPac,
      'recursos_orcamentarios': recursosOrcamentarios,
      'data_pretendida_contratacao':
          dataPretendidaContratacao?.toIso8601String().split('T')[0],
      'grau_prioridade': grauPrioridade,
      'correlacao_planejamento': correlacaoPlanejamento,
      'integrante_requisitante_nome': integranteRequisitanteNome,
      'integrante_requisitante_matricula': integranteRequisitanteMatricula,
      'integrante_requisitante_lotacao': integranteRequisitanteLotacao,
      'integrante_tecnico_1_nome': integranteTecnico1Nome,
      'integrante_tecnico_1_matricula': integranteTecnico1Matricula,
      'integrante_tecnico_1_lotacao': integranteTecnico1Lotacao,
      'integrante_tecnico_2_nome': integranteTecnico2Nome,
      'integrante_tecnico_2_matricula': integranteTecnico2Matricula,
      'integrante_tecnico_2_lotacao': integranteTecnico2Lotacao,
      'matriz_item': matrizItem,
      'matriz_g': matrizG,
      'matriz_u': matrizU,
      'matriz_t': matrizT,
      'localizacao': localizacao,
      'data_assinatura': dataAssinatura.toIso8601String().split('T')[0],
      'responsavel_1': responsavel1,
      'responsavel_2': responsavel2,
      'responsavel_3': responsavel3,
      'categoria_itens': categoriaItens,
      'classificacao_renem': classificacaoRenem,
      'link_sigadoc': linkSigadoc,
      'itens': itens,
    };
  }
}
