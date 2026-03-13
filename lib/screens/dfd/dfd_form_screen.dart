import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../modules/dfd/models/dfd_model.dart';
import '../../modules/dfd/repositories/dfd_repository.dart';
import '../../widgets/constrained_content.dart';
import '../../modules/unidades_lotacao/repositories/secretaria_repository.dart';
import '../../modules/unidades_lotacao/repositories/secretaria_adjunta_repository.dart';
import '../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';
import '../../modules/usuarios/models/usuario_model.dart';
import '../../modules/sigtap/models/procedimento_model.dart';
import '../../modules/renem/models/renem_model.dart';
import '../../modules/catmed/models/catmed_model.dart';
import '../../modules/renem/repositories/renem_repository.dart';
import '../../modules/usuarios/repositories/usuario_repository.dart';
import '../../modules/sigtap/repositories/procedimento_repository.dart';
import '../../modules/catmed/repositories/catmed_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DfdFormScreen extends StatefulWidget {
  final DfdModel? dfd;
  final UsuarioModel? usuarioLogado;
  final VoidCallback? onSaved;

  const DfdFormScreen({super.key, this.dfd, this.usuarioLogado, this.onSaved});

  @override
  State<DfdFormScreen> createState() => _DfdFormScreenState();
}

class _DfdFormScreenState extends State<DfdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = DfdRepository();
  final _usuarioRepository = UsuarioRepository();
  bool _salvando = false;

  // 1. Identificação
  final _orgaoController = TextEditingController();
  bool _carregandoOrgao = false;

  final _unidadeOrcamentariaController = TextEditingController();

  // Opções de Unidade Orçamentária
  String? _unidadeOrcamentariaSelecionada;
  final List<Map<String, String>> _opcoesUnidadeOrcamentaria = [
    {
      'codigo': '21601',
      'descricao':
          'Fundo Estadual de Saúde (SES-MT) - A mais comum para compras hospitalares.'
    },
    {'codigo': '21101', 'descricao': 'Secretaria de Estado de Saúde (SES-MT)'},
    {
      'codigo': '15101',
      'descricao': 'Secretaria de Estado de Fazenda (SEFAZ-MT)'
    },
    {
      'codigo': '14101',
      'descricao': 'Secretaria de Estado de Planejamento e Gestão (SEPLAG-MT)'
    },
    {'codigo': '21401', 'descricao': 'MT Saúde'},
  ];
  final _setorRequisitanteController = TextEditingController();
  final _responsavelDemandaController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();

  // 2. Objeto
  String? _classificacaoObjeto;
  final _descricaoDemandaController = TextEditingController();

  final _opcoesClassificacao = [
    'Consumíveis',
    'Material Permanente',
    'Equipamento de TI',
    'Serviço não continuado',
    'Serviço continuado SEM dedicação exclusiva de mão de obra',
    'Serviço continuado COM dedicação exclusiva de mão de obra',
  ];

  // 3. Forma de Contratação
  String? _formaContratacao;
  final _opcoesFormaContratacao = [
    'Modalidades da Lei nº 14.133/21 e Decreto nº 1.525/2022',
    'Utilização à ARP - Órgão Participante',
    'Adesão à ARP de outro Órgão',
    'Dispensa/Inexigibilidade (Lei nº 14.133/21 e Decreto Estadual/MT n° 1.525/2022)',
  ];

  final _numeroArpController = TextEditingController();
  final _editalArpController = TextEditingController();
  DateTime? _dataPublicacaoArp;
  DateTime? _dataVigenciaArp;
  bool _necessidadeEtp = false;
  bool _etpRetiradoManualmente = false;

  final _etpNumeroController = TextEditingController();
  final _linkSigadocController = TextEditingController();
  Uint8List? _etpBytes;
  String? _etpFileName;

  String _obterDicaEtp() {
    if (_formaContratacao == null) return '';
    if (_formaContratacao!.contains('Modalidades')) {
      return 'Obrigatório por Lei.\nETP é a primeira etapa da fase preparatória, servindo de base para o Termo de Referência (TR).';
    }
    if (_formaContratacao!.contains('Participante')) {
      return 'Dispensado (ou aproveitado).\nO ETP já foi realizado pelo Órgão Gerenciador durante a licitação que deu origem à ARP.';
    }
    if (_formaContratacao!.contains('Adesão')) {
      return 'Sim (Pode ser simplificado).\nNecessário para demonstrar a vantajosidade da adesão em relação a licitar por conta própria.';
    }
    if (_formaContratacao!.contains('Dispensa')) {
      return 'Depende do caso (Facultativo p/ baixo valor).\nAbaixo do limite financeiro: Facultativo (salta pro TR).\nAcima do limite ou outras dispensas: Obrigatório (exceto emergência/calamidade).\n\nObs: Por padrão, o sistema marca como obrigatório, mas você pode desmarcar manualmente se enquadrar na exceção.';
    }
    return '';
  }

  void _atualizarNecessidadeEtp(String? forma) {
    if (forma == null) return;

    // Reseta a flag de retirada manual sempre que muda a forma de contratação
    _etpRetiradoManualmente = false;

    // Auto-preenche o toggle do ETP baseado nas regras gerais
    if (forma.contains('Modalidades') || forma.contains('Adesão')) {
      _necessidadeEtp = true;
    } else if (forma.contains('Participante')) {
      _necessidadeEtp = false;
    } else if (forma.contains('Dispensa')) {
      // Para dispensa, assumimos "obrigatório" por padrão (acima do valor/outras dispensas)
      // O usuário pode desmarcar se for baixo valor ou emergência
      _necessidadeEtp = true;
    }
  }

  // 4. Justificativa
  final _justificativaController = TextEditingController();
  final _demonstracaoPacController = TextEditingController();
  final _recursosController = TextEditingController();
  DateTime? _dataPretendida;
  final _grauPrioridadeController = TextEditingController();
  final _correlacaoController = TextEditingController();

  // 5. Equipe
  final _reqNomeController = TextEditingController();
  final _reqMatriculaController = TextEditingController();
  final _reqLotacaoController = TextEditingController();
  List<UsuarioModel> _listaUsuarios = [];
  UsuarioModel? _integranteTecnico1Selecionado;
  UsuarioModel? _integranteTecnico2Selecionado;
  final _tec1NomeController = TextEditingController();
  final _tec1MatriculaController = TextEditingController();
  final _tec1LotacaoController = TextEditingController();
  final _tec2NomeController = TextEditingController();
  final _tec2MatriculaController = TextEditingController();
  final _tec2LotacaoController = TextEditingController();

  // 6. Matriz GUT
  final _matrizItemController = TextEditingController();
  int _matrizG = 1;
  int _matrizU = 1;
  int _matrizT = 1;

  // 7. Assinaturas
  final _localController = TextEditingController();
  DateTime _dataAssinatura = DateTime.now();
  final _resp1Controller = TextEditingController();
  final _resp2Controller = TextEditingController();
  final _resp3Controller = TextEditingController();
  UsuarioModel? _responsavel1Selecionado;
  UsuarioModel? _responsavel2Selecionado;
  UsuarioModel? _responsavel3Selecionado;

  // 8. Itens do DFD
  String? _categoriaItens;
  String? _classificacaoRenem;
  List<String> _classificacoesRenem = [];
  List<dynamic> _itensSelecionados = [];

  @override
  void initState() {
    super.initState();
    _inicializarDados();
    _carregarClassificacoesRenem();
    _carregarUsuarios();
  }

  void _atualizarMatrizItemDaCategoria() {
    String texto = '';
    if (_categoriaItens == 'SIGTAP') {
      texto = 'Procedimentos (SIGTAP)';
    } else if (_categoriaItens == 'RENEM') {
      texto = 'Equipamentos (RENEM)';
      if (_classificacaoRenem != null &&
          _classificacaoRenem!.isNotEmpty &&
          _classificacaoRenem != 'Todas') {
        texto = '$texto - $_classificacaoRenem';
      }
    } else if (_categoriaItens == 'CATMED') {
      texto = 'Medicamentos (CATMED)';
    }
    if (_matrizItemController.text != texto) {
      _matrizItemController.text = texto;
    }
  }

  Future<void> _carregarUsuarios() async {
    try {
      final lista = await _usuarioRepository.getUsuarios();
      if (!mounted) return;
      setState(() {
        _listaUsuarios = lista;
      });
      // Se estamos editando um DFD, tentar vincular os integrantes técnicos pelo matrícula
      if (widget.dfd != null) {
        final d = widget.dfd!;
        final mat1 = d.integranteTecnico1Matricula?.trim();
        final mat2 = d.integranteTecnico2Matricula?.trim();
        setState(() {
          if (mat1 != null && mat1.isNotEmpty) {
            _integranteTecnico1Selecionado = lista
                .where((u) => u.matricula?.trim() == mat1)
                .firstOrNull;
          }
          if (mat2 != null && mat2.isNotEmpty) {
            _integranteTecnico2Selecionado = lista
                .where((u) => u.matricula?.trim() == mat2)
                .firstOrNull;
          }
          // Vincular responsáveis (assinaturas) por nome
          final r1 = d.responsavel1.trim();
          final r2 = (d.responsavel2 ?? '').trim();
          final r3 = (d.responsavel3 ?? '').trim();
          if (r1.isNotEmpty) {
            _responsavel1Selecionado = lista
                .where((u) => u.nome.trim() == r1)
                .firstOrNull;
          }
          if (r2.isNotEmpty) {
            _responsavel2Selecionado = lista
                .where((u) => u.nome.trim() == r2)
                .firstOrNull;
          }
          if (r3.isNotEmpty) {
            _responsavel3Selecionado = lista
                .where((u) => u.nome.trim() == r3)
                .firstOrNull;
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar usuários: $e');
    }
  }

  Future<void> _carregarClassificacoesRenem() async {
    try {
      final repo = RenemRepository();
      final classificacoes = await repo.getClassificacoes();
      if (mounted) {
        setState(() {
          _classificacoesRenem = classificacoes;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar classificacoes renem: $e');
    }
  }

  Future<void> _mostrarSelecaoIntegranteTecnico(int qual) async {
    final filtrado = _listaUsuarios.where((u) {
      final nome = u.nome.toLowerCase();
      final mat = (u.matricula ?? '').toLowerCase();
      return nome.isNotEmpty || mat.isNotEmpty;
    }).toList();

    if (filtrado.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Nenhum usuário cadastrado. Peça a um administrador para cadastrar os integrantes no sistema.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final searchController = TextEditingController();
    List<UsuarioModel> listaFiltrada = List.from(filtrado);

    if (!mounted) return;
    final selecionado = await showDialog<UsuarioModel>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void aplicarFiltro() {
              final termo = searchController.text.trim().toLowerCase();
              setDialogState(() {
                if (termo.isEmpty) {
                  listaFiltrada = List.from(filtrado);
                } else {
                  listaFiltrada = filtrado
                      .where((u) =>
                          u.nome.toLowerCase().contains(termo) ||
                          (u.matricula ?? '').toLowerCase().contains(termo))
                      .toList();
                }
              });
            }

            return AlertDialog(
              title: Text(qual == 1
                  ? 'Selecionar Integrante Técnico 1'
                  : 'Selecionar Integrante Técnico 2'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nome ou matrícula',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => aplicarFiltro(),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: listaFiltrada.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                  'Nenhum usuário encontrado. Solicite o cadastro a um administrador.'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: listaFiltrada.length,
                              itemBuilder: (context, index) {
                                final u = listaFiltrada[index];
                                return ListTile(
                                  title: Text(u.nome),
                                  subtitle: Text(
                                      'Matrícula: ${u.matricula ?? "-"} • ${u.unidadeLotacao ?? u.setorLotacao ?? "-"}'),
                                  onTap: () =>
                                      Navigator.of(context).pop(u),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Não encontrou o usuário? Solicite o cadastro a um administrador.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selecionado != null && mounted) {
      setState(() {
        if (qual == 1) {
          _integranteTecnico1Selecionado = selecionado;
          _tec1NomeController.text = selecionado.nome;
          _tec1MatriculaController.text = selecionado.matricula ?? '';
          _tec1LotacaoController.text =
              selecionado.unidadeLotacao ?? selecionado.setorLotacao ?? '';
        } else {
          _integranteTecnico2Selecionado = selecionado;
          _tec2NomeController.text = selecionado.nome;
          _tec2MatriculaController.text = selecionado.matricula ?? '';
          _tec2LotacaoController.text =
              selecionado.unidadeLotacao ?? selecionado.setorLotacao ?? '';
        }
      });
    }
  }

  void _limparIntegranteTecnico(int qual) {
    setState(() {
      if (qual == 1) {
        _integranteTecnico1Selecionado = null;
        _tec1NomeController.clear();
        _tec1MatriculaController.clear();
        _tec1LotacaoController.clear();
      } else {
        _integranteTecnico2Selecionado = null;
        _tec2NomeController.clear();
        _tec2MatriculaController.clear();
        _tec2LotacaoController.clear();
      }
    });
  }

  Future<void> _mostrarSelecaoResponsavel(int qual) async {
    final filtrado = _listaUsuarios.where((u) => u.nome.trim().isNotEmpty).toList();
    if (filtrado.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Nenhum usuário cadastrado. Peça a um administrador para cadastrar no sistema.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final searchController = TextEditingController();
    List<UsuarioModel> listaFiltrada = List.from(filtrado);

    if (!mounted) return;
    final selecionado = await showDialog<UsuarioModel>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void aplicarFiltro() {
              final termo = searchController.text.trim().toLowerCase();
              setDialogState(() {
                listaFiltrada = termo.isEmpty
                    ? List.from(filtrado)
                    : filtrado
                        .where((u) =>
                            u.nome.toLowerCase().contains(termo) ||
                            (u.matricula ?? '').toLowerCase().contains(termo))
                        .toList();
              });
            }

            return AlertDialog(
              title: Text(
                  qual == 1
                      ? 'Selecionar Responsável 1'
                      : qual == 2
                          ? 'Selecionar Responsável 2 (Opcional)'
                          : 'Selecionar Responsável 3 (Opcional)'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nome ou matrícula',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => aplicarFiltro(),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: listaFiltrada.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                  'Nenhum usuário encontrado. Solicite o cadastro a um administrador.'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: listaFiltrada.length,
                              itemBuilder: (context, index) {
                                final u = listaFiltrada[index];
                                return ListTile(
                                  title: Text(u.nome),
                                  subtitle: Text(
                                      'Matrícula: ${u.matricula ?? "-"} • ${u.unidadeLotacao ?? u.setorLotacao ?? "-"}'),
                                  onTap: () => Navigator.of(context).pop(u),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Não encontrou? Solicite o cadastro a um administrador.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selecionado != null && mounted) {
      setState(() {
        switch (qual) {
          case 1:
            _responsavel1Selecionado = selecionado;
            _resp1Controller.text = selecionado.nome;
            break;
          case 2:
            _responsavel2Selecionado = selecionado;
            _resp2Controller.text = selecionado.nome;
            break;
          case 3:
            _responsavel3Selecionado = selecionado;
            _resp3Controller.text = selecionado.nome;
            break;
        }
      });
    }
  }

  void _limparResponsavel(int qual) {
    setState(() {
      switch (qual) {
        case 1:
          _responsavel1Selecionado = null;
          _resp1Controller.clear();
          break;
        case 2:
          _responsavel2Selecionado = null;
          _resp2Controller.clear();
          break;
        case 3:
          _responsavel3Selecionado = null;
          _resp3Controller.clear();
          break;
      }
    });
  }

  Widget _buildSelecaoResponsavel(int qual) {
    final selecionado = qual == 1
        ? _responsavel1Selecionado
        : qual == 2
            ? _responsavel2Selecionado
            : _responsavel3Selecionado;
    final controller = qual == 1
        ? _resp1Controller
        : qual == 2
            ? _resp2Controller
            : _resp3Controller;
    final obrigatorio = qual == 1;
    final label = qual == 1
        ? 'Responsável 1'
        : qual == 2
            ? 'Responsável 2 (Opcional)'
            : 'Responsável 3 (Opcional)';

    if (selecionado == null && controller.text.trim().isEmpty) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.person_add),
        label: Text('Selecionar $label'),
        onPressed: () => _mostrarSelecaoResponsavel(qual),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: controller,
              readOnly: true,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                filled: true,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: obrigatorio
                  ? (v) => v!.isEmpty ? 'Campo obrigatório' : null
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Alterar'),
                  onPressed: () => _mostrarSelecaoResponsavel(qual),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Limpar'),
                  onPressed: () => _limparResponsavel(qual),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _inicializarDados() async {
    if (widget.dfd != null) {
      _preencherDados(widget.dfd!);
    } else {
      await _preencherDadosUsuarioLogado();
    }
  }

  void _preencherDados(DfdModel d) {
    _orgaoController.text = d.orgao;

    // Tenta encontrar a opção correspondente para o Dropdown
    final uoExistente = _opcoesUnidadeOrcamentaria
        .indexWhere((opt) => opt['codigo'] == d.unidadeOrcamentaria);
    if (uoExistente != -1) {
      _unidadeOrcamentariaSelecionada = d.unidadeOrcamentaria;
    } else {
      // Fallback para o modo texto se não achar na lista
      _unidadeOrcamentariaController.text = d.unidadeOrcamentaria;
    }

    _setorRequisitanteController.text = d.setorRequisitante;
    _responsavelDemandaController.text = d.responsavelDemanda;
    _matriculaController.text = d.matricula;
    _emailController.text = d.email;
    _telefoneController.text = d.telefone;

    _classificacaoObjeto =
        d.classificacaoObjeto.isNotEmpty ? d.classificacaoObjeto : null;
    _descricaoDemandaController.text = d.descricaoDemanda;

    _formaContratacao = d.formaContratacaoSugerida.isNotEmpty
        ? d.formaContratacaoSugerida
        : null;
    _numeroArpController.text = d.numeroArp ?? '';
    _editalArpController.text = d.editalArp ?? '';
    _dataPublicacaoArp = d.dataPublicacaoArp;
    _dataVigenciaArp = d.dataVigenciaArp;
    _necessidadeEtp = d.necessidadeEtp;
    _etpRetiradoManualmente = d.etpRetiradoManualmente ?? false;
    _etpNumeroController.text = d.etpNumero ?? '';
    _etpFileName = d.etpFileUrl?.split('/').last;

    _justificativaController.text = d.justificativaNecessidade;
    _demonstracaoPacController.text = d.demonstracaoPrevisaoPac;
    _recursosController.text = d.recursosOrcamentarios;
    _dataPretendida = d.dataPretendidaContratacao;
    _grauPrioridadeController.text = d.grauPrioridade;
    _correlacaoController.text = d.correlacaoPlanejamento;

    _reqNomeController.text = d.integranteRequisitanteNome;
    _reqMatriculaController.text = d.integranteRequisitanteMatricula;
    _reqLotacaoController.text = d.integranteRequisitanteLotacao;
    _tec1NomeController.text = d.integranteTecnico1Nome ?? '';
    _tec1MatriculaController.text = d.integranteTecnico1Matricula ?? '';
    _tec1LotacaoController.text = d.integranteTecnico1Lotacao ?? '';
    _tec2NomeController.text = d.integranteTecnico2Nome ?? '';
    _tec2MatriculaController.text = d.integranteTecnico2Matricula ?? '';
    _tec2LotacaoController.text = d.integranteTecnico2Lotacao ?? '';

    _matrizItemController.text = d.matrizItem;
    _matrizG = d.matrizG;
    _matrizU = d.matrizU;
    _matrizT = d.matrizT;

    _localController.text = d.localizacao;
    _dataAssinatura = d.dataAssinatura;
    _resp1Controller.text = d.responsavel1;
    _resp2Controller.text = d.responsavel2 ?? '';
    _resp3Controller.text = d.responsavel3 ?? '';

    _categoriaItens = d.categoriaItens;
    _classificacaoRenem = d.classificacaoRenem;
    _linkSigadocController.text = d.linkSigadoc ?? '';
    _itensSelecionados = List.from(d.itens);
    _atualizarMatrizItemDaCategoria();
  }

  Future<void> _preencherDadosUsuarioLogado() async {
    if (widget.usuarioLogado == null) return;

    setState(() => _carregandoOrgao = true);

    final u = widget.usuarioLogado!;
    String orgaoNome = '';

    final lotacao = u.unidadeLotacao ?? '';

    if (lotacao.isNotEmpty) {
      try {
        final secRepo = SecretariaRepository();
        final adjuntaRepo = SecretariaAdjuntaRepository();
        final unidadeRepo = UnidadeHospitalarRepository();

        final secretarias = await secRepo.getAll();

        // 1. A lotação já é uma Secretaria?
        final matchSec = secretarias
            .where((s) => s.nome.toLowerCase() == lotacao.toLowerCase())
            .firstOrNull;
        if (matchSec != null) {
          orgaoNome = matchSec.nome;
        } else {
          // 2. É uma Secretaria Adjunta?
          final adjuntas = await adjuntaRepo.getAll();
          final matchAdj = adjuntas
              .where((a) => a.nome.toLowerCase() == lotacao.toLowerCase())
              .firstOrNull;
          if (matchAdj != null) {
            final parentSec = secretarias
                .where((s) => s.id == matchAdj.secretariaId)
                .firstOrNull;
            if (parentSec != null) orgaoNome = parentSec.nome;
          } else {
            // 3. É uma Unidade Hospitalar?
            final unidades = await unidadeRepo.getAll();
            final matchUni = unidades
                .where((un) => un.nome.toLowerCase() == lotacao.toLowerCase())
                .firstOrNull;
            if (matchUni != null) {
              final parentSec = secretarias
                  .where((s) => s.id == matchUni.secretariaId)
                  .firstOrNull;
              if (parentSec != null) orgaoNome = parentSec.nome;
            } else {
              // 4. Se for "Gabinete de Gestão Hospitalar" ou similar gravado direto em Setor de Lotação
              final setor = u.setorLotacao ?? '';
              if (setor.isNotEmpty) {
                final matchAdjSetor = adjuntas
                    .where((a) => a.nome.toLowerCase() == setor.toLowerCase())
                    .firstOrNull;
                if (matchAdjSetor != null) {
                  final parentSec = secretarias
                      .where((s) => s.id == matchAdjSetor.secretariaId)
                      .firstOrNull;
                  if (parentSec != null) orgaoNome = parentSec.nome;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Erro ao buscar secretaria: $e');
      }
    }

    // Fallback: se ainda estiver vazio, tenta forçar buscar a secretaria mestre (Secretaria de Estado de Saúde)
    // baseando-se no padrão comum do aplicativo.
    if (orgaoNome.isEmpty) {
      try {
        final secRepo = SecretariaRepository();
        final secretarias = await secRepo.getAll();
        if (secretarias.isNotEmpty) {
          // Pega a primeira secretaria cadastrada logo abaixo do governo (geralmente SES)
          orgaoNome = secretarias.first.nome;
        } else {
          orgaoNome = lotacao;
        }
      } catch (e) {
        orgaoNome = lotacao;
      }
    }

    if (mounted) {
      setState(() {
        _carregandoOrgao = false;
        _orgaoController.text = orgaoNome;

        // Setor Requisitante = Setor de Lotação (ou Unidade de Lotação como fallback)
        final setorLotacao =
            u.setorLotacao != null && u.setorLotacao!.isNotEmpty
                ? u.setorLotacao!
                : (u.unidadeLotacao ?? '');

        _setorRequisitanteController.text = setorLotacao;
        _responsavelDemandaController.text = u.nome;
        _matriculaController.text = u.matricula ?? '';

        // Auto-preencher Equipe de Planejamento -> Requisitante
        _reqNomeController.text = u.nome;
        _reqMatriculaController.text = u.matricula ?? '';
        _reqLotacaoController.text = setorLotacao;
      });
    }
  }

  Future<void> _anexarEtp() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      // Limite de 5MB para forçar a redução/otimização do tamanho
      const maxBytes = 5 * 1024 * 1024;
      if (file.size > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Arquivo muito grande! O tamanho máximo permitido é 5MB. Por favor, comprima o arquivo antes de enviar.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      setState(() {
        _etpBytes = file.bytes;
        _etpFileName = file.name;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_necessidadeEtp &&
        _etpBytes == null &&
        widget.dfd?.etpFileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, anexe o arquivo do ETP.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    if (_necessidadeEtp && _etpNumeroController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, informe o número do ETP.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final linkSigadoc = _linkSigadocController.text.trim();
    if (linkSigadoc.isNotEmpty) {
      final duplicado = await _repository.findLinkSigadocDuplicado(linkSigadoc,
          ignoreDfdId: widget.dfd?.id);
      if (duplicado != null && mounted) {
        final id = duplicado['dfdId'] ?? '';
        final etp = duplicado['etpNumero'];
        final processo = etp != null && etp.isNotEmpty
            ? 'Nº processo/ETP: $etp'
            : 'ID do processo: ${id.length > 12 ? '${id.substring(0, 12)}...' : id}';
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Link já utilizado'),
            content: Text(
              'Este link do SIGADOC já foi utilizado em outro processo.\n\n$processo',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    setState(() => _salvando = true);

    try {
      final uo = _unidadeOrcamentariaSelecionada ??
          _unidadeOrcamentariaController.text;

      final dfd = DfdModel(
        id: widget.dfd?.id,
        orgao: _orgaoController.text,
        unidadeOrcamentaria: uo,
        setorRequisitante: _setorRequisitanteController.text,
        responsavelDemanda: _responsavelDemandaController.text,
        matricula: _matriculaController.text,
        email: _emailController.text,
        telefone: _telefoneController.text,
        classificacaoObjeto: _classificacaoObjeto ?? '',
        descricaoDemanda: _descricaoDemandaController.text,
        formaContratacaoSugerida: _formaContratacao ?? '',
        numeroArp: _numeroArpController.text.isEmpty
            ? null
            : _numeroArpController.text,
        editalArp: _editalArpController.text.isEmpty
            ? null
            : _editalArpController.text,
        dataPublicacaoArp: _dataPublicacaoArp,
        dataVigenciaArp: _dataVigenciaArp,
        necessidadeEtp: _necessidadeEtp,
        etpRetiradoManualmente: _etpRetiradoManualmente,
        etpNumero: _necessidadeEtp ? _etpNumeroController.text.trim() : null,
        etpFileUrl: widget.dfd?.etpFileUrl,
        justificativaNecessidade: _justificativaController.text,
        demonstracaoPrevisaoPac: _demonstracaoPacController.text,
        recursosOrcamentarios: _recursosController.text,
        dataPretendidaContratacao: _dataPretendida,
        grauPrioridade: _grauPrioridadeController.text,
        correlacaoPlanejamento: _correlacaoController.text,
        integranteRequisitanteNome: _reqNomeController.text,
        integranteRequisitanteMatricula: _reqMatriculaController.text,
        integranteRequisitanteLotacao: _reqLotacaoController.text,
        integranteTecnico1Nome:
            _tec1NomeController.text.isEmpty ? null : _tec1NomeController.text,
        integranteTecnico1Matricula: _tec1MatriculaController.text.isEmpty
            ? null
            : _tec1MatriculaController.text,
        integranteTecnico1Lotacao: _tec1LotacaoController.text.isEmpty
            ? null
            : _tec1LotacaoController.text,
        integranteTecnico2Nome:
            _tec2NomeController.text.isEmpty ? null : _tec2NomeController.text,
        integranteTecnico2Matricula: _tec2MatriculaController.text.isEmpty
            ? null
            : _tec2MatriculaController.text,
        integranteTecnico2Lotacao: _tec2LotacaoController.text.isEmpty
            ? null
            : _tec2LotacaoController.text,
        matrizItem: _matrizItemController.text,
        matrizG: _matrizG,
        matrizU: _matrizU,
        matrizT: _matrizT,
        localizacao: _localController.text,
        dataAssinatura: _dataAssinatura,
        responsavel1: _resp1Controller.text,
        responsavel2:
            _resp2Controller.text.isEmpty ? null : _resp2Controller.text,
        responsavel3:
            _resp3Controller.text.isEmpty ? null : _resp3Controller.text,
        categoriaItens: _categoriaItens,
        classificacaoRenem: _classificacaoRenem,
        linkSigadoc: linkSigadoc.isEmpty ? null : linkSigadoc,
        itens: _itensSelecionados,
      );

      if (widget.dfd == null) {
        await _repository.createDfd(dfd,
            etpBytes: _etpBytes, etpFileName: _etpFileName);
      } else {
        await _repository.updateDfd(dfd,
            etpBytes: _etpBytes, etpFileName: _etpFileName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('DFD salvo com sucesso!'),
              backgroundColor: Colors.green),
        );
        widget.onSaved?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _selecionarData(BuildContext context, DateTime? atual,
      Function(DateTime) onSelect) async {
    final data = await showDatePicker(
      context: context,
      initialDate: atual ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (data != null) {
      setState(() => onSelect(data));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSelecaoIntegranteTecnico(int qual) {
    final selecionado =
        qual == 1 ? _integranteTecnico1Selecionado : _integranteTecnico2Selecionado;
    final nomeController =
        qual == 1 ? _tec1NomeController : _tec2NomeController;
    final matriculaController =
        qual == 1 ? _tec1MatriculaController : _tec2MatriculaController;
    final lotacaoController =
        qual == 1 ? _tec1LotacaoController : _tec2LotacaoController;

    if (selecionado == null &&
        nomeController.text.trim().isEmpty &&
        matriculaController.text.trim().isEmpty) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.person_add),
        label: Text(qual == 1
            ? 'Selecionar Integrante Técnico 1'
            : 'Selecionar Integrante Técnico 2'),
        onPressed: () => _mostrarSelecaoIntegranteTecnico(qual),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nomeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: matriculaController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Matrícula',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: lotacaoController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Lotação',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Alterar'),
                  onPressed: () => _mostrarSelecaoIntegranteTecnico(qual),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Limpar'),
                  onPressed: () => _limparIntegranteTecnico(qual),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrizGUTCard() {
    final resultado = _matrizG * _matrizU * _matrizT;
    String prioridade;
    Color prioridadeColor;
    IconData prioridadeIcon;
    if (resultado <= 20) {
      prioridade = 'Baixa';
      prioridadeColor = Colors.green;
      prioridadeIcon = Icons.trending_down;
    } else if (resultado <= 60) {
      prioridade = 'Média';
      prioridadeColor = Colors.orange;
      prioridadeIcon = Icons.trending_flat;
    } else {
      prioridade = 'Alta';
      prioridadeColor = Colors.red;
      prioridadeIcon = Icons.trending_up;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Matriz GUT',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gravidade × Urgência × Tendência = Prioridade',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _matrizItemController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Item / Demanda (preenchido pela categoria)',
                border: OutlineInputBorder(),
                filled: true,
                prefixIcon: Icon(Icons.label_outline, size: 22),
              ),
              validator: (v) => v!.isEmpty ? 'Selecione a categoria em "2.1. Itens da Demanda"' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _matrizG,
                    decoration: const InputDecoration(
                      labelText: 'Gravidade (G)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning_amber_outlined),
                    ),
                    items: [1, 2, 3, 4, 5]
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text('$e - ${_labelG(e)}')))
                        .toList(),
                    onChanged: (v) => setState(() => _matrizG = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _matrizU,
                    decoration: const InputDecoration(
                      labelText: 'Urgência (U)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: [1, 2, 3, 4, 5]
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text('$e - ${_labelU(e)}')))
                        .toList(),
                    onChanged: (v) => setState(() => _matrizU = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _matrizT,
                    decoration: const InputDecoration(
                      labelText: 'Tendência (T)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.show_chart),
                    ),
                    items: [1, 2, 3, 4, 5]
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text('$e - ${_labelT(e)}')))
                        .toList(),
                    onChanged: (v) => setState(() => _matrizT = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: prioridadeColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Cálculo',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'G × U × T = $_matrizG × $_matrizU × $_matrizT = $resultado',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(prioridadeIcon, color: prioridadeColor, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Prioridade $prioridade',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: prioridadeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resultado <= 20
                        ? 'Demanda pode ser planejada com menor urgência.'
                        : resultado <= 60
                            ? 'Demanda requer atenção e planejamento adequado.'
                            : 'Demanda de alta prioridade; tratar com urgência.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _labelG(int v) {
    const labels = ['Mínima', 'Baixa', 'Média', 'Alta', 'Crítica'];
    return labels[v - 1];
  }

  static String _labelU(int v) {
    const labels = ['Pode esperar', 'Breve', 'Normal', 'Urgente', 'Imediata'];
    return labels[v - 1];
  }

  static String _labelT(int v) {
    const labels = ['Não piora', 'Piora lento', 'Estável', 'Piora rápido', 'Piora agora'];
    return labels[v - 1];
  }

  Future<dynamic> _mostrarPopupSelecaoItem() async {
    if (_categoriaItens == null) return null;
    return showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.92,
          height: MediaQuery.of(context).size.height * 0.75,
          child: _PopupSelecaoItemContent(
            categoria: _categoriaItens!,
            classificacaoRenem: _classificacaoRenem,
            onSelecionado: (item) => Navigator.of(context).pop(item),
            onCancelar: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  Future<void> _adicionarItem() async {
    if (_categoriaItens == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione a Categoria da Demanda primeiro.')),
      );
      return;
    }

    if (_categoriaItens == 'RENEM' && _classificacaoRenem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione a Classificação do RENEM primeiro.')),
      );
      return;
    }

    dynamic itemSelecionado = await _mostrarPopupSelecaoItem();

    if (itemSelecionado != null) {
      Map<String, dynamic> novoItem = {};

      if (itemSelecionado is ProcedimentoSigtapModel) {
        if (_itensSelecionados
            .any((i) => i['codigo'] == itemSelecionado.coProcedimento)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Este procedimento já foi adicionado!')));
          }
          return;
        }

        novoItem = {
          'codigo': itemSelecionado.coProcedimento,
          'descricao': itemSelecionado.noProcedimento,
          'quantidade': 1,
          'valor_ref': null,
          'valor_unitario': null,
          'opmes': [],
        };

        // Buscar OPMES compatíveis do procedimento
        try {
          final res = await Supabase.instance.client
              .from('sigtap_procedimento_compativel')
              .select('co_procedimento_compativel, qt_permitida')
              .eq('co_procedimento_principal', itemSelecionado.coProcedimento);

          if (res.isNotEmpty) {
            List<Map<String, dynamic>> opmes = [];
            for (var row in res) {
              final coCompativel = row['co_procedimento_compativel'];
              // Pega a descrição
              final descRes = await Supabase.instance.client
                  .from('procedimentos_sigtap')
                  .select('no_procedimento')
                  .eq('co_procedimento', coCompativel)
                  .maybeSingle();

              opmes.add({
                'codigo': coCompativel,
                'descricao': descRes != null
                    ? descRes['no_procedimento']
                    : 'Desconhecido',
                'qt_permitida': row['qt_permitida'],
                'selecionado': true, // Pode desmarcar depois
                'quantidade_usada': 1,
              });
            }
            novoItem['opmes'] = opmes;
          }
        } catch (e) {
          debugPrint('Erro ao buscar opmes: $e');
        }
      } else if (itemSelecionado is RenemModel) {
        if (_itensSelecionados
            .any((i) => i['codigo'] == itemSelecionado.codItem)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Este equipamento já foi adicionado!')));
          }
          return;
        }
        novoItem = {
          'codigo': itemSelecionado.codItem,
          'descricao': itemSelecionado.item,
          'quantidade': 1,
          'valor_ref': itemSelecionado.valorSugerido,
          'valor_estimado': itemSelecionado.valorSugerido,
          'valor_unitario': null,
        };
      } else if (itemSelecionado is CatmedModel) {
        if (_itensSelecionados
            .any((i) => i['codigo'] == itemSelecionado.codigoSiag)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Este medicamento já foi adicionado!')));
          }
          return;
        }
        novoItem = {
          'codigo': itemSelecionado.codigoSiag,
          'descricao': itemSelecionado.descritivoTecnico,
          'quantidade': 1,
          'valor_ref': null,
          'valor_unitario': null,
        };
      }

      setState(() {
        _itensSelecionados.add(novoItem);
      });
    }
  }

  Widget _buildItensSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('2.1. Itens da Demanda'),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Categoria da Demanda',
            border: OutlineInputBorder(),
          ),
          initialValue: _categoriaItens,
          items: const [
            DropdownMenuItem(
                value: 'SIGTAP', child: Text('Procedimentos (SIGTAP)')),
            DropdownMenuItem(
                value: 'RENEM', child: Text('Equipamentos (RENEM)')),
            DropdownMenuItem(
                value: 'CATMED', child: Text('Medicamentos (CATMED)')),
          ],
          onChanged: (val) {
            if (val != _categoriaItens) {
              setState(() {
                _categoriaItens = val;
                _itensSelecionados
                    .clear(); // Limpa itens se mudar a categoria raiz
                if (val != 'RENEM') _classificacaoRenem = null;
                _atualizarMatrizItemDaCategoria();
              });
            }
          },
          validator: (v) =>
              v == null ? 'Obrigatório selecionar a categoria' : null,
        ),
        if (_categoriaItens == 'RENEM') ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              // Lista sem duplicatas para evitar erro do Dropdown (exatamente 1 item com o value)
              final opcoes = _classificacoesRenem.toSet().toList()..sort();
              final valorAtual = _classificacaoRenem != null &&
                      opcoes.contains(_classificacaoRenem)
                  ? _classificacaoRenem
                  : null;
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Classificação RENEM',
                  border: OutlineInputBorder(),
                ),
                // value necessário para evitar assertion quando há duplicatas ou valor fora da lista
                // ignore: deprecated_member_use
                value: valorAtual,
                items: opcoes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != _classificacaoRenem) {
                    setState(() {
                      _classificacaoRenem = val;
                      _itensSelecionados.clear();
                      _atualizarMatrizItemDaCategoria();
                    });
                  }
                },
                validator: (v) => _categoriaItens == 'RENEM' && v == null
                    ? 'Obrigatório selecionar classificação'
                    : null,
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _linkSigadocController,
          decoration: const InputDecoration(
            labelText: 'Link processo SIGADOC',
            hintText: 'Link do processo aberto no SIGADOC (um por DFD)',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _categoriaItens == null ||
                  (_categoriaItens == 'RENEM' && _classificacaoRenem == null)
              ? null
              : _adicionarItem,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Item'),
        ),
        const SizedBox(height: 16),
        if (_itensSelecionados.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: const Text('Nenhum item adicionado à demanda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itensSelecionados.length,
            itemBuilder: (context, index) {
              final item = _itensSelecionados[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item['codigo']} - ${item['descricao']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                if (item['valor_ref'] != null ||
                                    item['valor_estimado'] != null)
                                  Text(
                                      'Valor Ref: R\$ ${((item['valor_ref'] ?? item['valor_estimado']) as num).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: Colors.green, fontSize: 12)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: item['quantidade'].toString(),
                              decoration: const InputDecoration(
                                  labelText: 'Qtd',
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(8)),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                item['quantidade'] = int.tryParse(v) ?? 1;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => setState(
                                () => _itensSelecionados.removeAt(index)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          initialValue: item['valor_unitario'] != null
                              ? (item['valor_unitario'] as num).toStringAsFixed(2)
                              : '',
                          decoration: const InputDecoration(
                            labelText: 'Valor unit. (R\$)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) {
                            final n = double.tryParse(v.replaceAll(',', '.'));
                            item['valor_unitario'] = n;
                          },
                        ),
                      ),
                      if (item['opmes'] != null &&
                          (item['opmes'] as List).isNotEmpty) ...[
                        const Divider(),
                        const Text('OPMEs Compatíveis:',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey)),
                        const SizedBox(height: 4),
                        ...(item['opmes'] as List).map((opme) {
                          return Row(
                            children: [
                              Checkbox(
                                value: opme['selecionado'],
                                onChanged: (v) {
                                  setState(() => opme['selecionado'] = v);
                                },
                              ),
                              Expanded(
                                child: Text(
                                    '${opme['codigo']} - ${opme['descricao']}',
                                    style: const TextStyle(fontSize: 11)),
                              ),
                              if (opme['selecionado'] == true)
                                SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    initialValue:
                                        opme['quantidade_usada'].toString(),
                                    decoration: const InputDecoration(
                                        labelText: 'Qtd',
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(4)),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 11),
                                    onChanged: (v) {
                                      opme['quantidade_usada'] =
                                          int.tryParse(v) ?? 1;
                                    },
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dfd == null ? 'Novo DFD' : 'Editar DFD'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: ConstrainedContent(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'FORMULÁRIO DE FORMALIZAÇÃO DE DEMANDA (DFD)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              _buildSectionTitle('1. Identificação do Setor e Responsável'),
              if (_carregandoOrgao)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(),
                )
              else
                TextFormField(
                  controller: _orgaoController,
                  decoration: const InputDecoration(
                      labelText: 'Órgão', border: OutlineInputBorder()),
                  readOnly: true,
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Unidade Orçamentária',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                initialValue: _unidadeOrcamentariaSelecionada,
                items: _opcoesUnidadeOrcamentaria.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['codigo'],
                    child: Tooltip(
                      message: opt['descricao'],
                      child: Text('${opt['codigo']} - ${opt['descricao']}',
                          overflow: TextOverflow.ellipsis),
                    ),
                  );
                }).toList(),
                isExpanded: true,
                onChanged: (val) {
                  setState(() {
                    _unidadeOrcamentariaSelecionada = val;
                    _unidadeOrcamentariaController.text = val ?? '';
                  });
                },
                validator: (val) {
                  if (val == null &&
                      _unidadeOrcamentariaController.text.isEmpty) {
                    return 'Obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _setorRequisitanteController,
                decoration: const InputDecoration(
                    labelText: 'Setor Requisitante (Unidade/Setor/Depto)',
                    border: OutlineInputBorder()),
                readOnly: true,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _responsavelDemandaController,
                decoration: const InputDecoration(
                    labelText: 'Responsável pela Demanda',
                    border: OutlineInputBorder()),
                readOnly: true,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _matriculaController,
                      decoration: const InputDecoration(
                          labelText: 'Matrícula', border: OutlineInputBorder()),
                      readOnly: true,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSectionTitle('2. Objeto (Solução Preliminar)'),
              DropdownButtonFormField<String>(
                initialValue: _classificacaoObjeto,
                decoration: const InputDecoration(
                    labelText: 'Classificação do Objeto',
                    border: OutlineInputBorder()),
                items: _opcoesClassificacao
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _classificacaoObjeto = v),
                validator: (v) => v == null ? 'Selecione uma opção' : null,
                isExpanded: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoDemandaController,
                decoration: const InputDecoration(
                    labelText: 'Descrição da Demanda',
                    border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              _buildItensSection(),
              _buildSectionTitle('3. Forma de Contratação e Planejamento'),
              DropdownButtonFormField<String>(
                initialValue: _formaContratacao,
                decoration: const InputDecoration(
                    labelText: 'Forma de Contratação Sugerida',
                    border: OutlineInputBorder()),
                items: _opcoesFormaContratacao
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _formaContratacao = v;
                    _atualizarNecessidadeEtp(v);
                  });
                },
                validator: (v) => v == null ? 'Selecione uma opção' : null,
                isExpanded: true,
              ),
              const SizedBox(height: 12),
              if (_formaContratacao != null &&
                  _formaContratacao!.contains('ARP')) ...[
                const Text('Dados da ARP:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _numeroArpController,
                  decoration: const InputDecoration(
                      labelText: 'Número da Ata de Registro de Preço',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _editalArpController,
                  decoration: const InputDecoration(
                      labelText: 'Edital que originou a ARP',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Data de publicação',
                            style: TextStyle(fontSize: 12)),
                        subtitle: Text(_dataPublicacaoArp != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(_dataPublicacaoArp!)
                            : 'Selecionar'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selecionarData(context,
                            _dataPublicacaoArp, (d) => _dataPublicacaoArp = d),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Data de vigência',
                            style: TextStyle(fontSize: 12)),
                        subtitle: Text(_dataVigenciaArp != null
                            ? DateFormat('dd/MM/yyyy').format(_dataVigenciaArp!)
                            : 'Selecionar'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selecionarData(context, _dataVigenciaArp,
                            (d) => _dataVigenciaArp = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (_formaContratacao != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'Sobre o Estudo Técnico Preliminar (ETP)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(_obterDicaEtp(),
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                    'Necessidade de Estudo Técnico Preliminar (ETP)?'),
                value: _necessidadeEtp,
                onChanged: _formaContratacao != null &&
                        (_formaContratacao!.contains('Dispensa'))
                    ? (v) {
                        setState(() {
                          _necessidadeEtp = v;
                          // Se ele desligou (v=false) algo que era padrão True na Dispensa, marca que foi manual
                          _etpRetiradoManualmente = !v;
                        });
                      }
                    : null, // Bloqueado nas outras opções (Modalidades, Adesão e Participante)
              ),
              if (_formaContratacao != null &&
                  _formaContratacao!.contains('Dispensa')) ...[
                if (_etpRetiradoManualmente)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Atenção: ETP Retirado Manualmente',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.deepOrange)),
                              SizedBox(height: 4),
                              Text(
                                'Você indicou que o ETP não é necessário para esta Dispensa/Inexigibilidade. '
                                'Isso só é permitido em casos de baixo valor (Art. 75, I e II) ou situações extremas (emergência/calamidade), desde que plenamente justificado no Termo de Referência (TR).',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Ilustração / Informação Extra sobre Valores
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Limites de Baixo Valor (Art. 75, I e II) - Vigentes',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 8),
                      Text(
                          '• Obras, Serviços de Engenharia ou Manutenção de Veículos:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('   Até R\$ 123.001,84 (Dec. nº 11.871/2023)',
                          style: TextStyle(fontSize: 12)),
                      SizedBox(height: 4),
                      Text('• Outros Serviços e Compras:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('   Até R\$ 61.500,92',
                          style: TextStyle(fontSize: 12)),
                      SizedBox(height: 8),
                      Text(
                        'No MT (Decreto nº 1.525/2022):\n'
                        '- Abaixo desses valores: O ETP é facultativo (pode pular pro TR).\n'
                        '- Acima desses valores: O ETP é obrigatório (exceto emergência).',
                        style: TextStyle(
                            fontSize: 11, fontStyle: FontStyle.italic),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_necessidadeEtp) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Dados do Estudo Técnico Preliminar (ETP)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _etpNumeroController,
                        decoration: const InputDecoration(
                          labelText: 'Número do ETP',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: ETP 029/2025/HRCOL/SES/MT',
                        ),
                        validator: (v) => _necessidadeEtp && v!.trim().isEmpty
                            ? 'Campo obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'O número do ETP ajuda a identificar duplicidades no sistema.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text('Arquivo do ETP (Obrigatório, máx 5MB):',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _anexarEtp,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Anexar Arquivo'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _etpFileName ??
                                  (widget.dfd?.etpFileUrl != null
                                      ? 'Arquivo já anexado'
                                      : 'Nenhum arquivo selecionado'),
                              style: TextStyle(
                                fontSize: 13,
                                color: _etpFileName != null ||
                                        widget.dfd?.etpFileUrl != null
                                    ? Colors.green.shade700
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (widget.dfd?.etpFileUrl != null &&
                          _etpFileName == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Um arquivo já está salvo neste DFD. Anexar um novo irá substituí-lo.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue.shade800),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildSectionTitle('4. Justificativa e Previsão Orçamentária'),
              TextFormField(
                controller: _justificativaController,
                decoration: const InputDecoration(
                    labelText: 'Justificativa da Necessidade da Contratação',
                    border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _demonstracaoPacController,
                decoration: const InputDecoration(
                    labelText: 'Demonstração da Previsão no PAC',
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _recursosController,
                decoration: const InputDecoration(
                    labelText: 'Recursos Orçamentários e Exercício',
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data Pretendida da Contratação'),
                subtitle: Text(_dataPretendida != null
                    ? DateFormat('dd/MM/yyyy').format(_dataPretendida!)
                    : 'Selecionar'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selecionarData(
                    context, _dataPretendida, (d) => _dataPretendida = d),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _grauPrioridadeController,
                decoration: const InputDecoration(
                    labelText: 'Grau de Prioridade da Compra/Contratação',
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _correlacaoController,
                decoration: const InputDecoration(
                    labelText:
                        'Indicação de Correlação com Planejamento Estratégico',
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              _buildSectionTitle('5. Equipe de Planejamento'),
              const Text('Integrante Requisitante:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reqNomeController,
                decoration: const InputDecoration(
                    labelText: 'Nome', border: OutlineInputBorder()),
                readOnly: true,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                    controller: _reqMatriculaController,
                    decoration: const InputDecoration(
                        labelText: 'Matrícula', border: OutlineInputBorder()),
                    readOnly: true,
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextFormField(
                    controller: _reqLotacaoController,
                    decoration: const InputDecoration(
                        labelText: 'Lotação', border: OutlineInputBorder()),
                    readOnly: true,
                  )),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Integrante Técnico 1:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildSelecaoIntegranteTecnico(1),
              const SizedBox(height: 16),
              const Text('Integrante Técnico 2:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildSelecaoIntegranteTecnico(2),
              _buildSectionTitle('6. Matriz de Priorização GUT'),
              _buildMatrizGUTCard(),
              _buildSectionTitle('7. Assinaturas e Localidade'),
              TextFormField(
                controller: _localController,
                decoration: const InputDecoration(
                    labelText: 'Local', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data da Assinatura'),
                subtitle:
                    Text(DateFormat('dd/MM/yyyy').format(_dataAssinatura)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selecionarData(
                    context, _dataAssinatura, (d) => _dataAssinatura = d),
              ),
              const SizedBox(height: 12),
              _buildSelecaoResponsavel(1),
              const SizedBox(height: 12),
              _buildSelecaoResponsavel(2),
              const SizedBox(height: 12),
              _buildSelecaoResponsavel(3),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _salvando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SALVAR DFD',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conteúdo do popup de seleção de item (SIGTAP/RENEM/CATMED) com busca avançada.
class _PopupSelecaoItemContent extends StatefulWidget {
  final String categoria;
  final String? classificacaoRenem;
  final void Function(dynamic) onSelecionado;
  final VoidCallback onCancelar;

  const _PopupSelecaoItemContent({
    required this.categoria,
    this.classificacaoRenem,
    required this.onSelecionado,
    required this.onCancelar,
  });

  @override
  State<_PopupSelecaoItemContent> createState() => _PopupSelecaoItemContentState();
}

class _PopupSelecaoItemContentState extends State<_PopupSelecaoItemContent> {
  final _searchController = TextEditingController();
  List<dynamic> _itens = [];
  bool _loading = true;
  String _termo = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _carregar();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _termo = _searchController.text.trim());
        _carregar();
      }
    });
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    List<dynamic> lista = [];
    try {
      if (widget.categoria == 'SIGTAP') {
        final repo = ProcedimentoRepository();
        final termo = _termo.isEmpty ? null : _termo;
        lista = await repo.getProcedimentos(termoBusca: termo, limite: 100);
      } else if (widget.categoria == 'RENEM') {
        final repo = RenemRepository();
        final termo = _termo.isEmpty ? null : _termo;
        lista = await repo.getEquipamentos(
          termoBusca: termo,
          classificacaoFiltro: widget.classificacaoRenem,
          limite: 100,
        );
      } else if (widget.categoria == 'CATMED') {
        final repo = CatmedRepository();
        final termo = _termo.isEmpty ? null : _termo;
        lista = await repo.getMedicamentos(termoBusca: termo, statusFiltro: 'Ativo', limite: 100);
      }
    } catch (e) {
      debugPrint('Erro ao carregar itens: $e');
    }
    if (mounted) {
      setState(() {
        _itens = lista;
        _loading = false;
      });
    }
  }

  String _titulo() {
    if (widget.categoria == 'SIGTAP') return 'Selecionar Procedimento (SIGTAP)';
    if (widget.categoria == 'RENEM') return 'Selecionar Equipamento (RENEM)';
    return 'Selecionar Medicamento (CATMED)';
  }

  String _subtitulo() {
    if (widget.categoria == 'SIGTAP') return 'Código ou nome do procedimento';
    if (widget.categoria == 'RENEM') return 'Código, item, definição ou especificação';
    return 'Código ou descritivo técnico';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _titulo(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancelar,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Busca avançada',
              hintText: _subtitulo(),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              filled: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _itens.isEmpty
                  ? Center(
                      child: Text(
                        _termo.isEmpty
                            ? 'Nenhum item encontrado.'
                            : 'Nenhum resultado para "$_termo".',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _itens.length,
                      itemBuilder: (context, index) {
                        final item = _itens[index];
                        if (item is ProcedimentoSigtapModel) {
                          return ListTile(
                            title: Text(item.noProcedimento),
                            subtitle: Text('Código: ${item.coProcedimento}'),
                            onTap: () => widget.onSelecionado(item),
                          );
                        }
                        if (item is RenemModel) {
                          final valor = item.valorSugerido;
                          return ListTile(
                            title: Text(item.item ?? ''),
                            subtitle: Text(
                                'Cód: ${item.codItem}${valor != null ? ' • R\$ ${valor.toStringAsFixed(2)}' : ''}'),
                            onTap: () => widget.onSelecionado(item),
                          );
                        }
                        if (item is CatmedModel) {
                          return ListTile(
                            title: Text(item.descritivoTecnico ?? ''),
                            subtitle: Text('Código: ${item.codigoSiag}'),
                            onTap: () => widget.onSelecionado(item),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton(
            onPressed: widget.onCancelar,
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }
}
