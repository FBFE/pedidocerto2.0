import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../modules/unidades_lotacao/models/governo_model.dart';
import '../../modules/unidades_lotacao/models/secretaria_adjunta_model.dart';
import '../../modules/unidades_lotacao/models/secretaria_model.dart';
import '../../modules/unidades_lotacao/models/setor_model.dart';
import '../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../modules/unidades_lotacao/repositories/governo_repository.dart';
import '../../modules/unidades_lotacao/repositories/secretaria_adjunta_repository.dart';
import '../../modules/unidades_lotacao/repositories/secretaria_repository.dart';
import '../../modules/unidades_lotacao/repositories/setor_repository.dart';
import '../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';
import '../../modules/usuarios/models/usuario_model.dart';
import '../../modules/usuarios/repositories/usuario_repository.dart';
import '../../utils/input_formatters.dart';
import '../../utils/opcoes_cargo.dart';
import '../../utils/opcoes_escolaridade_formacao.dart';
import '../../widgets/constrained_content.dart';
import '../../widgets/seletor_busca_dialog.dart';

class AtualizarDadosScreen extends StatefulWidget {
  const AtualizarDadosScreen({
    super.key,
    required this.onIrParaPainel,
    required this.onSair,
    this.podeAcessarPainel = true,
    this.onPerfilAtualizado,

    /// Quando preenchido, administrador está editando outro usuário (carrega por id e permite alterar perfil).
    this.editingUserId,
  });

  final VoidCallback onIrParaPainel;
  final VoidCallback onSair;

  /// Se false, usuário está pendente de aprovação: não mostra "Ir para painel".
  final bool podeAcessarPainel;
  final VoidCallback? onPerfilAtualizado;
  final String? editingUserId;

  @override
  State<AtualizarDadosScreen> createState() => _AtualizarDadosScreenState();
}

class _AtualizarDadosScreenState extends State<AtualizarDadosScreen> {
  final _repository = UsuarioRepository();
  final _governoRepo = GovernoRepository();
  final _secretariaRepo = SecretariaRepository();
  final _secretariaAdjuntaRepo = SecretariaAdjuntaRepository();
  final _unidadeRepo = UnidadeHospitalarRepository();
  final _setorRepo = SetorRepository();
  final _formKey = GlobalKey<FormState>();
  UsuarioModel? _usuario;
  bool _loading = true;
  bool _saving = false;
  String? _erro;

  List<GovernoModel> _governos = [];
  List<SecretariaModel> _secretarias = [];
  List<SecretariaAdjuntaModel> _secretariasAdjuntas = [];
  List<UnidadeHospitalarModel> _unidades = [];

  /// Setores vinculados à unidade de lotação selecionada (Secretaria Adjunta ou Unidade). Vazio se for Governo/Secretaria.
  List<SetorModel> _setoresVinculados = [];
  bool _carregandoSetores = false;
  String? _unidadeLotacaoSelecionada;
  String? _setorLotacaoSelecionada;

  final _nome = TextEditingController();
  final _nascimento = TextEditingController();
  final _documento = TextEditingController();
  final _contato = TextEditingController();
  final _matricula = TextEditingController();
  final _dataPosse = TextEditingController();
  final _dataVencimentoContrato = TextEditingController();

  static const _opcoesRegime = [
    'Efetivo',
    'Comissionado',
    'Contrato',
    'Efetivo + Comissionado',
    'Terceirizado'
  ];
  static const _opcoesDga = ['DGA 2', 'DGA 3', 'DGA 4', 'DGA 5', 'DGA 6'];
  static const _opcoesCargaHoraria = [
    '20 Horas Semanais',
    '30 Horas Semanais',
    '40 Horas Semanais'
  ];

  String? _regimeContratoSelecionado;
  String? _dgaSelecionado;
  String? _cargaHorariaSelecionada;
  String? _escolaridadeSelecionada;
  final _escolaridadeOutra = TextEditingController();
  String? _nivelFormacaoSelecionado;
  final _nivelFormacaoOutro = TextEditingController();
  String? _areaFormacaoSelecionada;
  final _areaFormacaoOutro = TextEditingController();
  final _formacaoEspecifico = TextEditingController();

  static const _opcoesEscolaridade = opcoesEscolaridade;
  static const _opcoesNivelFormacao = opcoesNivelFormacao;
  static const _opcoesAreaFormacao = opcoesAreaFormacao;

  /// Quando já existe registro salvo e o usuário está editando a si mesmo e está aprovado, nascimento, documento, matrícula e data de posse não podem ser editados.
  /// O nome pode ser editado pelo próprio usuário a qualquer momento.
  /// Usuários pendentes ou admin editando outro usuário podem editar todos os dados.
  bool get _camposBloqueados =>
      _usuario?.id != null &&
      widget.podeAcessarPainel &&
      widget.editingUserId == null;
  bool get _editandoOutroUsuario => widget.editingUserId != null;
  String? _perfilSistemaSelecionado;
  static const _opcoesPerfilSistema = [
    ('pendente_aprovacao', 'Pendente de aprovação'),
    ('usuario', 'Usuário'),
    ('administrador', 'Administrador'),
  ];
  final _email = TextEditingController();
  final _situacao = TextEditingController();
  String? _cargoSelecionado;
  final _cargoOutra = TextEditingController();

  static const _opcoesCargo = opcoesCargo;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _nascimento.dispose();
    _documento.dispose();
    _contato.dispose();
    _matricula.dispose();
    _dataPosse.dispose();
    _dataVencimentoContrato.dispose();
    _escolaridadeOutra.dispose();
    _nivelFormacaoOutro.dispose();
    _areaFormacaoOutro.dispose();
    _formacaoEspecifico.dispose();
    _email.dispose();
    _situacao.dispose();
    _cargoOutra.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Inclui o valor já salvo nas opções se não estiver na lista (ex.: unidade/setor antigo).
  List<String> _opcoesComValorAtual(List<String> opcoes, String? valorAtual) {
    if (valorAtual == null ||
        valorAtual.trim().isEmpty ||
        opcoes.contains(valorAtual.trim())) {
      return opcoes;
    }
    return [valorAtual.trim(), ...opcoes];
  }

  Future<void> _carregar() async {
    if (_editandoOutroUsuario && widget.editingUserId != null) {
      try {
        final results = await Future.wait([
          _repository.getUsuarioById(widget.editingUserId!),
          _governoRepo.getAll(),
          _secretariaRepo.getAll(),
          _secretariaAdjuntaRepo.getAll(),
          _unidadeRepo.getAll(),
        ]);
        final u = results[0] as UsuarioModel?;
        _governos = results[1] as List<GovernoModel>;
        _secretarias = results[2] as List<SecretariaModel>;
        _secretariasAdjuntas = results[3] as List<SecretariaAdjuntaModel>;
        _unidades = results[4] as List<UnidadeHospitalarModel>;
        if (u != null) {
          _usuario = u;
          _perfilSistemaSelecionado = u.perfilSistema ?? 'pendente_aprovacao';
          _preencherFormulario(u);
        } else {
          setState(() => _erro = 'Usuário não encontrado.');
        }
        await _carregarSetoresVinculados();
      } catch (e) {
        setState(() => _erro = e.toString());
      }
      setState(() => _loading = false);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final email = user.email ?? '';
    _email.text = email;
    _nome.text = user.userMetadata?['nome'] as String? ?? '';

    try {
      final results = await Future.wait([
        _repository.getUsuarioByEmail(email),
        _governoRepo.getAll(),
        _secretariaRepo.getAll(),
        _secretariaAdjuntaRepo.getAll(),
        _unidadeRepo.getAll(),
      ]);
      final u = results[0] as UsuarioModel?;
      _governos = results[1] as List<GovernoModel>;
      _secretarias = results[2] as List<SecretariaModel>;
      _secretariasAdjuntas = results[3] as List<SecretariaAdjuntaModel>;
      _unidades = results[4] as List<UnidadeHospitalarModel>;
      if (u != null) {
        _usuario = u;
        _preencherFormulario(u);
        _email.text = u.email ?? email;
      }
      await _carregarSetoresVinculados();
    } catch (e) {
      setState(() => _erro = e.toString());
    }
    setState(() => _loading = false);
  }

  void _preencherFormulario(UsuarioModel u) {
    _nome.text = u.nome;
    _nascimento.text = _formatDate(u.nascimento);
    _documento.text = formatarCpfParaExibicao(u.documento);
    _contato.text = formatarTelefoneParaExibicao(u.contato);
    _matricula.text = u.matricula ?? '';
    _dataPosse.text = _formatDate(u.dataPosse);
    _regimeContratoSelecionado = u.regimeContrato;
    _dgaSelecionado = u.dga;
    _dataVencimentoContrato.text = _formatDate(u.dataVencimentoContrato);
    _cargaHorariaSelecionada = u.cargaHoraria;
    _carregarEscolaridade(u.escolaridade);
    _carregarFormacao(u.formacao);
    _email.text = u.email ?? '';
    _unidadeLotacaoSelecionada = u.unidadeLotacao;
    _setorLotacaoSelecionada = u.setorLotacao;
    _situacao.text = u.situacao ?? 'Ativo';
    _carregarCargo(u.cargo);
  }

  /// Carrega setores vinculados à unidade de lotação atual (Secretaria Adjunta ou Unidade). Limpa setor se não pertencer à nova lista.
  Future<void> _carregarSetoresVinculados() async {
    setState(() => _carregandoSetores = true);
    final unidade = _unidadeLotacaoSelecionada?.trim() ?? '';
    List<SetorModel> lista = [];
    if (unidade.startsWith('Secretaria Adjunta: ')) {
      final nome = unidade.substring('Secretaria Adjunta: '.length).trim();
      SecretariaAdjuntaModel? adjunta;
      for (final a in _secretariasAdjuntas) {
        if (a.nome.trim() == nome) {
          adjunta = a;
          break;
        }
      }
      if (adjunta?.id != null) {
        lista = await _setorRepo.getBySecretariaAdjuntaId(adjunta!.id!);
      }
    } else if (unidade.startsWith('Unidade: ')) {
      final nome = unidade.substring('Unidade: '.length).trim();
      UnidadeHospitalarModel? un;
      for (final u in _unidades) {
        if (u.nome.trim() == nome) {
          un = u;
          break;
        }
      }
      if (un?.id != null) {
        lista = await _setorRepo.getByUnidadeHospitalarId(un!.id!);
      }
    }
    if (!mounted) return;
    final nomesSetores = lista.map((s) => s.nome).toList();
    final setorAtualValido = _setorLotacaoSelecionada != null &&
        _setorLotacaoSelecionada!.trim().isNotEmpty &&
        nomesSetores.contains(_setorLotacaoSelecionada!.trim());
    setState(() {
      _setoresVinculados = lista;
      _carregandoSetores = false;
      if (!setorAtualValido) _setorLotacaoSelecionada = null;
    });
  }

  void _carregarEscolaridade(String? valor) {
    if (valor == null || valor.isEmpty) return;
    if (_opcoesEscolaridade.contains(valor)) {
      _escolaridadeSelecionada = valor;
    } else {
      _escolaridadeSelecionada = outraEspecificar;
      _escolaridadeOutra.text = valor;
    }
  }

  void _carregarFormacao(String? valor) {
    if (valor == null || valor.isEmpty) return;
    final parts = parseFormacao(valor);
    if (parts[0].isNotEmpty && _opcoesNivelFormacao.contains(parts[0])) {
      _nivelFormacaoSelecionado = parts[0];
    } else if (parts[0].isNotEmpty) {
      _nivelFormacaoSelecionado = outroEspecificar;
      _nivelFormacaoOutro.text = parts[0];
    }
    if (parts[1].isNotEmpty && _opcoesAreaFormacao.contains(parts[1])) {
      _areaFormacaoSelecionada = parts[1];
    } else if (parts[1].isNotEmpty) {
      _areaFormacaoSelecionada = outroEspecificar;
      _areaFormacaoOutro.text = parts[1];
    }
    if (parts[2].isNotEmpty) _formacaoEspecifico.text = parts[2];
  }

  void _carregarCargo(String? valor) {
    if (valor == null || valor.isEmpty) return;
    if (_opcoesCargo.contains(valor)) {
      _cargoSelecionado = valor;
    } else {
      _cargoSelecionado = outraEspecificar;
      _cargoOutra.text = valor;
    }
  }

  String get _cargoParaSalvar => _cargoSelecionado == outraEspecificar
      ? _cargoOutra.text.trim()
      : (_cargoSelecionado ?? '');

  String get _escolaridadeParaSalvar =>
      _escolaridadeSelecionada == outraEspecificar
          ? _escolaridadeOutra.text.trim()
          : (_escolaridadeSelecionada ?? '');

  String get _formacaoParaSalvar {
    final nivel = _nivelFormacaoSelecionado == outroEspecificar
        ? _nivelFormacaoOutro.text.trim()
        : (_nivelFormacaoSelecionado ?? '');
    final area = _areaFormacaoSelecionada == outroEspecificar
        ? _areaFormacaoOutro.text.trim()
        : (_areaFormacaoSelecionada ?? '');
    final especifico = _formacaoEspecifico.text.trim();
    final s = montarFormacao(nivel, area, especifico);
    return s.replaceAll(formacaoSeparador, '').trim().isEmpty ? '' : s;
  }

  DateTime? _parseDate(String s) {
    s = s.trim();
    if (s.isEmpty) return null;
    final parts = s.replaceAll('/', '-').split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  Future<void> _salvar() async {
    _erro = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Salvamento parcial: só nome e e-mail são obrigatórios; demais campos podem ficar em branco
    try {
      final usuario = UsuarioModel(
        id: _usuario?.id,
        nome: _nome.text.trim(),
        nascimento: _parseDate(_nascimento.text),
        documento:
            _documento.text.trim().isEmpty ? null : _documento.text.trim(),
        contato: _contato.text.trim().isEmpty ? null : _contato.text.trim(),
        matricula:
            _matricula.text.trim().isEmpty ? null : _matricula.text.trim(),
        dataPosse: _parseDate(_dataPosse.text),
        regimeContrato: _regimeContratoSelecionado,
        dga: _dgaSelecionado,
        dataVencimentoContrato: _parseDate(_dataVencimentoContrato.text),
        cargaHoraria: _cargaHorariaSelecionada,
        escolaridade:
            _escolaridadeParaSalvar.isEmpty ? null : _escolaridadeParaSalvar,
        formacao: _formacaoParaSalvar.isEmpty ? null : _formacaoParaSalvar,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        unidadeLotacao: _unidadeLotacaoSelecionada?.trim().isEmpty ?? true
            ? null
            : _unidadeLotacaoSelecionada?.trim(),
        setorLotacao: _setorLotacaoSelecionada?.trim().isEmpty ?? true
            ? null
            : _setorLotacaoSelecionada?.trim(),
        situacao:
            _situacao.text.trim().isEmpty ? 'Ativo' : _situacao.text.trim(),
        cargo: _cargoParaSalvar.isEmpty ? null : _cargoParaSalvar,
        perfilSistema: _editandoOutroUsuario
            ? (_perfilSistemaSelecionado ??
                _usuario?.perfilSistema ??
                'pendente_aprovacao')
            : (_usuario?.perfilSistema ?? 'pendente_aprovacao'),
      );
      if (_usuario?.id != null) {
        final paraSalvar = _editandoOutroUsuario
            ? usuario.copyWith(id: _usuario!.id)
            : (widget.podeAcessarPainel
                ? usuario.copyWith(
                    id: _usuario!.id,
                    nascimento: _usuario!.nascimento,
                    documento: _usuario!.documento,
                    matricula: _usuario!.matricula,
                    dataPosse: _usuario!.dataPosse,
                  )
                : usuario.copyWith(id: _usuario!.id));
        final atualizado = await _repository.updateUsuario(paraSalvar);
        _usuario = atualizado;
      } else {
        final criado = await _repository.createUsuario(usuario);
        _usuario = criado;
      }
      // Atualiza o nome no Auth (user_metadata) para refletir no app (drawer, barra do usuário).
      if (!_editandoOutroUsuario) {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'nome': _nome.text.trim()}),
          );
        } catch (_) {}
      }
      if (mounted) {
        widget.onPerfilAtualizado?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editandoOutroUsuario
                ? 'Usuário atualizado com sucesso.'
                : 'Dados salvos com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
        if (_editandoOutroUsuario) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('PGRST204') ||
            msg.contains('data_vencimento_contrato') ||
            msg.contains('schema cache')) {
          setState(() => _erro =
              'Falta adicionar colunas na tabela "usuarios" no Supabase.\n\n'
                  'No painel do Supabase: SQL Editor > New query > cole e execute o conteúdo do arquivo:\n'
                  'supabase/ADICIONAR_COLUNAS_USUARIOS.sql\n\n'
                  'Depois tente salvar novamente.');
        } else {
          setState(() => _erro = msg);
        }
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_editandoOutroUsuario ? 'Editar usuário' : 'Meus dados'),
          actions: [_buildSairButton()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _editandoOutroUsuario ? 'Editar usuário' : 'Atualizar informações'),
        actions: [
          if (widget.podeAcessarPainel && !_editandoOutroUsuario)
            TextButton.icon(
              onPressed: _saving ? null : () => widget.onIrParaPainel(),
              icon: const Icon(Icons.dashboard, size: 20),
              label: const Text('Ir para o painel'),
            ),
          _buildSairButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: ConstrainedContent(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_erro != null) ...[
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_erro!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!widget.podeAcessarPainel) ...[
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.schedule,
                                color: Colors.amber.shade800, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sua conta está pendente de aprovação. Você pode editar suas informações aqui. '
                                'Após aprovação por um administrador, você poderá acessar o painel do sistema.',
                                style: TextStyle(
                                    color: Colors.amber.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.podeAcessarPainel
                                  ? 'Você pode salvar a qualquer momento e voltar depois para completar. '
                                      'Nascimento, documento, matrícula e data de posse não podem ser alterados após o primeiro salvamento. Seu nome pode ser editado quando quiser.'
                                  : 'Você pode editar e salvar todos os seus dados a qualquer momento enquanto aguarda aprovação.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _campo(
                      'Nome completo *',
                      _nome,
                      (v) =>
                          v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      null,
                      false),
                  _campoData('Data de nascimento (DD/MM/AAAA)', _nascimento,
                      _camposBloqueados),
                  _campo('Documento (CPF)', _documento, null,
                      [CpfInputFormatter()], _camposBloqueados),
                  _campo('Contato (DDD + número)', _contato, null,
                      [TelefoneInputFormatter()]),
                  _campo(
                      'Matrícula',
                      _matricula,
                      null,
                      [FilteringTextInputFormatter.digitsOnly],
                      _camposBloqueados),
                  _campoData('Data de posse (DD/MM/AAAA)', _dataPosse,
                      _camposBloqueados),
                  _dropdown('Regime/Contrato', _regimeContratoSelecionado,
                      _opcoesRegime, (v) {
                    setState(() {
                      _regimeContratoSelecionado = v;
                      if (v != 'Comissionado' && v != 'Efetivo + Comissionado') {
                        _dgaSelecionado = null;
                      }
                      if (v != 'Contrato') _dataVencimentoContrato.clear();
                    });
                  }),
                  if (_regimeContratoSelecionado == 'Comissionado' ||
                      _regimeContratoSelecionado == 'Efetivo + Comissionado')
                    _dropdown('DGA', _dgaSelecionado, _opcoesDga,
                        (v) => setState(() => _dgaSelecionado = v)),
                  if (_regimeContratoSelecionado == 'Contrato')
                    _campoData('Data do vencimento do contrato',
                        _dataVencimentoContrato),
                  _dropdown(
                      'Carga horária',
                      _cargaHorariaSelecionada,
                      _opcoesCargaHoraria,
                      (v) => setState(() => _cargaHorariaSelecionada = v)),
                  _dropdown(
                      'Escolaridade',
                      _escolaridadeSelecionada,
                      _opcoesEscolaridade,
                      (v) => setState(() => _escolaridadeSelecionada = v)),
                  if (_escolaridadeSelecionada == outraEspecificar)
                    _campo('Especificar escolaridade', _escolaridadeOutra),
                  _dropdown(
                      'Formação – Nível / Titulação',
                      _nivelFormacaoSelecionado,
                      _opcoesNivelFormacao,
                      (v) => setState(() => _nivelFormacaoSelecionado = v)),
                  if (_nivelFormacaoSelecionado == outroEspecificar)
                    _campo(
                        'Especificar nível de formação', _nivelFormacaoOutro),
                  _dropdown(
                      'Formação – Área de conhecimento',
                      _areaFormacaoSelecionada,
                      _opcoesAreaFormacao,
                      (v) => setState(() => _areaFormacaoSelecionada = v)),
                  if (_areaFormacaoSelecionada == outroEspecificar)
                    _campo('Especificar área de formação', _areaFormacaoOutro),
                  _campo('Curso ou especialização específica (opcional)',
                      _formacaoEspecifico),
                  _campo(
                      'E-mail *',
                      _email,
                      (v) =>
                          v == null || v.trim().isEmpty ? 'Obrigatório' : null),
                  _seletorLotacao(
                    label: 'Unidade de lotação',
                    valor: _unidadeLotacaoSelecionada,
                    secoes: [
                      (
                        titulo: 'Governo',
                        opcoes: _governos
                            .where((g) => g.nome.trim().isNotEmpty)
                            .map((g) => 'Governo: ${g.nome.trim()}')
                            .toList()
                      ),
                      (
                        titulo: 'Secretaria',
                        opcoes: _secretarias
                            .where((s) => s.nome.trim().isNotEmpty)
                            .map((s) => 'Secretaria: ${s.nome.trim()}')
                            .toList()
                      ),
                      (
                        titulo: 'Secretaria Adjunta',
                        opcoes: _secretariasAdjuntas
                            .where((a) => a.nome.trim().isNotEmpty)
                            .map((a) => 'Secretaria Adjunta: ${a.nome.trim()}')
                            .toList()
                      ),
                      (
                        titulo: 'Unidade',
                        opcoes: _unidades
                            .where((u) => u.nome.trim().isNotEmpty)
                            .map((u) => 'Unidade: ${u.nome.trim()}')
                            .toList()
                      ),
                    ],
                    valorAtualPodeNaoEstarNaLista: _unidadeLotacaoSelecionada,
                    onSelecionado: (v) {
                      setState(() => _unidadeLotacaoSelecionada = v);
                      _carregarSetoresVinculados();
                    },
                  ),
                  _seletorSetorLotacao(),
                  _campo('Situação', _situacao),
                  _dropdown('Cargo', _cargoSelecionado, _opcoesCargo,
                      (v) => setState(() => _cargoSelecionado = v)),
                  if (_cargoSelecionado == outraEspecificar)
                    _campo('Especificar cargo', _cargoOutra),
                  if (_editandoOutroUsuario)
                    _dropdown(
                      'Perfil no sistema',
                      _perfilSistemaSelecionado == null
                          ? null
                          : _opcoesPerfilSistema
                              .firstWhere(
                                  (e) => e.$1 == _perfilSistemaSelecionado,
                                  orElse: () => _opcoesPerfilSistema.first)
                              .$2,
                      _opcoesPerfilSistema.map((e) => e.$2).toList(),
                      (v) => setState(() {
                        _perfilSistemaSelecionado = v == null
                            ? null
                            : _opcoesPerfilSistema
                                .firstWhere((e) => e.$2 == v)
                                .$1;
                      }),
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _salvar,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Salvando...' : 'Salvar dados'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                  if (widget.podeAcessarPainel) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => widget.onIrParaPainel(),
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Ir para o painel'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSairButton() {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await Supabase.instance.client.auth.signOut();
        widget.onSair();
      },
    );
  }

  Widget _campo(
    String label,
    TextEditingController controller, [
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
        ),
        validator: validator,
        inputFormatters: readOnly ? [] : (inputFormatters ?? []),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> opcoes,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value != null && opcoes.contains(value) ? value : null,
            isExpanded: true,
            hint: Text('Selecione',
                style: TextStyle(color: Theme.of(context).hintColor)),
            items: opcoes
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  bool get _unidadePermiteSetor {
    final u = _unidadeLotacaoSelecionada?.trim() ?? '';
    return u.startsWith('Secretaria Adjunta: ') || u.startsWith('Unidade: ');
  }

  /// Setor de lotação: apenas setores vinculados à unidade selecionada (Secretaria Adjunta ou Unidade).
  Widget _seletorSetorLotacao() {
    if (!_unidadePermiteSetor) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Setor de lotação',
            border: OutlineInputBorder(),
            filled: true,
            hintText:
                'Selecione uma Secretaria Adjunta ou Unidade de lotação acima',
          ),
          child: Text(
            'Selecione uma Secretaria Adjunta ou Unidade de lotação acima',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
          ),
        ),
      );
    }
    final opcoesSetores = _opcoesComValorAtual(
      _setoresVinculados.map((s) => s.nome).toList(),
      _setorLotacaoSelecionada,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _carregandoSetores
            ? null
            : () async {
                final escolhido = await showDialog<String>(
                  context: context,
                  builder: (context) => SeletorBuscaDialog(
                    titulo: 'Setor de lotação',
                    secoes: [
                      (
                        titulo: 'Setores vinculados à sua unidade',
                        opcoes: opcoesSetores
                      )
                    ],
                    valorAtual: _setorLotacaoSelecionada,
                    alturaMaxima: 520,
                  ),
                );
                if (escolhido != null) {
                  setState(() => _setorLotacaoSelecionada = escolhido);
                }
              },
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Setor de lotação',
            border: const OutlineInputBorder(),
            filled: true,
            suffixIcon: _carregandoSetores
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : const Icon(Icons.search, size: 22),
          ),
          child: Text(
            _carregandoSetores
                ? 'Carregando setores...'
                : (_setorLotacaoSelecionada != null &&
                        _setorLotacaoSelecionada!.isNotEmpty
                    ? _setorLotacaoSelecionada!
                    : 'Selecione (clique para buscar)'),
            style: TextStyle(
              color: (_setorLotacaoSelecionada != null &&
                      _setorLotacaoSelecionada!.isNotEmpty)
                  ? null
                  : Theme.of(context).hintColor,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  /// Campo que abre diálogo com busca e seções para Unidade/Setor de lotação.
  Widget _seletorLotacao({
    required String label,
    required String? valor,
    required List<({String titulo, List<String> opcoes})> secoes,
    String? valorAtualPodeNaoEstarNaLista,
    required ValueChanged<String?> onSelecionado,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final escolhido = await showDialog<String>(
            context: context,
            builder: (context) => SeletorBuscaDialog(
              titulo: label,
              secoes: secoes,
              valorAtual: valorAtualPodeNaoEstarNaLista,
              alturaMaxima: 520,
            ),
          );
          if (escolhido != null) onSelecionado(escolhido);
        },
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            suffixIcon: const Icon(Icons.search, size: 22),
          ),
          child: Text(
            valor != null && valor.isNotEmpty
                ? valor
                : 'Selecione (clique para buscar)',
            style: TextStyle(
              color: valor != null && valor.isNotEmpty
                  ? null
                  : Theme.of(context).hintColor,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoData(String label, TextEditingController controller,
      [bool readOnly = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'DD/MM/AAAA',
          border: const OutlineInputBorder(),
          filled: true,
          suffixIcon: readOnly
              ? null
              : IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _abrirCalendario(controller),
                ),
        ),
        inputFormatters: readOnly ? [] : [DataInputFormatter()],
      ),
    );
  }

  Future<void> _abrirCalendario(TextEditingController controller) async {
    final dataAtual = _parseDate(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dataAtual,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) controller.text = _formatDate(picked);
  }
}
