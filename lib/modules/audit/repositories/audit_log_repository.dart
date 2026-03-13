import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/audit_log_model.dart';

class AuditLogRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'audit_logs';

  Future<void> insert(AuditLogModel log) async {
    final json = {
      if (log.userId != null) 'user_id': log.userId,
      'action': log.action,
      'entity_name': log.entityName,
      if (log.entityId != null) 'entity_id': log.entityId,
      if (log.oldValue != null) 'old_value': log.oldValue,
      if (log.newValue != null) 'new_value': log.newValue,
      if (log.ipAddress != null) 'ip_address': log.ipAddress,
    };
    await _supabase.from(_table).insert(json);
  }

  Future<List<AuditLogModel>> getLogs({
    String? entityName,
    String? action,
    int limit = 100,
    int offset = 0,
  }) async {
    var query = _supabase.from(_table).select();
    if (entityName != null && entityName.isNotEmpty) {
      query = query.eq('entity_name', entityName);
    }
    if (action != null && action.isNotEmpty) {
      query = query.eq('action', action);
    }
    final res = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (res as List)
        .map((e) => AuditLogModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<AuditLogModel?> getById(String id) async {
    final res = await _supabase.from(_table).select().eq('id', id).maybeSingle();
    return res == null ? null : AuditLogModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Restaura o estado anterior. Só deve ser chamado por administradores.
  /// UPDATE: aplica old_value no registro atual.
  /// DELETE: reinsere o registro a partir de old_value.
  /// CREATE: remove o registro criado (entity_id).
  Future<void> restore(AuditLogModel log) async {
    final table = log.entityName;
    final entityId = log.entityId;
    if (table.isEmpty) throw Exception('Entidade inválida');

    switch (log.action) {
      case 'UPDATE':
        if (entityId == null || log.oldValue == null) throw Exception('Dados insuficientes para restauração');
        final payload = Map<String, dynamic>.from(log.oldValue!);
        payload.remove('id');
        await _supabase.from(table).update(payload).eq('id', entityId);
        break;
      case 'DELETE':
        if (log.oldValue == null) throw Exception('Dados insuficientes para restauração');
        await _supabase.from(table).insert(log.oldValue!);
        break;
      case 'CREATE':
        if (entityId == null) throw Exception('ID do registro não informado');
        await _supabase.from(table).delete().eq('id', entityId);
        break;
      default:
        throw Exception('Ação não suportada para restauração');
    }
  }
}
