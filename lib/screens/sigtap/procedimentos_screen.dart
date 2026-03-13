import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../modules/sigtap/models/procedimento_model.dart';
import '../../modules/sigtap/repositories/procedimento_repository.dart';
import '../../widgets/constrained_content.dart';
import 'importar_sigtap_screen.dart';

class ProcedimentosScreen extends StatefulWidget {
  final bool isSelecting;
  const ProcedimentosScreen({super.key, this.isSelecting = false});

  @override
  State<ProcedimentosScreen> createState() => _ProcedimentosScreenState();
}

class _ProcedimentosScreenState extends State<ProcedimentosScreen> {
  final _repository = ProcedimentoRepository();
  final _supabase = Supabase.instance.client;
  final _buscaController = TextEditingController();

  final List<ProcedimentoSigtapModel> _procedimentos = [];
  bool _carregando = false;
  String? _erro;

  // Filtros Avançados
  String? _grupoSelecionado;
  String? _subGrupoSelecionado;
  String? _formaOrganizacaoSelecionada;

  // Dados para os dropdowns
  List<Map<String, dynamic>> _grupos = [];
  List<Map<String, dynamic>> _subGrupos = [];
  List<Map<String, dynamic>> _formasOrganizacao = [];

  // Paginação
  int _offset = 0;
  static const int _limite = 50;
  bool _temMais = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _carregarGrupos();
    _carregarFinanciamentos();
    _carregar();
  }

  Future<void> _carregarGrupos() async {
    try {
      final response = await _supabase.from('sigtap_grupo').select('co_grupo, no_grupo').order('co_grupo');
      if (mounted) {
        setState(() {
          _grupos = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar grupos: $e');
    }
  }

  Future<void> _carregarFinanciamentos() async {
    try {
      await _supabase.from('sigtap_financiamento').select('co_financiamento, no_financiamento');
      if (mounted) {
        setState(() {}); // Só recarrega, como não é filtro na tela principal agora
      }
    } catch (_) {}
  }

  Future<void> _carregarSubGrupos(String coGrupo) async {
    try {
      final response = await _supabase
          .from('sigtap_sub_grupo')
          .select('co_sub_grupo, no_sub_grupo')
          .eq('co_grupo', coGrupo)
          .order('co_sub_grupo');
      if (mounted) {
        setState(() {
          _subGrupos = List<Map<String, dynamic>>.from(response);
          _subGrupoSelecionado = null;
          _formasOrganizacao.clear();
          _formaOrganizacaoSelecionada = null;
        });
        _resetarPaginacaoEBuscar();
      }
    } catch (e) {
      debugPrint('Erro ao carregar subgrupos: $e');
    }
  }

  Future<void> _carregarFormasOrganizacao(String coGrupo, String coSubGrupo) async {
    try {
      final response = await _supabase
          .from('sigtap_forma_organizacao')
          .select('co_forma_organizacao, no_forma_organizacao')
          .eq('co_grupo', coGrupo)
          .eq('co_sub_grupo', coSubGrupo)
          .order('co_forma_organizacao');
      if (mounted) {
        setState(() {
          _formasOrganizacao = List<Map<String, dynamic>>.from(response);
          _formaOrganizacaoSelecionada = null;
        });
        _resetarPaginacaoEBuscar();
      }
    } catch (e) {
      debugPrint('Erro ao carregar formas de organizacao: $e');
    }
  }

  void _resetarPaginacaoEBuscar() {
    _offset = 0;
    _procedimentos.clear();
    _temMais = true;
    _carregar();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _resetarPaginacaoEBuscar();
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _carregar({bool loadMore = false}) async {
    if (_carregando || !_temMais) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final novos = await _repository.getProcedimentos(
        termoBusca: _buscaController.text,
        grupo: _grupoSelecionado,
        subGrupo: _subGrupoSelecionado,
        formaOrganizacao: _formaOrganizacaoSelecionada,
        limite: _limite,
        offset: _offset,
      );

      setState(() {
        if (novos.length < _limite) {
          _temMais = false;
        }
        _procedimentos.addAll(novos);
        _offset += novos.length;
        _carregando = false;
      });
    } catch (e, st) {
      setState(() {
        _erro = '$e\n$st';
        _carregando = false;
      });
    }
  }

  void _mostrarDetalhes(ProcedimentoSigtapModel p) async {
    // Buscar as strings de Grupo, SubGrupo e Forma
    String strGrupo = p.coProcedimento.substring(0, 2);
    String strSubGrupo = p.coProcedimento.substring(2, 4);
    String strForma = p.coProcedimento.substring(4, 6);

    String descGrupo = strGrupo;
    String descSub = strSubGrupo;
    String descForma = strForma;
    String descFinanciamento = p.coFinanciamento ?? '-';

    try {
      final g = await _supabase.from('sigtap_grupo').select('no_grupo').eq('co_grupo', strGrupo).maybeSingle();
      if (g != null) descGrupo = '$strGrupo - ${g['no_grupo']}';

      final sg = await _supabase.from('sigtap_sub_grupo').select('no_sub_grupo').eq('co_grupo', strGrupo).eq('co_sub_grupo', strSubGrupo).maybeSingle();
      if (sg != null) descSub = '$strSubGrupo - ${sg['no_sub_grupo']}';

      final f = await _supabase.from('sigtap_forma_organizacao').select('no_forma_organizacao').eq('co_grupo', strGrupo).eq('co_sub_grupo', strSubGrupo).eq('co_forma_organizacao', strForma).maybeSingle();
      if (f != null) descForma = '$strForma - ${f['no_forma_organizacao']}';
      
      // Financiamento: tenta buscar na tabela se importamos
      if (p.coFinanciamento != null) {
        final fin = await _supabase.from('sigtap_financiamento').select('no_financiamento').eq('co_financiamento', p.coFinanciamento!).maybeSingle();
        if (fin != null) descFinanciamento = '${p.coFinanciamento} - ${fin['no_financiamento']}';
      }
    } catch (_) {}

    // Buscar modalidade e complexidade mapeando (opcional se não quiser depender só das tabelas)
    String modalidadeText = 'Ambulatorial Hospitalar Hospital Dia'; // Fixo para exemplo visual, ou busca tabela
    String complexidadeText = p.tpComplexidade == 'Alta Complexidade' ? 'Alta Complexidade' : 'Média Complexidade';
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    const Text('Procedimento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                const Divider(),
                Container(
                  color: Colors.blue.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Procedimento: ${p.coProcedimento.substring(0, 2)}.${p.coProcedimento.substring(2, 4)}.${p.coProcedimento.substring(4, 6)}.${p.coProcedimento.substring(6, 9)}-${p.coProcedimento.substring(9, 10)} - ${p.noProcedimento}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRowCustom('Grupo:', descGrupo),
                      _infoRowCustom('Sub-Grupo:', descSub),
                      _infoRowCustom('Forma de Organização:', descForma),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRowCustom('Competência:', p.dtCompetencia != null && p.dtCompetencia!.length == 6 ? '${p.dtCompetencia!.substring(4, 6)}/${p.dtCompetencia!.substring(0, 4)}' : (p.dtCompetencia ?? 'N/A')),
                      const Divider(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRowCustom('Modalidade de Atendimento:', modalidadeText, textColor: Colors.blue),
                                _infoRowCustom('Complexidade:', complexidadeText, textColor: Colors.blue),
                                _infoRowCustom('Financiamento:', descFinanciamento, textColor: Colors.blue),
                                _infoRowCustom('Instrumento de Registro:', 'BPA (Consolidado) BPA (Individualizado) AIH (Proc. Secundário)', textColor: Colors.blue),
                                _infoRowCustom('Sexo:', p.tpSexo == 'M' ? 'Masculino' : p.tpSexo == 'F' ? 'Feminino' : 'Ambos', textColor: Colors.blue),
                                _infoRowCustom('Dias de Permanência:', '${p.qtDiasPermanencia ?? 0}', textColor: Colors.blue),
                                _infoRowCustom('Quantidade Máxima:', '${p.qtMaximaExecucao ?? 0}', textColor: Colors.blue),
                                _infoRowCustom('Idade Mínima:', '${p.vlIdadeMinima ?? 0} meses', textColor: Colors.blue),
                                _infoRowCustom('Idade Máxima:', '${p.vlIdadeMaxima ?? 999} anos', textColor: Colors.blue),
                                _infoRowCustom('Pontos:', '${p.qtPontos ?? 0}', textColor: Colors.blue),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              color: Colors.grey.shade200,
                              width: double.infinity,
                              child: const Text('Valores', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _infoRowCustom('Serviço Ambulatorial:', 'R\$ ${p.vlSa?.toStringAsFixed(2) ?? '0.00'}', textColor: Colors.blue),
                                        _infoRowCustom('Total Ambulatorial:', 'R\$ ${p.vlSa?.toStringAsFixed(2) ?? '0.00'}', textColor: Colors.blue),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _infoRowCustom('Serviço Hospitalar:', 'R\$ ${p.vlSh?.toStringAsFixed(2) ?? '0.00'}', textColor: Colors.blue),
                                        _infoRowCustom('Serviço Profissional:', 'R\$ ${p.vlSp?.toStringAsFixed(2) ?? '0.00'}', textColor: Colors.blue),
                                        _infoRowCustom('Total Hospitalar:', 'R\$ ${((p.vlSh ?? 0) + (p.vlSp ?? 0)).toStringAsFixed(2)}', textColor: Colors.blue),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRowCustom('Descrição', ''),
                            FutureBuilder<dynamic>(
                              future: _supabase.from('sigtap_descricao').select('ds_procedimento').eq('co_procedimento', p.coProcedimento).maybeSingle(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                                if (snapshot.data == null) return const Text('Sem descrição disponível.', style: TextStyle(fontStyle: FontStyle.italic));
                                return Text(
                                  snapshot.data['ds_procedimento'] ?? '',
                                  style: const TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRowCustom(String label, String value, {Color textColor = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procedimentos SIGTAP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar Base SIGTAP',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ImportarSigtapScreen(),
                ),
              ).then((_) => _carregar());
            },
          ),
        ],
      ),
      body: ConstrainedContent(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Pesquisar Procedimento por',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Grupo', border: OutlineInputBorder()),
                              initialValue: _grupoSelecionado,
                              items: _grupos.map((g) {
                                return DropdownMenuItem<String>(
                                  value: g['co_grupo'],
                                  child: Text('${g['co_grupo']} - ${g['no_grupo']}'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _grupoSelecionado = val;
                                });
                                if (val != null) {
                                  _carregarSubGrupos(val);
                                } else {
                                  setState(() {
                                    _subGrupos.clear();
                                    _subGrupoSelecionado = null;
                                    _formasOrganizacao.clear();
                                    _formaOrganizacaoSelecionada = null;
                                  });
                                  _resetarPaginacaoEBuscar();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Sub-Grupo', border: OutlineInputBorder()),
                              initialValue: _subGrupoSelecionado,
                              items: _subGrupos.map((sg) {
                                return DropdownMenuItem<String>(
                                  value: sg['co_sub_grupo'],
                                  child: Text('${sg['co_sub_grupo']} - ${sg['no_sub_grupo']}'),
                                );
                              }).toList(),
                              onChanged: _grupoSelecionado == null ? null : (val) {
                                setState(() {
                                  _subGrupoSelecionado = val;
                                });
                                if (val != null) {
                                  _carregarFormasOrganizacao(_grupoSelecionado!, val);
                                } else {
                                  setState(() {
                                    _formasOrganizacao.clear();
                                    _formaOrganizacaoSelecionada = null;
                                  });
                                  _resetarPaginacaoEBuscar();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Forma de Organização', border: OutlineInputBorder()),
                              initialValue: _formaOrganizacaoSelecionada,
                              items: _formasOrganizacao.map((fo) {
                                return DropdownMenuItem<String>(
                                  value: fo['co_forma_organizacao'],
                                  child: Text('${fo['co_forma_organizacao']} - ${fo['no_forma_organizacao']}'),
                                );
                              }).toList(),
                              onChanged: _subGrupoSelecionado == null ? null : (val) {
                                setState(() {
                                  _formaOrganizacaoSelecionada = val;
                                });
                                _resetarPaginacaoEBuscar();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _buscaController,
                              decoration: const InputDecoration(
                                labelText: 'Código ou Nome do Procedimento',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_erro != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.withValues(alpha: 0.1),
                  child: Text('Erro: $_erro',
                      style: const TextStyle(color: Colors.red)),
                )
              else if (_procedimentos.isEmpty && !_carregando)
                const Expanded(
                  child: Center(
                    child: Text('Nenhum procedimento encontrado.'),
                  ),
                )
              else
                Expanded(
                  child: Card(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (!_carregando &&
                            _temMais &&
                            scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent - 200) {
                          _carregar(loadMore: true);
                        }
                        return false;
                      },
                      child: ListView.separated(
                        itemCount:
                            _procedimentos.length + (_carregando ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == _procedimentos.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final p = _procedimentos[index];
                          return ListTile(
                            title: Text(p.noProcedimento),
                            subtitle: Text('Código: ${p.coProcedimento}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline),
                              tooltip: 'Ver Detalhes',
                              onPressed: () => _mostrarDetalhes(p),
                            ),
                            onTap: () {
                              if (widget.isSelecting) {
                                Navigator.pop(context, p);
                              } else {
                                _mostrarDetalhes(p);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
