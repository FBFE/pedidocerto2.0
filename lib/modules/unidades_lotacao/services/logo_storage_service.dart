import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço para armazenar logos (Governo e Unidades Hospitalares) no bucket do Supabase Storage.
/// Ao editar: deletar a logo antiga e subir a nova. Ao deletar: deletar a logo também.
class LogoStorageService {
  final _supabase = Supabase.instance.client;
  static const String bucketName = 'logos-unidades';

  /// Path da logo da unidade hospitalar no bucket.
  static String pathForUnidade(String unidadeId, String extension) {
    final ext = extension.startsWith('.') ? extension : '.$extension';
    return '$unidadeId/logo$ext';
  }

  /// Path da logo do governo no bucket (pasta governo/).
  static String pathForGoverno(String governoId, String extension) {
    final ext = extension.startsWith('.') ? extension : '.$extension';
    return 'governo/$governoId/logo$ext';
  }

  /// Upload da logo da unidade hospitalar. Retorna o path para gravar em logo_url.
  Future<String> upload(
      Uint8List bytes, String unidadeId, String extension) async {
    final path = pathForUnidade(unidadeId, extension);
    await _supabase.storage.from(bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  /// Upload da logo do governo. Retorna o path para gravar em logo_url.
  Future<String> uploadGoverno(
      Uint8List bytes, String governoId, String extension) async {
    final path = pathForGoverno(governoId, extension);
    await _supabase.storage.from(bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  /// Remove a logo do bucket. path = valor armazenado em logo_url (ex: "uuid/logo.png").
  Future<void> deleteByPath(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _supabase.storage.from(bucketName).remove([path]);
    } catch (_) {
      // Ignora se arquivo já não existir
    }
  }

  /// Retorna a URL pública para exibir a logo. path = valor de logo_url.
  String getPublicUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return _supabase.storage.from(bucketName).getPublicUrl(path);
  }
}
