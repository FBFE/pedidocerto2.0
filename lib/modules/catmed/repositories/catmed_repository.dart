import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/catmed_model.dart';

class CatmedRepository {
  final _supabase = Supabase.instance.client;

  Future<List<CatmedModel>> getMedicamentos({
    String? termoBusca,
    String? statusFiltro,
    int limite = 50,
    int offset = 0,
  }) async {
    var query = _supabase.from('catmed_medicamentos').select();

    if (statusFiltro != null && statusFiltro.isNotEmpty && statusFiltro != 'Todos') {
      query = query.eq('status', statusFiltro.toLowerCase());
    }

    if (termoBusca != null && termoBusca.trim().isNotEmpty) {
      // Divide a busca por espaços para permitir pesquisa de palavras separadas (ex: "dipirona concentração")
      final termos = termoBusca.trim().split(RegExp(r'\s+'));
      for (final t in termos) {
        query = query.or('codigo_siag.ilike.%$t%,descritivo_tecnico.ilike.%$t%,exemplos.ilike.%$t%');
      }
    }

    final response = await query
        .order('descritivo_tecnico', ascending: true)
        .range(offset, offset + limite - 1);

    return (response as List).map((json) => CatmedModel.fromJson(json)).toList();
  }

  /// Total de medicamentos (para KPI do dashboard).
  Future<int> getCount() async {
    final res = await _supabase.from('catmed_medicamentos').select('codigo_siag');
    return (res as List).length;
  }
}
