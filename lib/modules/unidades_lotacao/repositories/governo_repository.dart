import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/governo_model.dart';
import '../services/logo_storage_service.dart';

class GovernoRepository {
  final _supabase = Supabase.instance.client;
  final _logoStorage = LogoStorageService();
  static const _table = 'governo';

  String logoPublicUrl(String? logoUrl) => _logoStorage.getPublicUrl(logoUrl);

  /// Retorna o primeiro governo (organograma tem uma raiz).
  Future<GovernoModel?> getFirst() async {
    final res = await _supabase.from(_table).select().limit(1).maybeSingle();
    return res == null
        ? null
        : GovernoModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<List<GovernoModel>> getAll() async {
    final res = await _supabase.from(_table).select().order('nome');
    return (res as List)
        .map((e) => GovernoModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<GovernoModel?> getById(String id) async {
    final res =
        await _supabase.from(_table).select().eq('id', id).maybeSingle();
    return res == null
        ? null
        : GovernoModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<GovernoModel> insert(
    GovernoModel m, {
    Uint8List? logoBytes,
    String? logoExtension,
  }) async {
    final json = m.toJson();
    if (logoBytes != null &&
        logoExtension != null &&
        logoExtension.isNotEmpty) {
      json.remove('logo_url');
    }
    final res = await _supabase.from(_table).insert(json).select().single();
    final inserted =
        GovernoModel.fromJson(Map<String, dynamic>.from(res as Map));
    if (logoBytes != null &&
        logoExtension != null &&
        logoExtension.isNotEmpty &&
        inserted.id != null) {
      final path = await _logoStorage.uploadGoverno(
          logoBytes, inserted.id!, logoExtension);
      await _supabase
          .from(_table)
          .update({'logo_url': path}).eq('id', inserted.id!);
      return GovernoModel.fromJson(
          Map<String, dynamic>.from(res)..['logo_url'] = path);
    }
    return inserted;
  }

  Future<GovernoModel> update(
    GovernoModel m, {
    Uint8List? logoBytes,
    String? logoExtension,
  }) async {
    if (m.id == null) throw Exception('ID obrigatório para atualizar');
    String? newLogoPath = m.logoUrl;
    if (logoBytes != null &&
        logoExtension != null &&
        logoExtension.isNotEmpty) {
      await _logoStorage.deleteByPath(m.logoUrl);
      newLogoPath =
          await _logoStorage.uploadGoverno(logoBytes, m.id!, logoExtension);
    }
    final json = m.toJson();
    json['logo_url'] = newLogoPath;
    final res = await _supabase
        .from(_table)
        .update(json)
        .eq('id', m.id!)
        .select()
        .single();
    return GovernoModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> delete(String id) async {
    final g = await getById(id);
    if (g?.logoUrl != null) await _logoStorage.deleteByPath(g!.logoUrl);
    await _supabase.from(_table).delete().eq('id', id);
  }
}
