import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/renem_model.dart';

class RenemRepository {
  final _supabase = Supabase.instance.client;

  Future<List<RenemModel>> getEquipamentos({
    String? termoBusca,
    String? classificacaoFiltro,
    int limite = 50,
    int offset = 0,
  }) async {
    var query = _supabase.from('renem_equipamentos').select();

    if (classificacaoFiltro != null &&
        classificacaoFiltro.isNotEmpty &&
        classificacaoFiltro != 'Todas') {
      query = query.eq('classificacao', classificacaoFiltro);
    }

    if (termoBusca != null && termoBusca.trim().isNotEmpty) {
      final termos = termoBusca.trim().split(RegExp(r'\s+'));
      for (final t in termos) {
        query = query.or(
            'cod_item.ilike.%$t%,item.ilike.%$t%,definicao.ilike.%$t%,especificacao_sugerida.ilike.%$t%');
      }
    }

    final response = await query
        .order('item', ascending: true)
        .range(offset, offset + limite - 1);

    return (response as List).map((json) => RenemModel.fromJson(json)).toList();
  }

  Future<List<String>> getClassificacoes() async {
    final response = await _supabase
        .from('renem_equipamentos')
        .select('classificacao')
        .not('classificacao', 'is', null);

    final setClassificacoes = <String>{};
    for (var row in response as List) {
      final c = row['classificacao']?.toString().trim();
      if (c != null && c.isNotEmpty) {
        setClassificacoes.add(c);
      }
    }

    final lista = setClassificacoes.toList()..sort();
    return lista;
  }

  Future<void> updateClassificacao(String codItem, String novaClassificacao) async {
    await _supabase.from('renem_equipamentos').update({
      'classificacao': novaClassificacao,
      'data_atualizacao': DateTime.now().toIso8601String(),
    }).eq('cod_item', codItem);
  }
}
