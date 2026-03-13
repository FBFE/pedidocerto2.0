import 'package:supabase_flutter/supabase_flutter.dart';

import '../../usuarios/repositories/usuario_repository.dart';
import '../models/audit_log_model.dart';
import '../repositories/audit_log_repository.dart';

/// Serviço para registrar ações (CREATE, UPDATE, DELETE) na trilha de auditoria.
/// Quem realizou a ação é obtido do usuário logado (Supabase Auth + tabela usuarios).
class AuditLogService {
  AuditLogService._();

  static final _repo = AuditLogRepository();
  static final _usuarioRepo = UsuarioRepository();

  static String? _cachedUserId;
  static String? _cachedEmail;

  static Future<String?> _getCurrentUserId() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null || email.isEmpty) return null;
    if (_cachedEmail == email && _cachedUserId != null) return _cachedUserId;
    try {
      final u = await _usuarioRepo.getUsuarioByEmail(email);
      _cachedEmail = email;
      _cachedUserId = u?.id;
      return _cachedUserId;
    } catch (_) {
      return null;
    }
  }

  /// Registra criação. [newValue] = estado do registro após o insert.
  static Future<void> logCreate({
    required String entityName,
    required String? entityId,
    required Map<String, dynamic>? newValue,
  }) async {
    final userId = await _getCurrentUserId();
    await _repo.insert(AuditLogModel(
      userId: userId,
      action: 'CREATE',
      entityName: entityName,
      entityId: entityId,
      newValue: newValue,
    ));
  }

  /// Registra alteração. [oldValue] = antes, [newValue] = depois.
  static Future<void> logUpdate({
    required String entityName,
    required String? entityId,
    required Map<String, dynamic>? oldValue,
    required Map<String, dynamic>? newValue,
  }) async {
    final userId = await _getCurrentUserId();
    await _repo.insert(AuditLogModel(
      userId: userId,
      action: 'UPDATE',
      entityName: entityName,
      entityId: entityId,
      oldValue: oldValue,
      newValue: newValue,
    ));
  }

  /// Registra exclusão. [oldValue] = estado do registro antes do delete.
  static Future<void> logDelete({
    required String entityName,
    required String? entityId,
    required Map<String, dynamic>? oldValue,
  }) async {
    final userId = await _getCurrentUserId();
    await _repo.insert(AuditLogModel(
      userId: userId,
      action: 'DELETE',
      entityName: entityName,
      entityId: entityId,
      oldValue: oldValue,
    ));
  }

  /// Limpa cache do usuário (ex.: no logout).
  static void clearUserCache() {
    _cachedUserId = null;
    _cachedEmail = null;
  }
}
