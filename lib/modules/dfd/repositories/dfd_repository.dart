import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../audit/services/audit_log_service.dart';
import '../models/dfd_model.dart';
import '../services/dfd_storage_service.dart';

class DfdRepository {
  final _supabase = Supabase.instance.client;
  final _storage = DfdStorageService();
  final String _tableName = 'dfd';

  Future<List<DfdModel>> getDfds() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list
        .map((e) => DfdModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<DfdModel> getDfdById(String id) async {
    final response =
        await _supabase.from(_tableName).select().eq('id', id).single();
    return DfdModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> _verificarDuplicidadeEtp(String? etpNumero,
      {String? ignoreId}) async {
    if (etpNumero == null || etpNumero.trim().isEmpty) return;

    final query = _supabase
        .from(_tableName)
        .select('id')
        .eq('etp_numero', etpNumero.trim());
    final result =
        ignoreId != null ? await query.neq('id', ignoreId) : await query;

    if ((result as List).isNotEmpty) {
      throw Exception(
          'Já existe um DFD cadastrado com este Número de ETP ($etpNumero). Não é permitido ETP duplicado.');
    }
  }

  /// Verifica se o link_sigadoc (nível DFD) já está em uso em outro DFD.
  /// Retorna { 'dfdId': id, 'etpNumero': numero ou null } se duplicado.
  Future<Map<String, String?>?> findLinkSigadocDuplicado(
    String link, {
    String? ignoreDfdId,
  }) async {
    final trimmed = link.trim();
    if (trimmed.isEmpty) return null;

    var query = _supabase
        .from(_tableName)
        .select('id, etp_numero')
        .eq('link_sigadoc', trimmed);
    if (ignoreDfdId != null) {
      query = query.neq('id', ignoreDfdId);
    }
    final list = await query as List<dynamic>;
    if (list.isEmpty) return null;
    final row = Map<String, dynamic>.from(list.first as Map);
    return {
      'dfdId': row['id'] as String? ?? '',
      'etpNumero': row['etp_numero'] as String?,
    };
  }

  Future<DfdModel> createDfd(DfdModel dfd,
      {Uint8List? etpBytes, String? etpFileName}) async {
    await _verificarDuplicidadeEtp(dfd.etpNumero);

    final json = dfd.toJson();
    if (etpBytes != null && etpFileName != null) {
      json.remove('etp_file_url'); // Será inserido após pegar o ID
    }

    final response =
        await _supabase.from(_tableName).insert(json).select().single();

    final inserted = DfdModel.fromJson(Map<String, dynamic>.from(response));

    if (etpBytes != null && etpFileName != null && inserted.id != null) {
      final path =
          await _storage.uploadEtp(etpBytes, inserted.id!, etpFileName);
      await _supabase
          .from(_tableName)
          .update({'etp_file_url': path}).eq('id', inserted.id!);
      final out = DfdModel.fromJson(
          Map<String, dynamic>.from(response)..['etp_file_url'] = path);
      try {
        await AuditLogService.logCreate(
          entityName: _tableName,
          entityId: out.id,
          newValue: out.toJson(),
        );
      } catch (_) {}
      return out;
    }
    try {
      await AuditLogService.logCreate(
        entityName: _tableName,
        entityId: inserted.id,
        newValue: inserted.toJson(),
      );
    } catch (_) {}
    return inserted;
  }

  Future<DfdModel> updateDfd(DfdModel dfd,
      {Uint8List? etpBytes, String? etpFileName}) async {
    if (dfd.id == null) {
      throw Exception('ID do DFD não pode ser nulo para atualização');
    }

    await _verificarDuplicidadeEtp(dfd.etpNumero, ignoreId: dfd.id);

    final oldDfd = await getDfdById(dfd.id!);
    String? newPath = dfd.etpFileUrl;
    if (etpBytes != null && etpFileName != null) {
      await _storage.deleteByPath(dfd.etpFileUrl);
      newPath = await _storage.uploadEtp(etpBytes, dfd.id!, etpFileName);
    }

    final json = dfd.toJson();
    json['etp_file_url'] = newPath;

    final response = await _supabase
        .from(_tableName)
        .update(json)
        .eq('id', dfd.id!)
        .select()
        .single();
    final updated = DfdModel.fromJson(Map<String, dynamic>.from(response));
    try {
      await AuditLogService.logUpdate(
        entityName: _tableName,
        entityId: dfd.id,
        oldValue: oldDfd.toJson(),
        newValue: updated.toJson(),
      );
    } catch (_) {}
    return updated;
  }

  Future<void> deleteDfd(String id) async {
    final dfd = await getDfdById(id);
    if (dfd.etpFileUrl != null) {
      await _storage.deleteByPath(dfd.etpFileUrl);
    }
    await _supabase.from(_tableName).delete().eq('id', id);
    try {
      await AuditLogService.logDelete(
        entityName: _tableName,
        entityId: id,
        oldValue: dfd.toJson(),
      );
    } catch (_) {}
  }
}
