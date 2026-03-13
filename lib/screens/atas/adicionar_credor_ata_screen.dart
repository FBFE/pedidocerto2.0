import 'package:flutter/material.dart';

import '../../modules/atas/models/ata_credor_model.dart';
import '../../modules/atas/repositories/ata_repository.dart';
import '../../modules/fornecedores/models/fornecedor_model.dart';
import '../../modules/fornecedores/models/fornecedor_representante_model.dart';
import '../../modules/fornecedores/repositories/fornecedor_representante_repository.dart';
import '../../modules/fornecedores/repositories/fornecedor_repository.dart';
import '../../utils/input_formatters.dart';

/// Tela para adicionar um credor (fornecedor) a uma ata já existente.
/// Exclui da lista os fornecedores já vinculados à ata (evita duplicar).
class AdicionarCredorAtaScreen extends StatefulWidget {
  const AdicionarCredorAtaScreen({
    super.key,
    required this.ataId,
    required this.numeroAta,
    required this.cnpjsJaNaAta,
  });

  final String ataId;
  final String numeroAta;
  /// CNPJs (apenas dígitos) dos credores já cadastrados nesta ata.
  final List<String> cnpjsJaNaAta;

  @override
  State<AdicionarCredorAtaScreen> createState() => _AdicionarCredorAtaScreenState();
}

class _AdicionarCredorAtaScreenState extends State<AdicionarCredorAtaScreen> {
  final _repo = AtaRepository();
  final _fornecedorRepo = FornecedorRepository();
  final _representanteRepo = FornecedorRepresentanteRepository();

  List<FornecedorModel> _fornecedores = [];
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
      final todos = await _fornecedorRepo.getAll();
      final setCnpj = widget.cnpjsJaNaAta.map((c) => cnpjApenasDigitos(c).padLeft(14, '0')).toSet();
      final filtrados = todos.where((f) {
        final c = cnpjApenasDigitos(f.cnpj);
        if (c.length != 14) return true;
        return !setCnpj.contains(c);
      }).toList();
      if (mounted) {
        setState(() {
          _fornecedores = filtrados;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _carregando = false;
        });
      }
    }
  }

  Future<void> _escolherRepresentanteEAdicionar(FornecedorModel f) async {
    List<FornecedorRepresentanteModel> reps = [];
    try {
      reps = await _representanteRepo.getByFornecedorId(f.id!);
    } catch (_) {}
    if (!mounted) return;

    FornecedorRepresentanteModel? repEscolhido;
    if (reps.isEmpty) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sem representante'),
          content: Text(
            '${f.razaoSocial ?? f.nomeFantasia ?? "Fornecedor"} não possui representante cadastrado. Deseja adicionar como credor mesmo assim?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sim')),
          ],
        ),
      );
      if (confirmar != true) return;
    } else if (reps.length == 1) {
      repEscolhido = reps.first;
    } else {
      repEscolhido = await showDialog<FornecedorRepresentanteModel>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Escolher representante'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: reps.length,
              itemBuilder: (_, i) {
                final r = reps[i];
                return ListTile(
                  title: Text(r.nome ?? '—'),
                  subtitle: r.cpf != null && r.cpf!.isNotEmpty ? Text('CPF: ${mascararCpf(r.cpf!)}') : null,
                  onTap: () => Navigator.pop(ctx, r),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ],
        ),
      );
      if (repEscolhido == null) return;
    }

    final cnpjLimpo = cnpjApenasDigitos(f.cnpj);
    final credor = AtaCredorModel(
      ataId: widget.ataId,
      fornecedorId: f.id,
      representanteId: repEscolhido?.id,
      cnpj: cnpjLimpo.isEmpty ? null : cnpjLimpo,
      razaoSocial: f.razaoSocial,
      nomeFantasia: f.nomeFantasia,
      endereco: f.endereco,
      contato: f.contato,
      situacao: f.situacao,
      representanteNome: repEscolhido?.nome,
      representanteCpf: repEscolhido?.cpf,
      representanteRg: repEscolhido?.rg,
      representanteContato: repEscolhido?.contato,
      representanteEmail: repEscolhido?.email,
    );
    try {
      await _repo.addCredorToAta(ataId: widget.ataId, credor: credor);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credor adicionado à ata.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar credor – ${widget.numeroAta}'),
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
                        FilledButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : _fornecedores.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business_center, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Todos os fornecedores já estão nesta ata ou não há fornecedores cadastrados.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _fornecedores.length,
                      itemBuilder: (context, i) {
                        final f = _fornecedores[i];
                        final razao = f.razaoSocial ?? f.nomeFantasia ?? '—';
                        final cnpj = formatarCnpjParaExibicao(f.cnpj);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(razao, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(cnpj),
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: () => _escolherRepresentanteEAdicionar(f),
                          ),
                        );
                      },
                    ),
    );
  }
}
