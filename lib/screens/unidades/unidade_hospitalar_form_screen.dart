import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../modules/unidades_lotacao/models/secretaria_model.dart';
import '../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../modules/unidades_lotacao/repositories/secretaria_repository.dart';
import '../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';

class UnidadeHospitalarFormScreen extends StatefulWidget {
  const UnidadeHospitalarFormScreen({
    super.key,
    this.unidade,
    required this.onSaved,
  });

  final UnidadeHospitalarModel? unidade;
  final VoidCallback onSaved;

  @override
  State<UnidadeHospitalarFormScreen> createState() =>
      _UnidadeHospitalarFormScreenState();
}

class _UnidadeHospitalarFormScreenState
    extends State<UnidadeHospitalarFormScreen> {
  final _repo = UnidadeHospitalarRepository();
  final _secretariaRepo = SecretariaRepository();
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _siglaCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();

  List<SecretariaModel> _secretarias = [];
  String? _secretariaId;
  bool _carregandoSecretarias = true;
  bool _salvando = false;

  /// Logo nova selecionada (para criar ou substituir).
  Uint8List? _logoBytes;
  String? _logoExtension;
  String? _logoFileName;

  @override
  void initState() {
    super.initState();
    if (widget.unidade != null) {
      _nomeCtrl.text = widget.unidade!.nome;
      _siglaCtrl.text = widget.unidade!.sigla ?? '';
      _descricaoCtrl.text = widget.unidade!.descricao ?? '';
      _secretariaId = widget.unidade!.secretariaId;
    }
    _carregarSecretarias();
  }

  Future<void> _carregarSecretarias() async {
    setState(() => _carregandoSecretarias = true);
    try {
      final lista = await _secretariaRepo.getAll();
      setState(() {
        _secretarias = lista;
        if (_secretariaId == null && lista.isNotEmpty) {
          _secretariaId = lista.first.id;
        }
        _carregandoSecretarias = false;
      });
    } catch (_) {
      setState(() => _carregandoSecretarias = false);
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
    final ext = file.extension ?? 'png';
    setState(() {
      _logoBytes = file.bytes;
      _logoExtension = ext;
      _logoFileName = file.name;
    });
  }

  void _removerLogoSelecionada() {
    setState(() {
      _logoBytes = null;
      _logoExtension = null;
      _logoFileName = null;
    });
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_secretariaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma secretaria')),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final nome = _nomeCtrl.text.trim();
      if (widget.unidade != null && widget.unidade!.id != null) {
        final m = UnidadeHospitalarModel(
          id: widget.unidade!.id,
          secretariaId: _secretariaId!,
          nome: nome,
          cnes: widget.unidade!.cnes,
          cnpj: widget.unidade!.cnpj,
          nomeEmpresarial: widget.unidade!.nomeEmpresarial,
          naturezaJuridica: widget.unidade!.naturezaJuridica,
          cep: widget.unidade!.cep,
          logradouro: widget.unidade!.logradouro,
          numero: widget.unidade!.numero,
          bairro: widget.unidade!.bairro,
          municipio: widget.unidade!.municipio,
          uf: widget.unidade!.uf,
          complemento: widget.unidade!.complemento,
          classificacaoEstabelecimento:
              widget.unidade!.classificacaoEstabelecimento,
          gestao: widget.unidade!.gestao,
          tipoEstrutura: widget.unidade!.tipoEstrutura,
          latitude: widget.unidade!.latitude,
          longitude: widget.unidade!.longitude,
          responsavelTecnico: widget.unidade!.responsavelTecnico,
          telefone: widget.unidade!.telefone,
          email: widget.unidade!.email,
          cadastradoEm: widget.unidade!.cadastradoEm,
          atualizacaoBaseLocal: widget.unidade!.atualizacaoBaseLocal,
          ultimaAtualizacaoNacional: widget.unidade!.ultimaAtualizacaoNacional,
          horarioFuncionamento: widget.unidade!.horarioFuncionamento,
          dataDesativacao: widget.unidade!.dataDesativacao,
          motivoDesativacao: widget.unidade!.motivoDesativacao,
          logoUrl: widget.unidade!.logoUrl,
          sigla: _siglaCtrl.text.trim().isEmpty ? null : _siglaCtrl.text.trim(),
          descricao: _descricaoCtrl.text.trim().isEmpty
              ? null
              : _descricaoCtrl.text.trim(),
        );
        await _repo.update(
          m,
          logoBytes: _logoBytes,
          logoExtension: _logoExtension,
        );
      } else {
        final m = UnidadeHospitalarModel(
          secretariaId: _secretariaId!,
          nome: nome,
          sigla: _siglaCtrl.text.trim().isEmpty ? null : _siglaCtrl.text.trim(),
          descricao: _descricaoCtrl.text.trim().isEmpty
              ? null
              : _descricaoCtrl.text.trim(),
        );
        await _repo.insert(
          m,
          logoBytes: _logoBytes,
          logoExtension: _logoExtension,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salvo com sucesso')),
      );
      widget.onSaved();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _siglaCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unidade = widget.unidade;
    final logoAtualUrl =
        unidade?.logoUrl != null && unidade!.logoUrl!.isNotEmpty
            ? _repo.logoPublicUrl(unidade.logoUrl)
            : null;
    final temLogoAtual = logoAtualUrl != null && _logoBytes == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(unidade != null && unidade.id != null
            ? 'Editar unidade'
            : 'Nova unidade'),
      ),
      body: _carregandoSecretarias
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _secretariaId,
                      decoration:
                          const InputDecoration(labelText: 'Secretaria'),
                      items: _secretarias
                          .map((s) => DropdownMenuItem(
                              value: s.id, child: Text(s.nome)))
                          .toList(),
                      onChanged: (v) => setState(() => _secretariaId = v),
                      validator: (v) =>
                          v == null ? 'Selecione uma secretaria' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Nome da unidade'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _siglaCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Sigla (opcional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descricaoCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Descrição (opcional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    const Text('Logo',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (_logoBytes != null) ...[
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _logoBytes!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _logoFileName ?? 'logo.$_logoExtension',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: _removerLogoSelecionada,
                            child: const Text('Remover'),
                          ),
                        ],
                      ),
                    ] else if (temLogoAtual) ...[
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              logoAtualUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 80),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Logo atual (envie nova para substituir)'),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
