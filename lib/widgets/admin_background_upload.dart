import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Bucket do Supabase Storage para planos de fundo. Crie no painel Supabase (público) se não existir.
const String kBackgroundsBucket = 'backgrounds';

/// Widget para administrador fazer upload de imagens como plano de fundo (Supabase Storage).
/// Usa bytes do file_picker para funcionar em web e mobile.
class AdminBackgroundUpload extends StatefulWidget {
  const AdminBackgroundUpload({
    super.key,
    this.onUploadComplete,
    this.isAdmin = true,
  });

  final void Function(String downloadUrl)? onUploadComplete;
  final bool isAdmin;

  @override
  State<AdminBackgroundUpload> createState() => _AdminBackgroundUploadState();
}

class _AdminBackgroundUploadState extends State<AdminBackgroundUpload> {
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  bool _isUploading = false;
  String? _downloadUrl;
  String? _error;

  Future<void> _pickFile() async {
    _error = null;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedBytes = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadToSupabase() async {
    if (_selectedBytes == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final ext = _selectedFileName?.split('.').last.toLowerCase() ?? 'png';
      final contentType = ext == 'webp'
          ? 'image/webp'
          : ext == 'png'
              ? 'image/png'
              : 'image/jpeg';
      final fileName = '${const Uuid().v4()}.$ext';

      await Supabase.instance.client.storage
          .from(kBackgroundsBucket)
          .uploadBinary(
            fileName,
            _selectedBytes!,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      final url = Supabase.instance.client.storage
          .from(kBackgroundsBucket)
          .getPublicUrl(fileName);
      setState(() {
        _downloadUrl = url;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload concluído! Use a URL em Configurações.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUploadComplete?.call(url);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload de plano de fundo (admin)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (_selectedBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _selectedBytes!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            if (_selectedBytes != null) const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.photo_library, size: 20),
              label: const Text('Selecionar imagem (galeria/arquivo)'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: (_isUploading || _selectedBytes == null)
                  ? null
                  : _uploadToSupabase,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: Text(
                  _isUploading ? 'Enviando...' : 'Subir como plano de fundo'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ],
            if (_downloadUrl != null) ...[
              const SizedBox(height: 12),
              Text(
                'URL (copie e use em "Escolha o plano de fundo"):',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              SelectableText(_downloadUrl!,
                  style: const TextStyle(fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}
