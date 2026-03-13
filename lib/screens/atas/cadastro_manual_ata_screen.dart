import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../modules/atas/models/ata_credor_model.dart';
import '../../modules/atas/models/ata_model.dart';
import '../../modules/atas/repositories/ata_repository.dart';
import '../../modules/fornecedores/models/fornecedor_model.dart';
import '../../modules/fornecedores/models/fornecedor_representante_model.dart';
import '../../modules/fornecedores/repositories/fornecedor_representante_repository.dart';
import '../../modules/fornecedores/repositories/fornecedor_repository.dart';
import '../../modules/fornecedores/services/brasil_api_cnpj_service.dart';
import '../../modules/usuarios/models/usuario_model.dart';
import '../../utils/input_formatters.dart';
import 'selecionar_itens_ata_screen.dart';

/// Cadastro manual da ata: dados gerais, empresa, representante e tipo.
/// Após salvar, abre a tela de seleção de itens do banco (medicamento/material/opme).
class CadastroManualAtaScreen extends StatefulWidget {
  const CadastroManualAtaScreen({
    super.key,
    this.usuarioLogado,
  });

  final UsuarioModel? usuarioLogado;

  @override
  State<CadastroManualAtaScreen> createState() => _CadastroManualAtaScreenState();
}

class _CadastroManualAtaScreenState extends State<CadastroManualAtaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AtaRepository();
  final _fornecedorRepo = FornecedorRepository();
  final _representanteRepo = FornecedorRepresentanteRepository();

  final _numeroAta = TextEditingController();
  final _numeroModalidade = TextEditingController();
  final _detalhamento = TextEditingController();
  final _anoCompetencia = TextEditingController();
  final _numeroProcesso = TextEditingController();
  final _linkProcesso = TextEditingController();

  final _cnpj = TextEditingController();
  final _razaoSocial = TextEditingController();
  final _nomeFantasia = TextEditingController();
  final _endereco = TextEditingController();
  final _contato = TextEditingController();
  final _situacao = TextEditingController();

  final _representanteNome = TextEditingController();
  final _representanteCpf = TextEditingController();
  final _representanteRg = TextEditingController();
  final _representanteContato = TextEditingController();
  final _representanteEmail = TextEditingController();

  String? _modalidade;
  DateTime? _vigenciaInicio;
  DateTime? _vigenciaFim;
  final _statusVigencia = TextEditingController();
  String? _tipoAta;

  FornecedorModel? _fornecedorCarregado;
  List<FornecedorRepresentanteModel> _representantesFornecedor = [];
  FornecedorRepresentanteModel? _representanteSelecionado;
  bool _empresaSomenteLeitura = false;
  bool _buscandoCnpj = false;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _contato.addListener(() => setState(() {}));
    _representanteContato.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _numeroAta.dispose();
    _numeroModalidade.dispose();
    _detalhamento.dispose();
    _anoCompetencia.dispose();
    _numeroProcesso.dispose();
    _linkProcesso.dispose();
    _cnpj.dispose();
    _razaoSocial.dispose();
    _nomeFantasia.dispose();
    _endereco.dispose();
    _contato.dispose();
    _situacao.dispose();
    _representanteNome.dispose();
    _representanteCpf.dispose();
    _representanteRg.dispose();
    _representanteContato.dispose();
    _representanteEmail.dispose();
    _statusVigencia.dispose();
    super.dispose();
  }

  String _formatDataHora(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  Future<void> _buscarCnpjAta() async {
    final cnpj = cnpjApenasDigitos(_cnpj.text);
    if (cnpj.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o CNPJ.')));
      return;
    }
    setState(() {
      _buscandoCnpj = true;
      _erro = null;
      _fornecedorCarregado = null;
      _representantesFornecedor = [];
      _representanteSelecionado = null;
      _empresaSomenteLeitura = false;
    });
    try {
      final existente = await _fornecedorRepo.getByCnpj(cnpj);
      if (existente != null) {
        _fornecedorCarregado = existente;
        _razaoSocial.text = existente.razaoSocial ?? '';
        _nomeFantasia.text = existente.nomeFantasia ?? '';
        _endereco.text = existente.endereco ?? '';
        _contato.text = formatarTelefoneParaExibicao(existente.contato);
        _situacao.text = existente.situacao ?? '';
        _cnpj.text = formatarCnpjParaExibicao(existente.cnpj);
        _empresaSomenteLeitura = true;
        final reps = await _representanteRepo.getByFornecedorId(existente.id!);
        if (mounted) setState(() {
          _representantesFornecedor = reps;
          _buscandoCnpj = false;
        });
        return;
      }
      final dados = await BrasilApiCnpjService.buscarPorCnpj(cnpj);
      if (mounted) setState(() {
        _buscandoCnpj = false;
        _cnpj.text = formatarCnpjParaExibicao(dados['cnpj'] ?? _cnpj.text);
        _razaoSocial.text = dados['razao_social'] ?? '';
        _nomeFantasia.text = dados['nome_fantasia'] ?? '';
        _endereco.text = dados['endereco'] ?? '';
        _contato.text = formatarTelefoneParaExibicao(dados['contato']);
        _situacao.text = dados['situacao'] ?? '';
        _empresaSomenteLeitura = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados preenchidos. Salve a ata para registrar o fornecedor.'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) setState(() {
        _buscandoCnpj = false;
        _erro = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _adicionarRepresentanteNaAta() async {
    if (_fornecedorCarregado?.id == null) return;
    final nome = _representanteNome.text.trim();
    final cpf = _representanteCpf.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome do representante obrigatório.')));
      return;
    }
    if (cpf.isNotEmpty) {
      final duplicado = await _representanteRepo.existeCpfNoFornecedor(_fornecedorCarregado!.id!, cpf);
      if (duplicado && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Já existe representante com este CPF.'), backgroundColor: Colors.orange));
        return;
      }
    }
    try {
      final rep = FornecedorRepresentanteModel(
        fornecedorId: _fornecedorCarregado!.id!,
        nome: nome,
        cpf: cpf.isEmpty ? null : cpf,
        rg: _representanteRg.text.trim().isEmpty ? null : _representanteRg.text.trim(),
        contato: _representanteContato.text.trim().isEmpty ? null : _representanteContato.text.trim(),
        email: _representanteEmail.text.trim().isEmpty ? null : _representanteEmail.text.trim(),
      );
      final inserido = await _representanteRepo.insert(rep);
      final lista = await _representanteRepo.getByFornecedorId(_fornecedorCarregado!.id!);
      if (mounted) setState(() {
        _representantesFornecedor = lista;
        _representanteSelecionado = inserido;
        _representanteNome.clear();
        _representanteCpf.clear();
        _representanteRg.clear();
        _representanteContato.clear();
        _representanteEmail.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Representante adicionado.'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _salvar() async {
    _erro = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_modalidade == null || _modalidade!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a modalidade.')),
      );
      return;
    }
    if (_tipoAta == null || _tipoAta!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo da ata (medicamento, material ou opme).')),
      );
      return;
    }
    if (!_empresaSomenteLeitura) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O fornecedor é obrigatório. Informe o CNPJ e clique em Buscar para carregar os dados da empresa.')),
      );
      return;
    }

    final cnpjLimpo = cnpjApenasDigitos(_cnpj.text);
    if (cnpjLimpo.length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CNPJ da empresa deve ter 14 dígitos.')));
      return;
    }
    if (_representanteSelecionado == null &&
        (_representanteNome.text.trim().isEmpty ||
            _representanteCpf.text.trim().isEmpty ||
            _representanteRg.text.trim().isEmpty ||
            _representanteContato.text.trim().isEmpty ||
            _representanteEmail.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os dados do representante ou selecione um da lista.')),
      );
      return;
    }

    setState(() => _salvando = true);

    String? fornecedorId = _fornecedorCarregado?.id;
    String? representanteId = _representanteSelecionado?.id;

    if (fornecedorId == null) {
      try {
        final existente = await _fornecedorRepo.getByCnpj(cnpjLimpo);
        if (existente != null) {
          fornecedorId = existente.id;
          if (_representanteSelecionado == null && _representanteNome.text.trim().isNotEmpty) {
            final rep = FornecedorRepresentanteModel(
              fornecedorId: existente.id!,
              nome: _representanteNome.text.trim(),
              cpf: _representanteCpf.text.trim().isEmpty ? null : _representanteCpf.text.trim(),
              rg: _representanteRg.text.trim().isEmpty ? null : _representanteRg.text.trim(),
              contato: _representanteContato.text.trim().isEmpty ? null : _representanteContato.text.trim(),
              email: _representanteEmail.text.trim().isEmpty ? null : _representanteEmail.text.trim(),
            );
            final duplicado = rep.cpf != null ? await _representanteRepo.existeCpfNoFornecedor(existente.id!, rep.cpf!) : false;
            if (!duplicado) {
              final inserido = await _representanteRepo.insert(rep);
              representanteId = inserido.id;
            }
          }
        } else {
          final f = FornecedorModel(
            cnpj: cnpjLimpo,
            razaoSocial: _razaoSocial.text.trim().isEmpty ? null : _razaoSocial.text.trim(),
            nomeFantasia: _nomeFantasia.text.trim().isEmpty ? null : _nomeFantasia.text.trim(),
            endereco: _endereco.text.trim().isEmpty ? null : _endereco.text.trim(),
            contato: _contato.text.trim().isEmpty ? null : _contato.text.trim(),
            situacao: _situacao.text.trim().isEmpty ? null : _situacao.text.trim(),
          );
          final inserido = await _fornecedorRepo.insert(f);
          fornecedorId = inserido.id;
          if (_representanteNome.text.trim().isNotEmpty) {
            final rep = FornecedorRepresentanteModel(
              fornecedorId: inserido.id!,
              nome: _representanteNome.text.trim(),
              cpf: _representanteCpf.text.trim().isEmpty ? null : _representanteCpf.text.trim(),
              rg: _representanteRg.text.trim().isEmpty ? null : _representanteRg.text.trim(),
              contato: _representanteContato.text.trim().isEmpty ? null : _representanteContato.text.trim(),
              email: _representanteEmail.text.trim().isEmpty ? null : _representanteEmail.text.trim(),
            );
            final r = await _representanteRepo.insert(rep);
            representanteId = r.id;
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _salvando = false);
          _erro = e.toString();
        }
        return;
      }
    } else {
      representanteId = _representanteSelecionado?.id;
    }
    if (fornecedorId != null && representanteId == null && _representanteNome.text.trim().isNotEmpty) {
      try {
        final rep = FornecedorRepresentanteModel(
          fornecedorId: fornecedorId,
          nome: _representanteNome.text.trim(),
          cpf: _representanteCpf.text.trim().isEmpty ? null : _representanteCpf.text.trim(),
          rg: _representanteRg.text.trim().isEmpty ? null : _representanteRg.text.trim(),
          contato: _representanteContato.text.trim().isEmpty ? null : _representanteContato.text.trim(),
          email: _representanteEmail.text.trim().isEmpty ? null : _representanteEmail.text.trim(),
        );
        final duplicado = rep.cpf != null ? await _representanteRepo.existeCpfNoFornecedor(fornecedorId, rep.cpf!) : false;
        if (!duplicado) {
          final inserido = await _representanteRepo.insert(rep);
          representanteId = inserido.id;
        }
      } catch (_) {}
    }

    final user = Supabase.instance.client.auth.currentUser;
    String? nomeCadastrou = widget.usuarioLogado?.nome ?? user?.userMetadata?['nome'] as String?;
    String? matriculaCadastrou = widget.usuarioLogado?.matricula;

    final dataHoraRegistro = DateTime.now();

    final ata = AtaModel(
      usuarioCadastrouNome: nomeCadastrou,
      usuarioCadastrouMatricula: matriculaCadastrou,
      dataHoraRegistro: dataHoraRegistro,
      numeroAta: _numeroAta.text.trim(),
      modalidade: _modalidade,
      numeroModalidade: _numeroModalidade.text.trim().isEmpty ? null : _numeroModalidade.text.trim(),
      vigenciaInicio: _vigenciaInicio,
      vigenciaFim: _vigenciaFim,
      statusVigencia: _statusVigencia.text.trim().isEmpty ? null : _statusVigencia.text.trim(),
      detalhamento: _detalhamento.text.trim().isEmpty ? null : _detalhamento.text.trim(),
      anoCompetencia: int.tryParse(_anoCompetencia.text.trim()),
      numeroProcessoAdministrativo: _numeroProcesso.text.trim().isEmpty ? null : _numeroProcesso.text.trim(),
      linkProcessoAdministrativo: _linkProcesso.text.trim().isEmpty ? null : _linkProcesso.text.trim(),
      tipoAta: _tipoAta,
    );

    final repSel = _representanteSelecionado;
    final credor = AtaCredorModel(
      ataId: '',
      fornecedorId: fornecedorId,
      representanteId: representanteId,
      cnpj: cnpjLimpo,
      razaoSocial: _razaoSocial.text.trim().isEmpty ? null : _razaoSocial.text.trim(),
      nomeFantasia: _nomeFantasia.text.trim().isEmpty ? null : _nomeFantasia.text.trim(),
      endereco: _endereco.text.trim().isEmpty ? null : _endereco.text.trim(),
      contato: _contato.text.trim().isEmpty ? null : _contato.text.trim(),
      situacao: _situacao.text.trim().isEmpty ? null : _situacao.text.trim(),
      representanteNome: repSel?.nome ?? (_representanteNome.text.trim().isEmpty ? null : _representanteNome.text.trim()),
      representanteCpf: repSel?.cpf ?? (_representanteCpf.text.trim().isEmpty ? null : _representanteCpf.text.trim()),
      representanteRg: repSel?.rg ?? (_representanteRg.text.trim().isEmpty ? null : _representanteRg.text.trim()),
      representanteContato: repSel?.contato ?? (_representanteContato.text.trim().isEmpty ? null : _representanteContato.text.trim()),
      representanteEmail: repSel?.email ?? (_representanteEmail.text.trim().isEmpty ? null : _representanteEmail.text.trim()),
    );

    try {
      final result = await _repo.saveAtaManual(ata: ata, credor: credor);
      if (!mounted) return;
      setState(() => _salvando = false);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SelecionarItensAtaScreen(
            ataId: result.ata.id!,
            credorId: result.credorId,
            tipoAta: _tipoAta!,
            numeroAta: ata.numeroExibicao,
            usuarioLogado: widget.usuarioLogado,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erro = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar ata (manual)'),
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
            _section('Registro', [
              _readOnly('Nome do usuário que cadastrou',
                  widget.usuarioLogado?.nome ?? Supabase.instance.client.auth.currentUser?.userMetadata?['nome']?.toString() ?? '—'),
              _readOnly('Matrícula', widget.usuarioLogado?.matricula ?? '—'),
              _readOnly('Data e hora do registro', _formatDataHora(DateTime.now())),
            ]),
            _section('Identificação da ata', [
              _textField(_numeroAta, 'Número da ata', obrigatorio: true),
              _dropdown('Modalidade', _modalidade, AtaModel.modalidades, (v) => setState(() => _modalidade = v)),
              _textField(_numeroModalidade, 'Número da modalidade'),
            ]),
            _section('Vigência', [
              _dateField('Data início vigência', _vigenciaInicio, (d) => setState(() => _vigenciaInicio = d)),
              _dateField('Data fim vigência', _vigenciaFim, (d) => setState(() => _vigenciaFim = d)),
              _textField(_statusVigencia, 'Status da vigência'),
            ]),
            _section('Detalhamento', [
              _textField(_detalhamento, 'Detalhamento', maxLines: 3),
              _textField(_anoCompetencia, 'Ano competência', keyboardType: TextInputType.number),
              _textField(_numeroProcesso, 'Número do processo administrativo'),
              _textField(_linkProcesso, 'Link do processo administrativo'),
            ]),
            _section('Empresa (fornecedor)', [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cnpj,
                      decoration: const InputDecoration(labelText: 'CNPJ', border: OutlineInputBorder()),
                      inputFormatters: [CnpjInputFormatter()],
                      validator: (v) {
                        if (v == null || cnpjApenasDigitos(v).length != 14) return 'CNPJ deve ter 14 dígitos';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _buscandoCnpj ? null : _buscarCnpjAta,
                    child: _buscandoCnpj ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Buscar'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E)),
                  ),
                ],
              ),
              if (!_empresaSomenteLeitura)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Informe o CNPJ e clique em Buscar para carregar os dados da empresa.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
                )
              else ...[
                _textField(_razaoSocial, 'Razão social', readOnly: true),
                _textField(_nomeFantasia, 'Nome fantasia', readOnly: true),
                _textField(_endereco, 'Endereço', maxLines: 2, readOnly: true),
                _textField(_contato, 'Contato', readOnly: true, inputFormatters: [TelefoneInputFormatter()]),
                if (_contato.text.trim().isNotEmpty && tipoTelefoneBR(_contato.text) != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(tipoTelefoneBR(_contato.text)!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ),
                _textField(_situacao, 'Situação', readOnly: true),
              ],
            ]),
            if (_empresaSomenteLeitura)
              _section('Representante', [
                if (_fornecedorCarregado != null && _representantesFornecedor.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<FornecedorRepresentanteModel>(
                      value: _representantesFornecedor.where((r) => r.id == _representanteSelecionado?.id).firstOrNull,
                      decoration: const InputDecoration(labelText: 'Selecione o representante', border: OutlineInputBorder()),
                      items: _representantesFornecedor.map((r) => DropdownMenuItem(value: r, child: Text('${r.nome ?? "—"}${r.cpf != null && r.cpf!.isNotEmpty ? " (${mascararCpf(r.cpf)})" : ""}'))).toList(),
                      onChanged: (v) => setState(() => _representanteSelecionado = v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Ou cadastre um novo representante:', style: Theme.of(context).textTheme.bodySmall),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Não há representante cadastrado para este fornecedor. Cadastre o representante abaixo.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.orange.shade800),
                    ),
                  ),
                _textField(_representanteNome, 'Nome do representante', obrigatorio: _representanteSelecionado == null, inputFormatters: [NomeTitleCaseInputFormatter()]),
                _textField(_representanteCpf, 'CPF', obrigatorio: _representanteSelecionado == null, inputFormatters: [CpfInputFormatter()], obscureText: true),
                _textField(_representanteRg, 'RG', obrigatorio: _representanteSelecionado == null, inputFormatters: [RgInputFormatter()], obscureText: true),
                _textField(_representanteContato, 'Contato', obrigatorio: _representanteSelecionado == null, inputFormatters: [TelefoneInputFormatter()]),
                if (_representanteContato.text.trim().isNotEmpty && tipoTelefoneBR(_representanteContato.text) != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(tipoTelefoneBR(_representanteContato.text)!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ),
                _textField(_representanteEmail, 'E-mail do representante', obrigatorio: _representanteSelecionado == null, keyboardType: TextInputType.emailAddress, inputFormatters: [LowercaseInputFormatter()]),
                if (_fornecedorCarregado != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton.icon(
                      onPressed: _adicionarRepresentanteNaAta,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Adicionar este representante ao fornecedor'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E)),
                    ),
                  ),
              ]),
            _section('Tipo da ata', [
              _dropdown('Tipo (medicamento / material / opme)', _tipoAta, AtaModel.tiposAta, (v) => setState(() => _tipoAta = v)),
            ]),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(_salvando ? 'Salvando...' : 'Salvar e selecionar itens'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _readOnly(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label, {bool obrigatorio = false, int maxLines = 1, TextInputType? keyboardType, void Function(String)? onChanged, bool readOnly = false, List<TextInputFormatter>? inputFormatters, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (obrigatorio ? ' *' : ''),
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        validator: obrigatorio ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null : null,
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> opcoes, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value?.isEmpty == true ? null : value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: opcoes.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, void Function(DateTime?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(value == null ? label : '${label}: ${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (d != null) onChanged(d);
        },
      ),
    );
  }
}
