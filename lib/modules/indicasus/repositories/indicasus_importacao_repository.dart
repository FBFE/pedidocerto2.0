import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/indicasus_importacao_model.dart';

class IndicasusImportacaoRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'indicasus_importacao';
  static const _tableHistorico = 'indicasus_importacao_historico';

  Future<List<IndicasusImportacaoModel>> getByUnidadeId(
      String unidadeId) async {
    final res = await _supabase
        .from(_table)
        .select()
        .eq('unidade_id', unidadeId)
        .order('ano_referencia', ascending: false);
    return (res as List)
        .map((e) => IndicasusImportacaoModel.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Busca importação existente pela unidade e ano (para sobrescrever na reimportação).
  Future<IndicasusImportacaoModel?> getByUnidadeIdAndAno(
      String unidadeId, int anoReferencia) async {
    final res = await _supabase
        .from(_table)
        .select()
        .eq('unidade_id', unidadeId)
        .eq('ano_referencia', anoReferencia)
        .maybeSingle();
    return res == null
        ? null
        : IndicasusImportacaoModel.fromJson(
            Map<String, dynamic>.from(res as Map));
  }

  Future<IndicasusImportacaoModel?> getById(String id) async {
    final res =
        await _supabase.from(_table).select().eq('id', id).maybeSingle();
    return res == null
        ? null
        : IndicasusImportacaoModel.fromJson(
            Map<String, dynamic>.from(res as Map));
  }

  Future<List<HistoricoIndicasusModel>> getHistorico(
      String importacaoId) async {
    final res = await _supabase
        .from(_tableHistorico)
        .select()
        .eq('importacao_id', importacaoId)
        .order('ocorrido_em', ascending: false);
    return (res as List)
        .map((e) => HistoricoIndicasusModel.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Insere nova importação e registra histórico 'criacao'.
  Future<IndicasusImportacaoModel> insert(IndicasusImportacaoModel m) async {
    final payload = {
      'unidade_id': m.unidadeId,
      'ano_referencia': m.anoReferencia,
      'nome_unidade_planilha': m.nomeUnidadePlanilha,
      'dados_json': m.linhas,
    };
    final res = await _supabase.from(_table).insert(payload).select().single();
    final inserted = IndicasusImportacaoModel.fromJson(
        Map<String, dynamic>.from(res as Map));
    if (inserted.id != null) {
      final email = _supabase.auth.currentUser?.email;
      await _supabase.from(_tableHistorico).insert({
        'importacao_id': inserted.id,
        'tipo': 'criacao',
        'descricao': 'Importação inicial - ano ${m.anoReferencia}',
        'usuario_email': email,
      });
    }
    return inserted;
  }

  /// Salva ou atualiza. Só sobrescreve se [sobrescreverSeMesmoAno] for true e já existir
  /// importação para a mesma unidade e mesmo ano de competência; caso contrário sempre insere.
  /// Use sobrescreverSeMesmoAno: false quando o ano não foi detectado na planilha (evita sobrescrever por engano).
  Future<IndicasusImportacaoModel> saveOrUpdate(
    IndicasusImportacaoModel m, {
    bool sobrescreverSeMesmoAno = true,
  }) async {
    if (!sobrescreverSeMesmoAno) {
      return insert(m);
    }
    final existente = await getByUnidadeIdAndAno(m.unidadeId, m.anoReferencia);
    if (existente != null && existente.id != null) {
      final atualizado = IndicasusImportacaoModel(
        id: existente.id,
        unidadeId: m.unidadeId,
        anoReferencia: m.anoReferencia,
        nomeUnidadePlanilha: m.nomeUnidadePlanilha,
        linhas: m.linhas,
        createdAt: existente.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
      return update(atualizado, tipoHistorico: 'reimportacao');
    }
    return insert(m);
  }

  Future<IndicasusImportacaoModel> update(IndicasusImportacaoModel m,
      {String tipoHistorico = 'edicao'}) async {
    if (m.id == null) throw StateError('Importação sem id');
    final payload = {
      'ano_referencia': m.anoReferencia,
      'nome_unidade_planilha': m.nomeUnidadePlanilha,
      'dados_json': m.linhas,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final res = await _supabase
        .from(_table)
        .update(payload)
        .eq('id', m.id!)
        .select()
        .single();
    final updated = IndicasusImportacaoModel.fromJson(
        Map<String, dynamic>.from(res as Map));
    final email = _supabase.auth.currentUser?.email;
    await _supabase.from(_tableHistorico).insert({
      'importacao_id': m.id,
      'tipo': tipoHistorico,
      'descricao': tipoHistorico == 'reimportacao'
          ? 'Reimportação - dados do ano ${m.anoReferencia} sobrescritos'
          : 'Dados atualizados',
      'usuario_email': email,
    });
    return updated;
  }

  Future<void> delete(String id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }
}
