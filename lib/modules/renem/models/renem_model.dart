class RenemModel {
  final String codItem;
  final String? item;
  final String? definicao;
  final String? classificacao;
  final double? valorSugerido;
  final String? itemDolarizado;
  final String? especificacaoSugerida;
  final DateTime? dataAtualizacao;

  RenemModel({
    required this.codItem,
    this.item,
    this.definicao,
    this.classificacao,
    this.valorSugerido,
    this.itemDolarizado,
    this.especificacaoSugerida,
    this.dataAtualizacao,
  });

  factory RenemModel.fromJson(Map<String, dynamic> json) {
    return RenemModel(
      codItem: json['cod_item'],
      item: json['item'],
      definicao: json['definicao'],
      classificacao: json['classificacao'],
      valorSugerido: json['valor_sugerido'] != null
          ? (json['valor_sugerido'] as num).toDouble()
          : null,
      itemDolarizado: json['item_dolarizado'],
      especificacaoSugerida: json['especificacao_sugerida'],
      dataAtualizacao: json['data_atualizacao'] != null
          ? DateTime.parse(json['data_atualizacao'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cod_item': codItem,
      'item': item,
      'definicao': definicao,
      'classificacao': classificacao,
      'valor_sugerido': valorSugerido,
      'item_dolarizado': itemDolarizado,
      'especificacao_sugerida': especificacaoSugerida,
      if (dataAtualizacao != null)
        'data_atualizacao': dataAtualizacao!.toIso8601String(),
    };
  }
}
