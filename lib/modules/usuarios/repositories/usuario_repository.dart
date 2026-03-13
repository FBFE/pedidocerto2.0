import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario_model.dart';

class UsuarioRepository {
  final _supabase = Supabase.instance.client;
  final String _tableName = 'usuarios';

  Future<List<UsuarioModel>> getUsuarios() async {
    final response = await _supabase.from(_tableName).select();
    final list = response as List<dynamic>;
    return list
        .map((e) => UsuarioModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _verificarDuplicidade(UsuarioModel usuario) async {
    // Verifica email
    if (usuario.email != null && usuario.email!.trim().isNotEmpty) {
      final query = _supabase
          .from(_tableName)
          .select('id')
          .eq('email', usuario.email!.trim());
      final result =
          usuario.id != null ? await query.neq('id', usuario.id!) : await query;
      if ((result as List).isNotEmpty) {
        throw Exception('Já existe um usuário cadastrado com este e-mail.');
      }
    }

    // Verifica matricula
    if (usuario.matricula != null && usuario.matricula!.trim().isNotEmpty) {
      final query = _supabase
          .from(_tableName)
          .select('id')
          .eq('matricula', usuario.matricula!.trim());
      final result =
          usuario.id != null ? await query.neq('id', usuario.id!) : await query;
      if ((result as List).isNotEmpty) {
        throw Exception('Já existe um usuário cadastrado com esta matrícula.');
      }
    }

    // Verifica documento
    if (usuario.documento != null && usuario.documento!.trim().isNotEmpty) {
      final query = _supabase
          .from(_tableName)
          .select('id')
          .eq('documento', usuario.documento!.trim());
      final result =
          usuario.id != null ? await query.neq('id', usuario.id!) : await query;
      if ((result as List).isNotEmpty) {
        throw Exception('Já existe um usuário cadastrado com este documento.');
      }
    }
  }

  String _formatarNome(String nome) {
    if (nome.trim().isEmpty) return nome;
    return nome.trim().toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return '';
      // Exceções comuns que não devem ser capitalizadas (opcional, pode ajustar conforme necessidade)
      if (['da', 'de', 'do', 'das', 'dos', 'e'].contains(word)) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  UsuarioModel _formatarDados(UsuarioModel usuario) {
    return usuario.copyWith(
      nome: _formatarNome(usuario.nome),
      email: usuario.email?.trim().toLowerCase(),
    );
  }

  Future<UsuarioModel> createUsuario(UsuarioModel usuario) async {
    final usuarioFormatado = _formatarDados(usuario);
    await _verificarDuplicidade(usuarioFormatado);

    final response = await _supabase
        .from(_tableName)
        .insert(usuarioFormatado.toJson())
        .select()
        .single();
    return UsuarioModel.fromJson(response);
  }

  Future<UsuarioModel> updateUsuario(UsuarioModel usuario) async {
    if (usuario.id == null) {
      throw Exception('ID do usuário não pode ser nulo para atualização');
    }

    final usuarioFormatado = _formatarDados(usuario);
    await _verificarDuplicidade(usuarioFormatado);

    final response = await _supabase
        .from(_tableName)
        .update(usuarioFormatado.toJson())
        .eq('id', usuarioFormatado.id!)
        .select()
        .single();
    return UsuarioModel.fromJson(response);
  }

  Future<void> deleteUsuario(String id) async {
    await _supabase.from(_tableName).delete().eq('id', id);
  }

  Future<UsuarioModel?> getUsuarioById(String id) async {
    final response =
        await _supabase.from(_tableName).select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return UsuarioModel.fromJson(response);
  }

  Future<UsuarioModel?> getUsuarioByEmail(String email) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('email', email)
        .maybeSingle();
    if (response == null) return null;
    return UsuarioModel.fromJson(response);
  }

  /// Lista usuários com perfil pendente de aprovação (apenas administradores devem usar).
  Future<List<UsuarioModel>> getUsuariosPendentes() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('perfil_sistema', 'pendente_aprovacao')
        .order('nome');
    final list = response as List<dynamic>;
    return list
        .map((e) => UsuarioModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
