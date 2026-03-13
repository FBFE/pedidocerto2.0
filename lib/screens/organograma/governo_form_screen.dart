import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../modules/unidades_lotacao/models/governo_model.dart';
import '../../modules/unidades_lotacao/repositories/governo_repository.dart';

class GovernoFormScreen extends StatefulWidget {
  const GovernoFormScreen({
    super.key,
    this.governo,
    required this.onSaved,
  });

  final GovernoModel? governo;
  final VoidCallback onSaved;

  @override
  State<GovernoFormScreen> createState() => _GovernoFormScreenState();
}

class _GovernoFormScreenState extends State<GovernoFormScreen> {
  final _repo = GovernoRepository();
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _siglaCtrl = TextEditingController();

  bool _salvando = false;
  Uint8List? _logoBytes;
  String? _logoExtension;
  String? _logoFileName;

  @override
  void initState() {
    super.initState();
    if (widget.governo != null) {
      _nomeCtrl.text = widget.governo!.nome;
      _siglaCtrl.text = widget.governo!.sigla ?? '';
    }
  }

  Future<void> _escolherLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Não foi possível ler o arquivo. Tente outra imagem.')),
        );
      }
      return;
    }
    setState(() {
      _logoBytes = file.bytes;
      _logoExtension = file.extension ?? 'png';
      _logoFileName = file.name;
    });
  }

  void _removerLogo() {
    setState(() {
      _logoBytes = null;
      _logoExtension = null;
      _logoFileName = null;
    });
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _salvando = true);
    try {
      final nome = _nomeCtrl.text.trim();
      final sigla =
          _siglaCtrl.text.trim().isEmpty ? null : _siglaCtrl.text.trim();
      if (widget.governo != null) {
        await _repo.update(
          GovernoModel(
              id: widget.governo!.id,
              nome: nome,
              sigla: sigla,
              logoUrl: widget.governo!.logoUrl),
          logoBytes: _logoBytes,
          logoExtension: _logoExtension,
        );
      } else {
        await _repo.insert(
          GovernoModel(nome: nome, sigla: sigla),
          logoBytes: _logoBytes,
          logoExtension: _logoExtension,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Salvo com sucesso')));
      widget.onSaved();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _siglaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.governo;
    final logoUrl = g?.logoUrl != null && g!.logoUrl!.isNotEmpty
        ? _repo.logoPublicUrl(g.logoUrl!)
        : null;
    final temLogoAtual = logoUrl != null && _logoBytes == null;

    return Scaffold(
      appBar: AppBar(
          title: Text(g == null ? 'Cadastrar Governo' : 'Editar Governo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'A raiz do organograma. Cadastre o Governo primeiro, depois adicione Secretarias e a estrutura.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome do Governo'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _siglaCtrl,
                decoration:
                    const InputDecoration(labelText: 'Sigla (opcional)'),
              ),
              const SizedBox(height: 24),
              const Text('Logo', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_logoBytes != null) ...[
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_logoBytes!,
                          width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(_logoFileName ?? 'logo.$_logoExtension',
                            overflow: TextOverflow.ellipsis)),
                    TextButton(
                        onPressed: _removerLogo, child: const Text('Remover')),
                  ],
                ),
              ] else if (temLogoAtual) ...[
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(logoUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 80)),
                    ),
                    const SizedBox(width: 12),
                    const Text('Logo atual'),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _escolherLogo,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Substituir logo'),
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: _escolherLogo,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Selecionar arquivo da logo'),
                ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _salvando ? null : _salvar,
                child: _salvando
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
