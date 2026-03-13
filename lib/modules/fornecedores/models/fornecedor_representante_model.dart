/// Representante de um fornecedor – CPF não duplica no mesmo fornecedor.
class FornecedorRepresentanteModel {
  final String? id;
  final String fornecedorId;
  final String? nome;
  final String? cpf;
  final String? rg;
  final String? contato;
  final String? email;

  FornecedorRepresentanteModel({
    this.id,
    required this.fornecedorId,
    this.nome,
    this.cpf,
    this.rg,
    this.contato,
    this.email,
  });

  factory FornecedorRepresentanteModel.fromJson(Map<String, dynamic> json) {
    return FornecedorRepresentanteModel(
      id: json['id'] as String?,
      fornecedorId: json['fornecedor_id'] as String? ?? '',
      nome: json['nome'] as String?,
      cpf: json['cpf'] as String?,
      rg: json['rg'] as String?,
      contato: json['contato'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'fornecedor_id': fornecedorId,
      'nome': nome,
      'cpf': cpf,
      'rg': rg,
      'contato': contato,
      'email': email,
    };
  }
}
