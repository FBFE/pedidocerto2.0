/// Registro da trilha de auditoria (CREATE, UPDATE, DELETE).
class AuditLogModel {
  final String? id;
  final String? userId;
  final String action;
  final String entityName;
  final String? entityId;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String? ipAddress;
  final DateTime? createdAt;

  AuditLogModel({
    this.id,
    this.userId,
    required this.action,
    required this.entityName,
    this.entityId,
    this.oldValue,
    this.newValue,
    this.ipAddress,
    this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      action: json['action'] as String? ?? '',
      entityName: json['entity_name'] as String? ?? '',
      entityId: json['entity_id'] as String?,
      oldValue: json['old_value'] != null
          ? Map<String, dynamic>.from(json['old_value'] as Map)
          : null,
      newValue: json['new_value'] != null
          ? Map<String, dynamic>.from(json['new_value'] as Map)
          : null,
      ipAddress: json['ip_address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static String actionLabel(String action) {
    switch (action) {
      case 'CREATE':
        return 'Adicionar';
      case 'UPDATE':
        return 'Editar';
      case 'DELETE':
        return 'Excluir';
      default:
        return action;
    }
  }
}
