import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class DfdStorageService {
  final _supabase = Supabase.instance.client;
  static const String bucketName = 'dfd-docs';

  String pathForEtp(String dfdId, String fileName) {
    // Pegar a extensão se houver
    final ext =
        fileName.contains('.') ? '.${fileName.split('.').last}' : '.pdf';
    return '$dfdId/etp$ext';
  }

  Future<String> uploadEtp(
      Uint8List bytes, String dfdId, String fileName) async {
    final path = pathForEtp(dfdId, fileName);
    await _supabase.storage.from(bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  Future<void> deleteByPath(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _supabase.storage.from(bucketName).remove([path]);
    } catch (_) {
      // Ignora se não existir
    }
  }

  String getPublicUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return _supabase.storage.from(bucketName).getPublicUrl(path);
  }
}
