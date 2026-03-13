import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/unidade_medida_model.dart';

class UnidadeMedidaRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'unidades_medida';

  Future<List<UnidadeMedidaModel>> getAll({String? categoria}) async {
    var query = _supabase.from(_table).select();
    if (categoria != null && categoria.trim().isNotEmpty) {
      query = query.eq('categoria', categoria.trim());
    }
    final res = await query.order('sigla');
    return (res as List).map((e) => UnidadeMedidaModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<String>> getCategorias() async {
    final res = await _supabase.from(_table).select('categoria');
    final set = <String>{};
    for (final e in res as List) {
      final c = (e as Map)['categoria']?.toString();
      if (c != null && c.trim().isNotEmpty) set.add(c.trim());
    }
    return set.toList()..sort();
  }

  Future<UnidadeMedidaModel?> getPorSigla(String sigla) async {
    final s = sigla.trim();
    if (s.isEmpty) return null;
    final res = await _supabase.from(_table).select().eq('sigla', s).maybeSingle();
    return res == null ? null : UnidadeMedidaModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<UnidadeMedidaModel> insert(UnidadeMedidaModel u) async {
    final json = u.toJson()..remove('id');
    final res = await _supabase.from(_table).insert(json).select().single();
    return UnidadeMedidaModel.fromJson(Map<String, dynamic>.from(res as Map));
  }
}
