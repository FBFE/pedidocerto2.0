import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/setor_model.dart';

class SetorRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'setores';

  Future<List<SetorModel>> getAll() async {
    final res = await _supabase.from(_table).select().order('nome');
    return (res as List)
        .map((e) => SetorModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SetorModel>> getBySecretariaAdjuntaId(String id) async {
    final res = await _supabase
        .from(_table)
        .select()
        .eq('secretaria_adjunta_id', id)
        .order('nome');
    return (res as List)
        .map((e) => SetorModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SetorModel>> getByUnidadeHospitalarId(String id) async {
    final res = await _supabase
        .from(_table)
        .select()
        .eq('unidade_hospitalar_id', id)
        .order('nome');
    return (res as List)
        .map((e) => SetorModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<SetorModel?> getById(String id) async {
    final res =
        await _supabase.from(_table).select().eq('id', id).maybeSingle();
    return res == null
        ? null
        : SetorModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<SetorModel> insert(SetorModel m) async {
    final res =
        await _supabase.from(_table).insert(m.toJson()).select().single();
    return SetorModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<SetorModel> update(SetorModel m) async {
    if (m.id == null) throw Exception('ID obrigatório para atualizar');
    final res = await _supabase
        .from(_table)
        .update(m.toJson())
        .eq('id', m.id!)
        .select()
        .single();
    return SetorModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> delete(String id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }
}
