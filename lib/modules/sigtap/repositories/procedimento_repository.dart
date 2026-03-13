import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/procedimento_model.dart';

class ProcedimentoRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ProcedimentoSigtapModel>> getProcedimentos({
    String? termoBusca,
    String? grupo,
    String? subGrupo,
    String? formaOrganizacao,
    int limite = 50,
    int offset = 0,
  }) async {
    var query = _supabase.from('procedimentos_sigtap').select();

    if (termoBusca != null && termoBusca.isNotEmpty) {
      if (int.tryParse(termoBusca) != null) {
        query = query.or('co_procedimento.ilike.%$termoBusca%,no_procedimento.ilike.%$termoBusca%');
      } else {
        query = query.ilike('no_procedimento', '%$termoBusca%');
      }
    }

    if (grupo != null && grupo.isNotEmpty) {
      query = query.like('co_procedimento', '$grupo%');
      
      if (subGrupo != null && subGrupo.isNotEmpty) {
        query = query.like('co_procedimento', '$grupo$subGrupo%');
        
        if (formaOrganizacao != null && formaOrganizacao.isNotEmpty) {
          query = query.like('co_procedimento', '$grupo$subGrupo$formaOrganizacao%');
        }
      }
    }

    final response = await query.order('co_procedimento', ascending: true).range(offset, offset + limite - 1);

    return (response as List).map((e) => ProcedimentoSigtapModel.fromJson(e)).toList();
  }

  /// Total de procedimentos (para KPI do dashboard).
  Future<int> getCount() async {
    final res = await _supabase.from('procedimentos_sigtap').select('co_procedimento');
    return (res as List).length;
  }

  Future<ProcedimentoSigtapModel?> getProcedimentoPorCodigo(String codigo) async {
    final response = await _supabase
        .from('procedimentos_sigtap')
        .select()
        .eq('co_procedimento', codigo)
        .maybeSingle();

    if (response == null) return null;
    return ProcedimentoSigtapModel.fromJson(response);
  }
}
