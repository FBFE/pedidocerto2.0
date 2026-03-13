import 'package:flutter/material.dart';

import '../../services/background_preference_service.dart';
import '../../widgets/admin_background_upload.dart';
import '../../widgets/background_selector.dart';

/// Tela de configurações: plano de fundo e (para admin) upload de novos fundos.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({
    super.key,
    this.isAdmin = false,
    this.onBackgroundChanged,
  });

  final bool isAdmin;
  final VoidCallback? onBackgroundChanged;

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  String? _currentBackground;
  List<String> _customUrls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final path = await BackgroundPreferenceService.getBackgroundPath();
    final urls = await BackgroundPreferenceService.getCustomBackgroundUrls();
    if (mounted) {
      setState(() {
        _currentBackground = path;
        _customUrls = urls;
        _loading = false;
      });
    }
  }

  Future<void> _onBackgroundSelected(String pathOrUrl) async {
    if (pathOrUrl.isEmpty) {
      await BackgroundPreferenceService.setBackgroundPath(null);
      setState(() => _currentBackground = null);
    } else {
      await BackgroundPreferenceService.setBackgroundPath(pathOrUrl);
      setState(() => _currentBackground = pathOrUrl);
    }
    widget.onBackgroundChanged?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plano de fundo atualizado.')),
      );
    }
  }

  Future<void> _onUploadComplete(String url) async {
    await BackgroundPreferenceService.addCustomBackgroundUrl(url);
    await BackgroundPreferenceService.setBackgroundPath(url);
    await _load();
    widget.onBackgroundChanged?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Plano de fundo enviado e já aplicado. Volte à tela inicial para ver.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'O plano de fundo escolhido aparece na tela principal (lista de usuários). '
                    'Toque em uma miniatura abaixo para selecionar.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 16),
                  BackgroundSelector(
                    title: 'Escolha o plano de fundo',
                    currentBackground: _currentBackground,
                    onBackgroundSelected: _onBackgroundSelected,
                    backgrounds: [
                      const BackgroundItem(
                          pathOrUrl: '', isAsset: true, label: 'Nenhum'),
                      ..._customUrls.map((url) =>
                          BackgroundItem(pathOrUrl: url, isAsset: false)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AdminBackgroundUpload(
                    isAdmin: widget.isAdmin,
                    onUploadComplete: _onUploadComplete,
                  ),
                ],
              ),
            ),
    );
  }
}
