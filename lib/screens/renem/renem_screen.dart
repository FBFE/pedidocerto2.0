import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../modules/renem/models/renem_model.dart';
import '../../modules/renem/repositories/renem_repository.dart';
import '../../widgets/constrained_content.dart';
import 'importar_renem_screen.dart';

class RenemScreen extends StatefulWidget {
  final bool isSelecting;
  final String? initialClassificacao;
  final VoidCallback? onBack;
  const RenemScreen(
      {super.key, this.isSelecting = false, this.initialClassificacao, this.onBack});

  @override
  State<RenemScreen> createState() => _RenemScreenState();
}

class _RenemScreenState extends State<RenemScreen> {
  final _repository = RenemRepository();
  final _buscaController = TextEditingController();

  final List<RenemModel> _equipamentos = [];
  bool _carregando = false;
  String? _erro;

  // Filtros
  String _classificacaoSelecionada = 'Todas';
  List<String> _opcoesClassificacao = ['Todas'];

  // Paginação
  int _offset = 0;
  static const int _limite = 50;
  bool _temMais = true;
  Timer? _debounce;

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    if (widget.initialClassificacao != null) {
      _classificacaoSelecionada = widget.initialClassificacao!;
    }
    _carregarFiltros();
    _carregar();
  }

  Future<void> _carregarFiltros() async {
    try {
      final classificacoes = await _repository.getClassificacoes();
      if (mounted) {
        setState(() {
          _opcoesClassificacao = ['Todas', ...classificacoes];
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar classificações: $e');
    }
  }

  void _resetarPaginacaoEBuscar() {
    _offset = 0;
    _equipamentos.clear();
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
      final novos = await _repository.getEquipamentos(
        termoBusca: _buscaController.text,
        classificacaoFiltro: _classificacaoSelecionada,
        limite: _limite,
        offset: _offset,
      );

      if (mounted) {
        setState(() {
          if (novos.length < _limite) {
            _temMais = false;
          }
          _equipamentos.addAll(novos);
          _offset += novos.length;
          _carregando = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _erro = '$e\n$st';
          _carregando = false;
        });
      }
    }
  }

  void _mostrarDetalhes(RenemModel m) {
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
                    const Icon(Icons.precision_manufacturing,
                        color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    const Text('Detalhes do Equipamento',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Text(
                        'Cód. ${m.codItem}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar Classificação',
                      onPressed: () {
                        Navigator.of(context).pop();
                        _editarClassificacao(m);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                const Divider(),
                Container(
                  color: Colors.blueGrey.withValues(alpha: 0.05),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    m.item ?? 'Sem nome',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300)),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRowCustom('Classificação:', m.classificacao ?? '-'),
                      _infoRowCustom(
                        'Valor Sugerido:',
                        m.valorSugerido != null
                            ? _currencyFormat.format(m.valorSugerido)
                            : 'Não informado',
                        textColor: Colors.green.shade800,
                        isBold: true,
                      ),
                      _infoRowCustom('Item Dolarizado:',
                          m.itemDolarizado == 'S' ? 'Sim' : 'Não'),
                    ],
                  ),
                ),
                if (m.definicao != null && m.definicao!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300)),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRowCustom('Definição:', m.definicao!),
                      ],
                    ),
                  ),
                ],
                if (m.especificacaoSugerida != null &&
                    m.especificacaoSugerida!.isNotEmpty &&
                    m.especificacaoSugerida != 'Clique para Detalhar') ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300)),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRowCustom('Especificação Sugerida:',
                            m.especificacaoSugerida!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRowCustom(String label, String value,
      {Color textColor = Colors.black87, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                    fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }

  void _editarClassificacao(RenemModel m) {
    String classEscolhida = m.classificacao ?? 'Todas';
    if (!_opcoesClassificacao.contains(classEscolhida)) {
      classEscolhida = 'Todas';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Classificação'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Selecione uma das classificações já existentes:'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Nova Classificação',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: classEscolhida,
                    items: _opcoesClassificacao
                        .where((c) => c != 'Todas') // Remover "Todas" da lista de escolha, a menos que ele queira limpar
                        .map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      );
                    }).toList()
                      ..insert(
                          0,
                          const DropdownMenuItem(
                              value: 'Todas',
                              child: Text('Nenhuma / Remover classificação'))),
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() => classEscolhida = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nova = classEscolhida == 'Todas' ? '' : classEscolhida;
                    Navigator.of(context).pop();
                    setState(() => _carregando = true);
                    try {
                      await _repository.updateClassificacao(m.codItem, nova);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Classificação atualizada com sucesso!'),
                              backgroundColor: Colors.green),
                        );
                        _carregarFiltros();
                        _resetarPaginacaoEBuscar();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => _carregando = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Erro ao atualizar: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
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
        title: const Text('Equipamentos (RENEM)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar RENEM',
            onPressed: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => const ImportarRenemScreen(),
                ),
              )
                  .then((_) {
                _carregarFiltros();
                _carregar();
              });
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
                        'Filtros e Pesquisa',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _buscaController,
                              decoration: const InputDecoration(
                                labelText:
                                    'Código, Item, Definição ou Especificação',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: 'Classificação',
                                  border: OutlineInputBorder()),
                              initialValue: _classificacaoSelecionada,
                              items: _opcoesClassificacao.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c,
                                  child:
                                      Text(c, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (widget.isSelecting &&
                                      widget.initialClassificacao != null)
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setState(() =>
                                            _classificacaoSelecionada = val);
                                        _resetarPaginacaoEBuscar();
                                      }
                                    },
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
              else if (_equipamentos.isEmpty && !_carregando)
                const Expanded(
                  child: Center(
                    child: Text('Nenhum equipamento encontrado.'),
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
                        itemCount: _equipamentos.length + (_carregando ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == _equipamentos.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final m = _equipamentos[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.precision_manufacturing,
                                  color: Colors.blueGrey),
                            ),
                            title: Text(m.item ?? 'Sem nome',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                'Cód: ${m.codItem} | Classificação: ${m.classificacao ?? '-'}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  m.valorSugerido != null
                                      ? _currencyFormat.format(m.valorSugerido)
                                      : 'R\$ -',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                                if (m.itemDolarizado == 'S')
                                  const Text('(Dolarizado)',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.orange)),
                              ],
                            ),
                            onTap: () {
                              if (widget.isSelecting) {
                                Navigator.pop(context, m);
                              } else {
                                _mostrarDetalhes(m);
                              }
                            },
                            onLongPress: () => _editarClassificacao(m),
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
