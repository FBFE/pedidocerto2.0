import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/secretaria_model.dart';

class SecretariaRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'secretarias';

  Future<List<SecretariaModel>> getAll() async {
    final res = await _supabase.from(_table).select().order('nome');
    return (res as List)
        .map((e) =>
            SecretariaModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SecretariaModel>> getByGovernoId(String governoId) async {
    final res = await _supabase
        .from(_table)
        .select()
        .eq('governo_id', governoId)
        .order('nome');
    return (res as List)
        .map((e) =>
            SecretariaModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<SecretariaModel?> getById(String id) async {
    final res =
        await _supabase.from(_table).select().eq('id', id).maybeSingle();
    return res == null
        ? null
        : SecretariaModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<SecretariaModel> insert(SecretariaModel m) async {
    final res =
        await _supabase.from(_table).insert(m.toJson()).select().single();
    return SecretariaModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<SecretariaModel> update(SecretariaModel m) async {
    if (m.id == null) throw Exception('ID obrigatório para atualizar');
    final res = await _supabase
        .from(_table)
        .update(m.toJson())
        .eq('id', m.id!)
        .select()
        .single();
    return SecretariaModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> delete(String id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }
}
