import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/secretaria_adjunta_model.dart';

class SecretariaAdjuntaRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'secretarias_adjuntas';

  Future<List<SecretariaAdjuntaModel>> getAll() async {
    final res = await _supabase.from(_table).select().order('nome');
    return (res as List)
        .map((e) => SecretariaAdjuntaModel.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SecretariaAdjuntaModel>> getBySecretariaId(
      String secretariaId) async {
    final res = await _supabase
        .from(_table)
        .select()
        .eq('secretaria_id', secretariaId)
        .order('nome');
    return (res as List)
        .map((e) => SecretariaAdjuntaModel.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<SecretariaAdjuntaModel?> getById(String id) async {
    final res =
        await _supabase.from(_table).select().eq('id', id).maybeSingle();
    return res == null
        ? null
        : SecretariaAdjuntaModel.fromJson(
            Map<String, dynamic>.from(res as Map));
  }

  Future<SecretariaAdjuntaModel> insert(SecretariaAdjuntaModel m) async {
    final res =
        await _supabase.from(_table).insert(m.toJson()).select().single();
    return SecretariaAdjuntaModel.fromJson(
        Map<String, dynamic>.from(res as Map));
  }

  Future<SecretariaAdjuntaModel> update(SecretariaAdjuntaModel m) async {
    if (m.id == null) throw Exception('ID obrigatório para atualizar');
    final res = await _supabase
        .from(_table)
        .update(m.toJson())
        .eq('id', m.id!)
        .select()
        .single();
    return SecretariaAdjuntaModel.fromJson(
        Map<String, dynamic>.from(res as Map));
  }

  Future<void> delete(String id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }
}
