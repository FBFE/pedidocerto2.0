import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../modules/fornecedores/models/fornecedor_model.dart';
import '../../modules/fornecedores/models/fornecedor_representante_model.dart';
import '../../modules/fornecedores/repositories/fornecedor_representante_repository.dart';
import '../../modules/fornecedores/repositories/fornecedor_repository.dart';
import '../../modules/fornecedores/services/brasil_api_cnpj_service.dart';
import '../../utils/input_formatters.dart';

/// Formulário de fornecedor: busca por CNPJ (BrasilAPI ou banco), dados da empresa e lista de representantes.
class FornecedorFormScreen extends StatefulWidget {
  const FornecedorFormScreen({
    super.key,
    this.fornecedor,
    this.onSalvo,
  });

  final FornecedorModel? fornecedor;
  final VoidCallback? onSalvo;

  @override
  State<FornecedorFormScreen> createState() => _FornecedorFormScreenState();
}

class _FornecedorFormScreenState extends State<FornecedorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = FornecedorRepository();
  final _repRepo = FornecedorRepresentanteRepository();

  final _cnpj = TextEditingController();
  final _razaoSocial = TextEditingController();
  final _nomeFantasia = TextEditingController();
  final _endereco = TextEditingController();
  final _contato = TextEditingController();
  final _situacao = TextEditingController();
  List<TextEditingController> _emailsEmpresa = [TextEditingController()];

  List<FornecedorRepresentanteModel> _representantes = [];
  bool _camposBloqueados = false;
  bool _buscandoCnpj = false;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _contato.addListener(() => setState(() {}));
    if (widget.fornecedor != null) {
      final f = widget.fornecedor!;
      _cnpj.text = formatarCnpjParaExibicao(f.cnpj);
      _razaoSocial.text = f.razaoSocial ?? '';
      _nomeFantasia.text = f.nomeFantasia ?? '';
      _endereco.text = f.endereco ?? '';
      _contato.text = formatarTelefoneParaExibicao(f.contato);
      _emailsEmpresa = _parseEmails(f.email);
      if (_emailsEmpresa.isEmpty) _emailsEmpresa = [TextEditingController()];
      _situacao.text = f.situacao ?? '';
      _camposBloqueados = true;
      _carregarRepresentantes();
    }
  }

  static List<TextEditingController> _parseEmails(String? s) {
    if (s == null || s.trim().isEmpty) return [TextEditingController()];
    final list = s.split(RegExp(r'[,;]')).map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
    if (list.isEmpty) return [TextEditingController()];
    return list.map((e) => TextEditingController(text: e)).toList();
  }

  void _adicionarEmailEmpresa() {
    setState(() => _emailsEmpresa.add(TextEditingController()));
  }

  void _removerEmailEmpresa(int index) {
    if (_emailsEmpresa.length <= 1) return;
    _emailsEmpresa[index].dispose();
    setState(() => _emailsEmpresa.removeAt(index));
  }

  List<String> get _emailsEmpresaTexto => _emailsEmpresa
      .map((c) => c.text.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _carregarRepresentantes() async {
    if (widget.fornecedor?.id == null) return;
    try {
      final list = await _repRepo.getByFornecedorId(widget.fornecedor!.id!);
      if (mounted) setState(() => _representantes = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _cnpj.dispose();
    _razaoSocial.dispose();
    _nomeFantasia.dispose();
    _endereco.dispose();
    _contato.dispose();
    for (final c in _emailsEmpresa) c.dispose();
    _situacao.dispose();
    super.dispose();
  }

  Future<void> _buscarCnpj() async {
    final cnpj = cnpjApenasDigitos(_cnpj.text);
    if (cnpj.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o CNPJ.')));
      return;
    }
    setState(() {
      _buscandoCnpj = true;
      _erro = null;
    });
    try {
      final existente = await _repo.getByCnpj(cnpj);
      if (existente != null && existente.id != widget.fornecedor?.id) {
        if (mounted) {
          setState(() => _buscandoCnpj = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este CNPJ já está cadastrado.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }
      if (existente != null) {
        _cnpj.text = formatarCnpjParaExibicao(existente.cnpj);
        _razaoSocial.text = existente.razaoSocial ?? '';
        _nomeFantasia.text = existente.nomeFantasia ?? '';
        _endereco.text = existente.endereco ?? '';
        _contato.text = formatarTelefoneParaExibicao(existente.contato);
        for (final c in _emailsEmpresa) c.dispose();
        _emailsEmpresa = _parseEmails(existente.email);
        if (_emailsEmpresa.isEmpty) _emailsEmpresa = [TextEditingController()];
        _situacao.text = existente.situacao ?? '';
        if (mounted) setState(() {
          _buscandoCnpj = false;
          _camposBloqueados = true;
        });
        return;
      }
      final dados = await BrasilApiCnpjService.buscarPorCnpj(cnpj);
      if (mounted) {
        setState(() {
          _buscandoCnpj = false;
          _camposBloqueados = true;
          _cnpj.text = formatarCnpjParaExibicao(dados['cnpj'] ?? _cnpj.text);
          _razaoSocial.text = dados['razao_social'] ?? '';
          _nomeFantasia.text = dados['nome_fantasia'] ?? '';
          _endereco.text = dados['endereco'] ?? '';
          _contato.text = formatarTelefoneParaExibicao(dados['contato']);
          for (final c in _emailsEmpresa) c.dispose();
          _emailsEmpresa = [TextEditingController()];
          _situacao.text = dados['situacao'] ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados preenchidos pela Receita Federal.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _buscandoCnpj = false;
          _erro = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cnpj = _cnpj.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cnpj.length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CNPJ deve ter 14 dígitos.')));
      return;
    }
    setState(() => _salvando = true);
    try {
      final f = FornecedorModel(
        id: widget.fornecedor?.id,
        cnpj: cnpj,
        razaoSocial: _razaoSocial.text.trim().isEmpty ? null : _razaoSocial.text.trim(),
        nomeFantasia: _nomeFantasia.text.trim().isEmpty ? null : _nomeFantasia.text.trim(),
        endereco: _endereco.text.trim().isEmpty ? null : _endereco.text.trim(),
        contato: _contato.text.trim().isEmpty ? null : _contato.text.trim(),
        email: _emailsEmpresaTexto.isEmpty ? null : _emailsEmpresaTexto.join(', '),
        situacao: _situacao.text.trim().isEmpty ? null : _situacao.text.trim(),
      );
      if (widget.fornecedor?.id != null) {
        await _repo.update(f);
      } else {
        final existente = await _repo.getByCnpj(cnpj);
        if (existente != null) {
          if (mounted) {
            setState(() => _salvando = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CNPJ já cadastrado.'), backgroundColor: Colors.orange));
          }
          return;
        }
        await _repo.insert(f);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fornecedor salvo.'), backgroundColor: Colors.green));
        widget.onSalvo?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _adicionarRepresentante() async {
    if (widget.fornecedor?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salve o fornecedor antes de adicionar representantes.')));
      return;
    }
    final result = await showDialog<FornecedorRepresentanteModel>(
      context: context,
      builder: (context) => _RepresentanteDialog(fornecedorId: widget.fornecedor!.id!, repRepo: _repRepo),
    );
    if (result != null && mounted) _carregarRepresentantes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fornecedor == null ? 'Novo fornecedor' : 'Editar fornecedor'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_erro!, style: const TextStyle(color: Colors.red)),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Empresa (fornecedor)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cnpj,
                            decoration: const InputDecoration(
                              labelText: 'CNPJ',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: widget.fornecedor != null,
                            inputFormatters: [CnpjInputFormatter()],
                            validator: (v) {
                              if (v == null || cnpjApenasDigitos(v).length != 14) return 'CNPJ deve ter 14 dígitos';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _buscandoCnpj || widget.fornecedor != null ? null : _buscarCnpj,
                          child: _buscandoCnpj ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Buscar'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E)),
                        ),
                      ],
                    ),
                    if (!_camposBloqueados)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('Informe o CNPJ e clique em Buscar para carregar os dados da empresa.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
                      )
                    else ...[
                      const SizedBox(height: 12),
                      _campo(_razaoSocial, 'Razão social', readOnly: true),
                      _campo(_nomeFantasia, 'Nome fantasia', readOnly: true),
                      _campo(_endereco, 'Endereço', maxLines: 2, readOnly: true),
                      _campo(_contato, 'Contato', readOnly: true, inputFormatters: [TelefoneInputFormatter()]),
                      if (_contato.text.trim().isNotEmpty && tipoTelefoneBR(_contato.text) != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(tipoTelefoneBR(_contato.text)!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ),
                      _campo(_situacao, 'Situação', readOnly: true),
                      ...List.generate(_emailsEmpresa.length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailsEmpresa[i],
                                decoration: InputDecoration(
                                  labelText: i == 0 ? 'E-mail da empresa' : 'Outro e-mail ${i + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                inputFormatters: [LowercaseInputFormatter()],
                              ),
                            ),
                            if (_emailsEmpresa.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _removerEmailEmpresa(i),
                                tooltip: 'Remover e-mail',
                              ),
                          ],
                        ),
                      )),
                      TextButton.icon(
                        onPressed: _adicionarEmailEmpresa,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar outro e-mail'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Representantes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (widget.fornecedor?.id != null)
                          TextButton.icon(
                            onPressed: _adicionarRepresentante,
                            icon: const Icon(Icons.add),
                            label: const Text('Novo'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_representantes.isEmpty)
                      Text(
                        widget.fornecedor?.id == null ? 'Salve o fornecedor para adicionar representantes.' : 'Nenhum representante. Toque em "Novo".',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      ..._representantes.map((r) => ListTile(
                            title: Text(r.nome ?? '—'),
                            subtitle: Text([if (r.cpf != null && r.cpf!.isNotEmpty) mascararCpf(r.cpf), if (r.email != null && r.email!.isNotEmpty) r.email].join(' · ')),
                            dense: true,
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(_salvando ? 'Salvando...' : 'Salvar'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, {int maxLines = 1, bool readOnly = false, List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        maxLines: maxLines,
        readOnly: readOnly,
        inputFormatters: inputFormatters,
      ),
    );
  }
}

class _RepresentanteDialog extends StatefulWidget {
  const _RepresentanteDialog({required this.fornecedorId, required this.repRepo});

  final String fornecedorId;
  final FornecedorRepresentanteRepository repRepo;

  @override
  State<_RepresentanteDialog> createState() => _RepresentanteDialogState();
}

class _RepresentanteDialogState extends State<_RepresentanteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _rg = TextEditingController();
  final _contato = TextEditingController();
  final _email = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _rg.dispose();
    _contato.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cpf = _cpf.text.trim();
    if (cpf.isNotEmpty) {
      final duplicado = await widget.repRepo.existeCpfNoFornecedor(widget.fornecedorId, cpf);
      if (duplicado && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Já existe um representante com este CPF neste fornecedor.'), backgroundColor: Colors.orange));
        return;
      }
    }
    setState(() => _salvando = true);
    try {
      final rep = FornecedorRepresentanteModel(
        fornecedorId: widget.fornecedorId,
        nome: _nome.text.trim().isEmpty ? null : _nome.text.trim(),
        cpf: cpf.isEmpty ? null : cpf,
        rg: _rg.text.trim().isEmpty ? null : _rg.text.trim(),
        contato: _contato.text.trim().isEmpty ? null : _contato.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      );
      await widget.repRepo.insert(rep);
      if (mounted) Navigator.of(context).pop(rep);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo representante'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome do representante *', border: OutlineInputBorder()),
                inputFormatters: [NomeTitleCaseInputFormatter()],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cpf,
                decoration: const InputDecoration(labelText: 'CPF', border: OutlineInputBorder()),
                inputFormatters: [CpfInputFormatter()],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rg,
                decoration: const InputDecoration(labelText: 'RG', border: OutlineInputBorder()),
                inputFormatters: [RgInputFormatter()],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contato,
                decoration: const InputDecoration(labelText: 'Contato *', border: OutlineInputBorder()),
                inputFormatters: [TelefoneInputFormatter()],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'E-mail *', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [LowercaseInputFormatter()],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Adicionar'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E)),
        ),
      ],
    );
  }
}
