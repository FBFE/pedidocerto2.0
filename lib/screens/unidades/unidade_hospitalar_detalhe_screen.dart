import 'package:flutter/material.dart';

import '../../modules/unidades_lotacao/models/secretaria_model.dart';
import '../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../modules/unidades_lotacao/repositories/secretaria_repository.dart';
import '../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';
import '../../widgets/constrained_content.dart';
import 'custo_unidade/dados_unidade_screen.dart';
import 'unidade_hospitalar_form_screen.dart';

/// Página de detalhe da unidade hospitalar (somente leitura). Possui botão para abrir a edição.
class UnidadeHospitalarDetalheScreen extends StatefulWidget {
  const UnidadeHospitalarDetalheScreen({
    super.key,
    required this.unidade,
    this.onAtualizado,
  });

  final UnidadeHospitalarModel unidade;
  final VoidCallback? onAtualizado;

  @override
  State<UnidadeHospitalarDetalheScreen> createState() =>
      _UnidadeHospitalarDetalheScreenState();
}

class _UnidadeHospitalarDetalheScreenState
    extends State<UnidadeHospitalarDetalheScreen> {
  final _unidadeRepo = UnidadeHospitalarRepository();
  final _secretariaRepo = SecretariaRepository();

  UnidadeHospitalarModel? _unidade;
  SecretariaModel? _secretaria;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _unidade = widget.unidade;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      SecretariaModel? sec;
      if (widget.unidade.secretariaId.isNotEmpty) {
        sec = await _secretariaRepo.getById(widget.unidade.secretariaId);
      }
      UnidadeHospitalarModel? u = _unidade;
      if (widget.unidade.id != null) {
        u = await _unidadeRepo.getById(widget.unidade.id!);
      }
      setState(() {
        _secretaria = sec;
        _unidade = u ?? widget.unidade;
        _carregando = false;
      });
    } catch (_) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _abrirDadosUnidade() async {
    final u = _unidade ?? widget.unidade;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DadosUnidadeScreen(
          unidade: u,
          onAtualizado: widget.onAtualizado,
        ),
      ),
    );
  }

  Future<void> _abrirEdicao() async {
    if (_unidade == null) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => UnidadeHospitalarFormScreen(
          unidade: _unidade,
          onSaved: () {
            widget.onAtualizado?.call();
            _carregarDados();
          },
        ),
      ),
    );
    if (ok == true && mounted) {
      widget.onAtualizado?.call();
      _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _unidade ?? widget.unidade;
    final logoUrl = u.logoUrl != null && u.logoUrl!.isNotEmpty
        ? _unidadeRepo.logoPublicUrl(u.logoUrl)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(u.nome),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Dados da unidade (importar planilha)',
            onPressed: _carregando ? null : _abrirDadosUnidade,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar unidade',
            onPressed: _carregando ? null : _abrirEdicao,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SizedBox.expand(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Logo da unidade: tela inteira, centralizada, preenchida, 75% transparência
                  if (logoUrl != null && logoUrl.isNotEmpty)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.25,
                        child: Image.network(
                          logoUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  // Conteúdo em cima, com fundo levemente opaco para legibilidade
                  SingleChildScrollView(
                    child: ConstrainedContent(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _titulo('Informações gerais'),
                            _info('Nome', u.nome),
                            if (u.sigla != null && u.sigla!.isNotEmpty)
                              _info('Sigla', u.sigla!),
                            _info('Secretaria', _secretaria?.nome ?? '—'),
                            if (u.descricao != null &&
                                u.descricao!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _info('Descrição', u.descricao!),
                            ],
                            if (u.cnes != null && u.cnes!.isNotEmpty)
                              _info('CNES', u.cnes!),
                            if (u.municipio != null && u.municipio!.isNotEmpty)
                              _info('Município', u.municipio!),
                            if (u.telefone != null && u.telefone!.isNotEmpty)
                              _info('Telefone', u.telefone!),
                            if (u.email != null && u.email!.isNotEmpty)
                              _info('E-mail', u.email!),
                            const SizedBox(height: 32),
                            FilledButton.icon(
                              onPressed: _abrirEdicao,
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar unidade'),
                              style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _titulo(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
