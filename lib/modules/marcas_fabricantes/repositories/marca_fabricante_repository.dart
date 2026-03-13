import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marca_fabricante_model.dart';

class MarcaFabricanteRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'marcas_fabricantes';

  Future<List<MarcaFabricanteModel>> getAll() async {
    final res = await _supabase.from(_table).select().order('nome');
    return (res as List).map((e) => MarcaFabricanteModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Busca marcas com nome similar (para avisar duplicata: ILIKE %termo%).
  Future<List<MarcaFabricanteModel>> getSimilares(String termo) async {
    if (termo.trim().isEmpty) return [];
    final t = termo.trim().toLowerCase();
    final res = await _supabase.from(_table).select().ilike('nome', '%$t%').limit(10);
    return (res as List).map((e) => MarcaFabricanteModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Verifica se já existe marca com mesmo nome (case-insensitive, trim).
  Future<MarcaFabricanteModel?> getPorNomeExato(String nome) async {
    final n = nome.trim();
    if (n.isEmpty) return null;
    final res = await _supabase.from(_table).select().ilike('nome', n).maybeSingle();
    return res == null ? null : MarcaFabricanteModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<MarcaFabricanteModel> insert(MarcaFabricanteModel m) async {
    final json = m.toJson()..remove('id');
    final res = await _supabase.from(_table).insert(json).select().single();
    return MarcaFabricanteModel.fromJson(Map<String, dynamic>.from(res as Map));
  }
}
