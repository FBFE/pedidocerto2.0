/// Permissão de um usuário para um módulo (DFD, SIGTAP, RENEM, etc.).
class UsuarioPermissaoModel {
  final String? id;
  final String usuarioId;
  final String modulo;
  final bool adicionar;
  final bool editar;
  final bool excluir;

  UsuarioPermissaoModel({
    this.id,
    required this.usuarioId,
    required this.modulo,
    this.adicionar = false,
    this.editar = false,
    this.excluir = false,
  });

  factory UsuarioPermissaoModel.fromJson(Map<String, dynamic> json) {
    return UsuarioPermissaoModel(
      id: json['id'] as String?,
      usuarioId: json['usuario_id'] as String? ?? '',
      modulo: json['modulo'] as String? ?? '',
      adicionar: json['adicionar'] as bool? ?? false,
      editar: json['editar'] as bool? ?? false,
      excluir: json['excluir'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'usuario_id': usuarioId,
      'modulo': modulo,
      'adicionar': adicionar,
      'editar': editar,
      'excluir': excluir,
    };
  }

  UsuarioPermissaoModel copyWith({
    String? id,
    String? usuarioId,
    String? modulo,
    bool? adicionar,
    bool? editar,
    bool? excluir,
  }) {
    return UsuarioPermissaoModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      modulo: modulo ?? this.modulo,
      adicionar: adicionar ?? this.adicionar,
      editar: editar ?? this.editar,
      excluir: excluir ?? this.excluir,
    );
  }
}

/// Módulos que possuem permissões (Editar, Adicionar, Excluir).
class ModulosPermissao {
  static const String dfd = 'dfd';
  static const String sigtap = 'sigtap';
  static const String renem = 'renem';
  static const String organograma = 'organograma';
  static const String catmed = 'catmed';
  static const String atas = 'atas';
  static const String fornecedores = 'fornecedores';
  static const String unidades = 'unidades';

  static const List<String> todos = [
    dfd,
    sigtap,
    renem,
    organograma,
    catmed,
    atas,
    fornecedores,
    unidades,
  ];

  static String label(String modulo) {
    switch (modulo) {
      case dfd:
        return 'DFD';
      case sigtap:
        return 'Procedimentos SIGTAP';
      case renem:
        return 'Equipamentos RENEM';
      case organograma:
        return 'Organograma';
      case catmed:
        return 'Medicamentos CATMED';
      case atas:
        return 'Banco de Atas';
      case fornecedores:
        return 'Fornecedores';
      case unidades:
        return 'Unidades Hospitalares';
      default:
        return modulo;
    }
  }
}
