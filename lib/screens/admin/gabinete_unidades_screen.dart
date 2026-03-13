import 'package:flutter/material.dart';

import '../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';
import '../../modules/unidades_lotacao/repositories/gabinete_gestao_hospitalar_repository.dart';
import '../../widgets/constrained_content.dart';

/// Tela (somente administradores) para escolher quais unidades hospitalares
/// estão sob gestão do Gabinete do Secretário Adjunto de Gestão Hospitalar.
/// Usuários desse gabinete verão apenas essas unidades na listagem.
class GabineteUnidadesScreen extends StatefulWidget {
  const GabineteUnidadesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<GabineteUnidadesScreen> createState() => _GabineteUnidadesScreenState();
}

class _GabineteUnidadesScreenState extends State<GabineteUnidadesScreen> {
  final _unidadeRepo = UnidadeHospitalarRepository();
  final _gabineteRepo = GabineteGestaoHospitalarRepository();

  List<UnidadeHospitalarModel> _todas = [];
  Set<String> _selecionados = {};
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final futures = [
        _unidadeRepo.getAll(),
        _gabineteRepo.getUnidadeIds(),
      ];
      final results = await Future.wait(futures);
      final todas = results[0] as List<UnidadeHospitalarModel>;
      final ids = results[1] as List<String>;
      setState(() {
        _todas = todas;
        _selecionados = ids.toSet();
        _carregando = false;
      });
    } catch (e, st) {
      setState(() {
        _erro = '$e\n$st';
        _carregando = false;
      });
    }
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await _gabineteRepo.setUnidadeIds(_selecionados.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidades do Gabinete atualizadas.')),
        );
        setState(() => _salvando = false);
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _erro = '$e\n$st';
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => widget.onBack!(),
              )
            : null,
        title: const Text('Unidades do Gabinete – Gestão Hospitalar'),
      ),
      body: ConstrainedContent(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Erro ao carregar', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: SelectableText(_erro!, style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _carregar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                        child: Text(
                          'Selecione as unidades sob gestão do Gabinete do Secretário Adjunto de Gestão Hospitalar. '
                          'Usuários desse gabinete verão apenas estas unidades em Unidades Hospitalares.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _todas.length,
                          itemBuilder: (context, i) {
                            final u = _todas[i];
                            final id = u.id ?? '';
                            final selected = _selecionados.contains(id);
                            return CheckboxListTile(
                              value: selected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selecionados.add(id);
                                  } else {
                                    _selecionados.remove(id);
                                  }
                                });
                              },
                              title: Text(u.nome),
                              subtitle: u.sigla != null && u.sigla!.isNotEmpty
                                  ? Text(u.sigla!, style: Theme.of(context).textTheme.bodySmall)
                                  : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _salvando ? null : _salvar,
                        icon: _salvando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_salvando ? 'Salvando...' : 'Salvar seleção'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
      ),
    );
  }
}
