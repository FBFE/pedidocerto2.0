/// Item de um credor na ata (quantidade, valores e padronização com banco).
class AtaCredorItemModel {
  final String? id;
  final String ataCredorId;
  final int numeroItem;
  final String? descricao;
  final double quantidade;
  final double valorUnitario;
  final double valorTotal;
  /// Código no banco (CATMED/RENEM/SIGTAP) ou null se novo por ata
  final String? codigoItemPadrao;
  /// 'catmed' | 'renem' | 'sigtap' | 'novo_ata'
  final String? tipoItemPadrao;
  /// Descrição quando tipo_item_padrao = novo_ata
  final String? descricaoItemPadrao;
  /// Nome do item (ex.: descrição do banco ou digitado)
  final String? nomeItem;
  /// Especificação adicional se houver
  final String? especificacao;
  /// ID da marca/fabricante (banco marcas_fabricantes)
  final String? marcaFabricanteId;
  /// ID da unidade de medida (banco unidades_medida)
  final String? unidadeMedidaId;
  /// Para itens de cadastro manual: quem cadastrou
  final String? usuarioCadastrouNome;
  final String? usuarioCadastrouMatricula;
  final DateTime? createdAt;

  AtaCredorItemModel({
    this.id,
    required this.ataCredorId,
    required this.numeroItem,
    this.descricao,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
    this.codigoItemPadrao,
    this.tipoItemPadrao,
    this.descricaoItemPadrao,
    this.nomeItem,
    this.especificacao,
    this.marcaFabricanteId,
    this.unidadeMedidaId,
    this.usuarioCadastrouNome,
    this.usuarioCadastrouMatricula,
    this.createdAt,
  });

  bool get isCadastroManual => tipoItemPadrao == 'cadastro_manual';

  factory AtaCredorItemModel.fromJson(Map<String, dynamic> json) {
    return AtaCredorItemModel(
      id: json['id'] as String?,
      ataCredorId: json['ata_credor_id'] as String? ?? '',
      numeroItem: json['numero_item'] is int
          ? json['numero_item'] as int
          : int.tryParse(json['numero_item']?.toString() ?? '0') ?? 0,
      descricao: json['descricao'] as String?,
      quantidade: (json['quantidade'] as num?)?.toDouble() ?? 0,
      valorUnitario: (json['valor_unitario'] as num?)?.toDouble() ?? 0,
      valorTotal: (json['valor_total'] as num?)?.toDouble() ?? 0,
      codigoItemPadrao: json['codigo_item_padrao'] as String?,
      tipoItemPadrao: json['tipo_item_padrao'] as String?,
      descricaoItemPadrao: json['descricao_item_padrao'] as String?,
      nomeItem: json['nome_item'] as String?,
      especificacao: json['especificacao'] as String?,
      marcaFabricanteId: json['marca_fabricante_id'] as String?,
      unidadeMedidaId: json['unidade_medida_id'] as String?,
      usuarioCadastrouNome: json['usuario_cadastrou_nome'] as String?,
      usuarioCadastrouMatricula: json['usuario_cadastrou_matricula'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ata_credor_id': ataCredorId,
      'numero_item': numeroItem,
      'descricao': descricao,
      'quantidade': quantidade,
      'valor_unitario': valorUnitario,
      'valor_total': valorTotal,
      'codigo_item_padrao': codigoItemPadrao,
      'tipo_item_padrao': tipoItemPadrao,
      'descricao_item_padrao': descricaoItemPadrao,
      'nome_item': nomeItem,
      'especificacao': especificacao,
      'marca_fabricante_id': marcaFabricanteId,
      'unidade_medida_id': unidadeMedidaId,
      'usuario_cadastrou_nome': usuarioCadastrouNome,
      'usuario_cadastrou_matricula': usuarioCadastrouMatricula,
    };
  }
}
