import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario_permissao_model.dart';

class UsuarioPermissaoRepository {
  final _supabase = Supabase.instance.client;
  static const _table = 'usuario_permissoes';

  Future<List<UsuarioPermissaoModel>> getByUsuarioId(String usuarioId) async {
    final res = await _supabase
        .from(_table)
        .select()
        .eq('usuario_id', usuarioId);
    return (res as List)
        .map((e) => UsuarioPermissaoModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Substitui todas as permissões do usuário pelas fornecidas.
  Future<void> setPermissoes(String usuarioId, List<UsuarioPermissaoModel> permissoes) async {
    final existentes = await getByUsuarioId(usuarioId);
    final idsRemover = existentes.where((e) => e.id != null).map((e) => e.id!).toList();
    if (idsRemover.isNotEmpty) {
      await _supabase.from(_table).delete().inFilter('id', idsRemover);
    }
    if (permissoes.isEmpty) return;
    final toInsert = permissoes
        .map((p) => {
              'usuario_id': usuarioId,
              'modulo': p.modulo,
              'adicionar': p.adicionar,
              'editar': p.editar,
              'excluir': p.excluir,
            })
        .toList();
    await _supabase.from(_table).insert(toInsert);
  }
}
