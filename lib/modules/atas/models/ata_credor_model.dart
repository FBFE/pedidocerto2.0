/// Credor vinculado a uma ata (fornecedor/empresa + representante).
class AtaCredorModel {
  final String? id;
  final String ataId;

  /// Vínculo com cadastro de fornecedores (opcional)
  final String? fornecedorId;
  final String? representanteId;

  /// Empresa (cópia ou preenchido manualmente)
  final String? cnpj;
  final String? razaoSocial;
  final String? nomeFantasia;
  final String? endereco;
  final String? contato;
  final String? situacao;

  /// Representante (cópia ou preenchido manualmente)
  final String? representanteNome;
  final String? representanteCpf;
  final String? representanteRg;
  final String? representanteContato;
  final String? representanteEmail;

  AtaCredorModel({
    this.id,
    required this.ataId,
    this.fornecedorId,
    this.representanteId,
    this.cnpj,
    this.razaoSocial,
    this.nomeFantasia,
    this.endereco,
    this.contato,
    this.situacao,
    this.representanteNome,
    this.representanteCpf,
    this.representanteRg,
    this.representanteContato,
    this.representanteEmail,
  });

  factory AtaCredorModel.fromJson(Map<String, dynamic> json) {
    return AtaCredorModel(
      id: json['id'] as String?,
      ataId: json['ata_id'] as String? ?? '',
      fornecedorId: json['fornecedor_id'] as String?,
      representanteId: json['representante_id'] as String?,
      cnpj: json['cnpj'] as String?,
      razaoSocial: json['razao_social'] as String?,
      nomeFantasia: json['nome_fantasia'] as String?,
      endereco: json['endereco'] as String?,
      contato: json['contato'] as String?,
      situacao: json['situacao'] as String?,
      representanteNome: json['representante_nome'] as String?,
      representanteCpf: json['representante_cpf'] as String?,
      representanteRg: json['representante_rg'] as String?,
      representanteContato: json['representante_contato'] as String?,
      representanteEmail: json['representante_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ata_id': ataId,
      'fornecedor_id': fornecedorId,
      'representante_id': representanteId,
      'cnpj': cnpj,
      'razao_social': razaoSocial,
      'nome_fantasia': nomeFantasia,
      'endereco': endereco,
      'contato': contato,
      'situacao': situacao,
      'representante_nome': representanteNome,
      'representante_cpf': representanteCpf,
      'representante_rg': representanteRg,
      'representante_contato': representanteContato,
      'representante_email': representanteEmail,
    };
  }
}
