import 'package:flutter/material.dart';

import '../../modules/fornecedores/models/fornecedor_model.dart';
import '../../modules/fornecedores/repositories/fornecedor_repository.dart';
import 'fornecedor_form_screen.dart';

/// Lista de fornecedores cadastrados (CNPJ único). Abre formulário para novo/editar.
class FornecedoresScreen extends StatefulWidget {
  const FornecedoresScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends State<FornecedoresScreen> {
  final _repo = FornecedorRepository();
  List<FornecedorModel> _lista = [];
  bool _carregando = true;
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
      final list = await _repo.getAll();
      if (mounted) setState(() {
        _lista = list;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  void _abrirFormulario([FornecedorModel? fornecedor]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FornecedorFormScreen(
          fornecedor: fornecedor,
          onSalvo: _carregar,
        ),
      ),
    );
    if (mounted) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        title: const Text('Fornecedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregando ? null : _carregar,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _carregar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _lista.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business, size: 64, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7)),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum fornecedor cadastrado',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Toque em + para cadastrar. Você também pode cadastrar ao registrar uma ata (informando o CNPJ).',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => _abrirFormulario(),
                              icon: const Icon(Icons.add),
                              label: const Text('Cadastrar fornecedor'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _lista.length,
                      itemBuilder: (context, index) {
                        final f = _lista[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              f.razaoSocial ?? f.nomeFantasia ?? f.cnpj,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(f.cnpj),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _abrirFormulario(f),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
    );
  }
}
