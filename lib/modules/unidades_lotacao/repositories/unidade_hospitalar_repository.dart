import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/unidade_hospitalar_model.dart';
import '../services/logo_storage_service.dart';

class UnidadeHospitalarRepository {
  final _supabase = Supabase.instance.client;
  final _logoStorage = LogoStorageService();
  static const _table = 'unidades_hospitalares';

  /// URL pública para exibir a logo (logo_url no banco guarda o path do bucket).
  String logoPublicUrl(String? logoUrl) => _logoStorage.getPublicUrl(logoUrl);

  Future<List<UnidadeHospitalarModel>> getAll() async {
    final res = await _supabase.from(_table).select().order('nome');
    return (res as List)
        .map((e) => UnidadeHospitalarModel.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<UnidadeHospitalarModel>> getBySecretariaId(
      String secretariaId) async {
    final res = await _supabase
        .from(_table)
        .select()
        .eq('secretaria_id', secretariaId)
        .order('nome');
    return (res as List)
        .map((e) => UnidadeHospitalarModel.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<UnidadeHospitalarModel?> getById(String id) async {
    final res =
        await _supabase.from(_table).select().eq('id', id).maybeSingle();
    return res == null
        ? null
        : UnidadeHospitalarModel.fromJson(
            Map<String, dynamic>.from(res as Map));
  }

  /// Insere a unidade. Se [logoBytes] e [logoExtension] forem fornecidos, faz upload
  /// da logo no bucket e grava o path em logo_url.
  Future<UnidadeHospitalarModel> insert(
    UnidadeHospitalarModel m, {
    Uint8List? logoBytes,
    String? logoExtension,
  }) async {
    final json = m.toJson();
    final hasLogo = logoBytes != null &&
        logoExtension != null &&
        (logoExtension.isNotEmpty);
    if (hasLogo) json.remove('logo_url');
    final res = await _supabase.from(_table).insert(json).select().single();
    final inserted =
        UnidadeHospitalarModel.fromJson(Map<String, dynamic>.from(res as Map));
    if (logoBytes != null &&
        logoExtension != null &&
        logoExtension.isNotEmpty &&
        inserted.id != null) {
      final path =
          await _logoStorage.upload(logoBytes, inserted.id!, logoExtension);
      await _supabase
          .from(_table)
          .update({'logo_url': path}).eq('id', inserted.id!);
      return UnidadeHospitalarModel.fromJson(
          Map<String, dynamic>.from(res)..['logo_url'] = path);
    }
    return inserted;
  }

  /// Atualiza a unidade. Se [logoBytes] e [logoExtension] forem fornecidos, remove
  /// a logo antiga do bucket, faz upload da nova e atualiza logo_url.
  Future<UnidadeHospitalarModel> update(
    UnidadeHospitalarModel m, {
    Uint8List? logoBytes,
    String? logoExtension,
  }) async {
    if (m.id == null) throw Exception('ID obrigatório para atualizar');
    String? newLogoPath = m.logoUrl;
    if (logoBytes != null &&
        logoExtension != null &&
        logoExtension.isNotEmpty) {
      await _logoStorage.deleteByPath(m.logoUrl);
      newLogoPath = await _logoStorage.upload(logoBytes, m.id!, logoExtension);
    }
    final json = m.toJson();
    json['logo_url'] = newLogoPath;
    final res = await _supabase
        .from(_table)
        .update(json)
        .eq('id', m.id!)
        .select()
        .single();
    return UnidadeHospitalarModel.fromJson(
        Map<String, dynamic>.from(res as Map));
  }

  /// Remove a unidade e, se existir, a logo no bucket.
  Future<void> delete(String id) async {
    final unidade = await getById(id);
    if (unidade?.logoUrl != null) {
      await _logoStorage.deleteByPath(unidade!.logoUrl);
    }
    await _supabase.from(_table).delete().eq('id', id);
  }
}
