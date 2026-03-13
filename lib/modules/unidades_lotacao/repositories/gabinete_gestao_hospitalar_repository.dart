import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositório da configuração "unidades sob gestão do Gabinete do Secretário Adjunto de Gestão Hospitalar".
///
/// No Supabase, crie a tabela (uma vez):
/// ```sql
/// create table if not exists gabinete_gestao_hospitalar_unidades (
///   unidade_id uuid primary key references unidades_hospitalares(id) on delete cascade
/// );
/// ```
class GabineteGestaoHospitalarRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'gabinete_gestao_hospitalar_unidades';

  /// Retorna a lista de IDs de unidades configuradas como sob gestão do Gabinete.
  Future<List<String>> getUnidadeIds() async {
    final res = await _supabase.from(_table).select('unidade_id');
    return (res as List)
        .map((e) => e is Map ? e['unidade_id'] as String? : null)
        .whereType<String>()
        .toList();
  }

  /// Substitui a configuração pelas unidades indicadas.
  /// (Delete com WHERE é exigido pelo PostgREST; por isso buscamos os IDs atuais antes.)
  Future<void> setUnidadeIds(List<String> unidadeIds) async {
    final atuais = await getUnidadeIds();
    if (atuais.isNotEmpty) {
      await _supabase.from(_table).delete().inFilter('unidade_id', atuais);
    }
    if (unidadeIds.isEmpty) return;
    await _supabase.from(_table).insert(
      unidadeIds.map((id) => {'unidade_id': id}).toList(),
    );
  }
}
