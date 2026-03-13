import 'dart:async';
import 'package:flutter/material.dart';
import '../../modules/catmed/models/catmed_model.dart';
import '../../modules/catmed/repositories/catmed_repository.dart';
import '../../widgets/constrained_content.dart';
import 'importar_catmed_screen.dart';

class CatmedScreen extends StatefulWidget {
  final bool isSelecting;
  const CatmedScreen({super.key, this.isSelecting = false});

  @override
  State<CatmedScreen> createState() => _CatmedScreenState();
}

class _CatmedScreenState extends State<CatmedScreen> {
  final _repository = CatmedRepository();
  final _buscaController = TextEditingController();

  final List<CatmedModel> _medicamentos = [];
  bool _carregando = false;
  String? _erro;

  // Filtros
  String _statusSelecionado = 'Ativo';
  final List<String> _opcoesStatus = ['Ativo', 'Inativo', 'Todos'];

  // Paginação
  int _offset = 0;
  static const int _limite = 50;
  bool _temMais = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _resetarPaginacaoEBuscar() {
    _offset = 0;
    _medicamentos.clear();
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
      final novos = await _repository.getMedicamentos(
        termoBusca: _buscaController.text,
        statusFiltro: _statusSelecionado,
        limite: _limite,
        offset: _offset,
      );

      if (mounted) {
        setState(() {
          if (novos.length < _limite) {
            _temMais = false;
          }
          _medicamentos.addAll(novos);
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

  void _mostrarDetalhes(CatmedModel m) {
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
                    const Icon(Icons.medication, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text('Detalhes do Medicamento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: m.status == 'ativo' ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: m.status == 'ativo' ? Colors.green : Colors.red),
                      ),
                      child: Text(
                        m.status.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: m.status == 'ativo' ? Colors.green.shade800 : Colors.red.shade800, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                const Divider(),
                Container(
                  color: Colors.teal.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${m.codigoSiag} - ${m.descritivoTecnico}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRowCustom('Unidade de Fornecimento:', m.unidade ?? '-'),
                      _infoRowCustom('Embalagem:', m.embalagem ?? '-'),
                      _infoRowCustom('Tipo:', m.tipo ?? '-'),
                      _infoRowCustom('Exemplos Comerciais:', m.exemplos ?? '-'),
                      const Divider(),
                      _infoRowCustom('Classificação ATC:', '${m.codigoAtc ?? ''} ${m.atc != null ? '- ${m.atc}' : ''}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRowCustom('CAP:', m.cap ?? '-', textColor: Colors.teal),
                            _infoRowCustom('CB:', m.cb ?? '-', textColor: Colors.teal),
                            _infoRowCustom('CE:', m.ce ?? '-', textColor: Colors.teal),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRowCustom('PE:', m.pe ?? '-', textColor: Colors.teal),
                            _infoRowCustom('HOSP:', m.hosp ?? '-', textColor: Colors.teal),
                            _infoRowCustom('EX:', m.ex ?? '-', textColor: Colors.teal),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (m.obs != null && m.obs!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRowCustom('Observações:', m.obs!),
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

  Widget _infoRowCustom(String label, String value, {Color textColor = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: textColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos (CATMED)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar CATMED',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ImportarCatmedScreen(),
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
                        'Filtros e Pesquisa',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _buscaController,
                              decoration: const InputDecoration(
                                labelText: 'Código SIAG, Descrição ou Exemplos',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                              initialValue: _statusSelecionado,
                              items: _opcoesStatus.map((s) {
                                return DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _statusSelecionado = val);
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
              else if (_medicamentos.isEmpty && !_carregando)
                const Expanded(
                  child: Center(
                    child: Text('Nenhum medicamento encontrado.'),
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
                        itemCount: _medicamentos.length + (_carregando ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == _medicamentos.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final m = _medicamentos[index];
                          return ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: m.status == 'ativo' ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(m.descritivoTecnico ?? 'Sem descrição', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Código SIAG: ${m.codigoSiag} | Unidade: ${m.unidade ?? '-'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline),
                              tooltip: 'Ver Detalhes',
                              onPressed: () => _mostrarDetalhes(m),
                            ),
                            onTap: () {
                              if (widget.isSelecting) {
                                Navigator.pop(context, m);
                              } else {
                                _mostrarDetalhes(m);
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
