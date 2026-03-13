import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/custo_unidade_importacao_model.dart';

class CustoUnidadeImportacaoRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'custo_unidade_importacao';
  static const _tableHistorico = 'custo_unidade_importacao_historico';

  Future<List<CustoUnidadeImportacaoModel>> getByUnidadeId(
      String unidadeId) async {
    final res = await _supabase
        .from(_table)
        .select()
        .eq('unidade_id', unidadeId)
        .order('ano_competencia', ascending: false);
    return (res as List)
        .map((e) => CustoUnidadeImportacaoModel.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CustoUnidadeImportacaoModel?> getById(String id) async {
    final res =
        await _supabase.from(_table).select().eq('id', id).maybeSingle();
    return res == null
        ? null
        : CustoUnidadeImportacaoModel.fromJson(
            Map<String, dynamic>.from(res as Map));
  }

  Future<List<HistoricoImportacaoModel>> getHistorico(
      String importacaoId) async {
    final res = await _supabase
        .from(_tableHistorico)
        .select()
        .eq('importacao_id', importacaoId)
        .order('ocorrido_em', ascending: false);
    return (res as List)
        .map((e) => HistoricoImportacaoModel.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CustoUnidadeImportacaoModel> insert(
      CustoUnidadeImportacaoModel m) async {
    final payload = {
      'unidade_id': m.unidadeId,
      'ano_competencia': m.anoCompetencia,
      'nome_unidade_planilha': m.nomeUnidadePlanilha,
      'dados_json': m.linhas.map((e) => e.toJson()).toList(),
    };
    final res = await _supabase.from(_table).insert(payload).select().single();
    final inserted = CustoUnidadeImportacaoModel.fromJson(
        Map<String, dynamic>.from(res as Map));
    if (inserted.id != null) {
      final email = _supabase.auth.currentUser?.email;
      await _supabase.from(_tableHistorico).insert({
        'importacao_id': inserted.id,
        'tipo': 'criacao',
        'descricao': 'Importação inicial - ano ${m.anoCompetencia}',
        'usuario_email': email,
      });
    }
    return inserted;
  }

  Future<CustoUnidadeImportacaoModel> update(
      CustoUnidadeImportacaoModel m) async {
    if (m.id == null) throw StateError('Importação sem id');
    final payload = {
      'ano_competencia': m.anoCompetencia,
      'nome_unidade_planilha': m.nomeUnidadePlanilha,
      'dados_json': m.linhas.map((e) => e.toJson()).toList(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final res = await _supabase
        .from(_table)
        .update(payload)
        .eq('id', m.id!)
        .select()
        .single();
    final updated = CustoUnidadeImportacaoModel.fromJson(
        Map<String, dynamic>.from(res as Map));
    final email = _supabase.auth.currentUser?.email;
    await _supabase.from(_tableHistorico).insert({
      'importacao_id': m.id,
      'tipo': 'edicao',
      'descricao': 'Dados atualizados',
      'usuario_email': email,
    });
    return updated;
  }

  Future<void> delete(String id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }
}
