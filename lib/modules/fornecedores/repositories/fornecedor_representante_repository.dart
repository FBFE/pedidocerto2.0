import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fornecedor_representante_model.dart';

class FornecedorRepresentanteRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'fornecedor_representantes';

  Future<List<FornecedorRepresentanteModel>> getByFornecedorId(String fornecedorId) async {
    final res = await _supabase.from(_table).select().eq('fornecedor_id', fornecedorId).order('nome');
    return (res as List).map((e) => FornecedorRepresentanteModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Verifica se já existe representante com esse CPF no mesmo fornecedor (evitar duplicata).
  Future<bool> existeCpfNoFornecedor(String fornecedorId, String cpf, {String? excludeId}) async {
    final limpo = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (limpo.isEmpty) return false;
    final res = await _supabase.from(_table).select('id, cpf').eq('fornecedor_id', fornecedorId) as List;
    for (final row in res) {
      final map = row as Map;
      final existingCpf = map['cpf']?.toString().replaceAll(RegExp(r'[^\d]'), '');
      if (existingCpf == limpo && (excludeId == null || map['id'] != excludeId)) return true;
    }
    return false;
  }

  Future<FornecedorRepresentanteModel> insert(FornecedorRepresentanteModel m) async {
    final json = m.toJson();
    json.remove('id');
    final res = await _supabase.from(_table).insert(json).select().single();
    return FornecedorRepresentanteModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> delete(String id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }
}
