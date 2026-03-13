import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fornecedor_model.dart';

class FornecedorRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'fornecedores';

  Future<List<FornecedorModel>> getAll() async {
    final res = await _supabase.from(_table).select().order('razao_social');
    return (res as List).map((e) => FornecedorModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<FornecedorModel?> getByCnpj(String cnpj) async {
    final limpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (limpo.length != 14) return null;
    final res = await _supabase.from(_table).select().eq('cnpj', limpo).maybeSingle();
    return res == null ? null : FornecedorModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<FornecedorModel?> getById(String id) async {
    final res = await _supabase.from(_table).select().eq('id', id).maybeSingle();
    return res == null ? null : FornecedorModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Insere fornecedor. Falha se CNPJ já existir (duplicado).
  Future<FornecedorModel> insert(FornecedorModel m) async {
    final cnpjLimpo = m.cnpj.replaceAll(RegExp(r'[^\d]'), '');
    final json = m.toJson()..['cnpj'] = cnpjLimpo;
    json.remove('id');
    final res = await _supabase.from(_table).insert(json).select().single();
    return FornecedorModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<FornecedorModel> update(FornecedorModel m) async {
    if (m.id == null) throw Exception('ID obrigatório para atualizar');
    final res = await _supabase.from(_table).update(m.toJson()).eq('id', m.id!).select().single();
    return FornecedorModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> delete(String id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }
}
