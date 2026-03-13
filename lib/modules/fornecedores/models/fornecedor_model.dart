/// Fornecedor (empresa) no banco – CNPJ único.
class FornecedorModel {
  final String? id;
  final String cnpj;
  final String? razaoSocial;
  final String? nomeFantasia;
  final String? endereco;
  final String? contato;
  final String? email;
  final String? situacao;
  final DateTime? createdAt;

  FornecedorModel({
    this.id,
    required this.cnpj,
    this.razaoSocial,
    this.nomeFantasia,
    this.endereco,
    this.contato,
    this.email,
    this.situacao,
    this.createdAt,
  });

  factory FornecedorModel.fromJson(Map<String, dynamic> json) {
    return FornecedorModel(
      id: json['id'] as String?,
      cnpj: json['cnpj'] as String? ?? '',
      razaoSocial: json['razao_social'] as String?,
      nomeFantasia: json['nome_fantasia'] as String?,
      endereco: json['endereco'] as String?,
      contato: json['contato'] as String?,
      email: json['email'] as String?,
      situacao: json['situacao'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'cnpj': cnpj,
      'razao_social': razaoSocial,
      'nome_fantasia': nomeFantasia,
      'endereco': endereco,
      'contato': contato,
      'email': email,
      'situacao': situacao,
    };
  }
}
