import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../modules/atas/models/ata_credor_item_model.dart';
import '../../modules/atas/repositories/ata_repository.dart';
import '../../modules/marcas_fabricantes/models/marca_fabricante_model.dart';
import '../../modules/marcas_fabricantes/repositories/marca_fabricante_repository.dart';
import '../../modules/unidades_medida/models/unidade_medida_model.dart';
import '../../modules/unidades_medida/repositories/unidade_medida_repository.dart';
import '../../utils/input_formatters.dart';

/// Dados de um item na etapa de detalhamento (antes de salvar).
class _ItemDetalhe {
  final int numeroItem;
  final String codigo;
  final String descricaoInicial;
  final String tipoItemPadrao; // 'catmed' | 'renem' | 'cadastro_manual'
  final TextEditingController nomeItem = TextEditingController();
  final TextEditingController especificacao = TextEditingController();
  final TextEditingController quantidade = TextEditingController();
  final TextEditingController valorUnitario = TextEditingController();
  String? marcaFabricanteId;
  String? unidadeMedidaId;

  bool get isCadastroManual => tipoItemPadrao == 'cadastro_manual';

  _ItemDetalhe({
    required this.numeroItem,
    required this.codigo,
    required this.descricaoInicial,
    required this.tipoItemPadrao,
  }) {
    nomeItem.text = descricaoInicial;
    quantidade.text = isCadastroManual ? '' : '0';
    valorUnitario.text = isCadastroManual ? '' : '0,00';
  }

  void dispose() {
    nomeItem.dispose();
    especificacao.dispose();
    quantidade.dispose();
    valorUnitario.dispose();
  }

  double get valorTotal {
    final q = double.tryParse(quantidade.text.replaceAll(',', '.')) ?? 0;
    final v = moedaBrParaDouble(valorUnitario.text);
    return q * v;
  }
}

/// Tela para preencher detalhes dos itens selecionados: nome, especificação, marca, unidade, quantidade e valores.
class DetalharItensAtaScreen extends StatefulWidget {
  const DetalharItensAtaScreen({
    super.key,
    required this.ataId,
    required this.credorId,
    required this.tipoAta,
    required this.numeroAta,
    required this.itensSelecionados,
    this.usuarioLogado,
    this.voltarParaDetalheAta = false,
  });

  final String ataId;
  final String credorId;
  final String tipoAta;
  final String numeroAta;
  final List<Map<String, dynamic>> itensSelecionados;
  final dynamic usuarioLogado;
  /// Quando true, após salvar volta para a tela de detalhe da ata (pop 2x).
  final bool voltarParaDetalheAta;

  @override
  State<DetalharItensAtaScreen> createState() => _DetalharItensAtaScreenState();
}

class _DetalharItensAtaScreenState extends State<DetalharItensAtaScreen> {
  final _ataRepo = AtaRepository();
  final _marcaRepo = MarcaFabricanteRepository();
  final _unidadeRepo = UnidadeMedidaRepository();

  List<_ItemDetalhe> _itens = [];
  List<MarcaFabricanteModel> _marcas = [];
  List<UnidadeMedidaModel> _unidades = [];
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    int num = 1;
    for (final row in widget.itensSelecionados) {
      _itens.add(_ItemDetalhe(
        numeroItem: num++,
        codigo: row['codigo'] as String? ?? '',
        descricaoInicial: row['descricao'] as String? ?? '',
        tipoItemPadrao: row['tipo_item_padrao'] as String? ?? '',
      ));
    }
    _carregarMarcasEUnidades();
  }

  @override
  void dispose() {
    for (final i in _itens) i.dispose();
    super.dispose();
  }

  Future<void> _carregarMarcasEUnidades() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final marcas = await _marcaRepo.getAll();
      final unidades = await _unidadeRepo.getAll();
      if (mounted) setState(() {
        _marcas = marcas;
        _unidades = unidades;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _abrirNovaMarca({String? nomeSugerido}) async {
    final nomeCtrl = TextEditingController(text: nomeSugerido ?? '');
    var similares = <MarcaFabricanteModel>[];
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nova marca/fabricante'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome da marca/fabricante',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  if (similares.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Já existe marca registrada compatível com esta:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange.shade800),
                    ),
                    ...similares.take(3).map((m) => ListTile(dense: true, title: Text(m.nome))),
                    const SizedBox(height: 4),
                    const Text('Deseja usar uma das acima (selecione no dropdown) ou cadastrar mesmo assim?'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              if (similares.isEmpty)
                FilledButton(
                  onPressed: () async {
                    final nome = nomeCtrl.text.trim();
                    if (nome.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome.')));
                      return;
                    }
                    final exato = await _marcaRepo.getPorNomeExato(nome);
                    if (exato != null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta marca já está cadastrada.'), backgroundColor: Colors.orange));
                      return;
                    }
                    final sim = await _marcaRepo.getSimilares(nome);
                    if (sim.isNotEmpty) {
                      setDialogState(() => similares = sim);
                      return;
                    }
                    await _inserirMarca(nome);
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  child: const Text('Cadastrar'),
                )
              else
                FilledButton(
                  onPressed: () async {
                    final nome = nomeCtrl.text.trim();
                    if (nome.isEmpty) return;
                    await _inserirMarca(nome);
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  child: const Text('Cadastrar mesmo assim'),
                ),
            ],
          );
        },
      ),
    );
    nomeCtrl.dispose();
    if (result == true && mounted) await _carregarMarcasEUnidades();
  }

  Future<void> _inserirMarca(String nome) async {
    final user = Supabase.instance.client.auth.currentUser;
    final marca = MarcaFabricanteModel(
      nome: nome,
      usuarioCadastrouNome: widget.usuarioLogado?.nome ?? user?.userMetadata?['nome']?.toString(),
      usuarioCadastrouMatricula: widget.usuarioLogado?.matricula?.toString(),
      dataHoraRegistro: DateTime.now(),
    );
    await _marcaRepo.insert(marca);
  }

  Future<void> _abrirNovaUnidade() async {
    final siglaCtrl = TextEditingController();
    final nomeCtrl = TextEditingController();
    final detalhesCtrl = TextEditingController();
    final categoriaCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova unidade de medida'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: siglaCtrl, decoration: const InputDecoration(labelText: 'Sigla (ex.: UN, GAL)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: detalhesCtrl, decoration: const InputDecoration(labelText: 'Detalhes', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: categoriaCtrl, decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final sigla = siglaCtrl.text.trim();
              if (sigla.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe a sigla.')));
                return;
              }
              final existente = await _unidadeRepo.getPorSigla(sigla);
              if (existente != null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Já existe unidade com esta sigla.'), backgroundColor: Colors.orange));
                return;
              }
              final user = Supabase.instance.client.auth.currentUser;
              final u = UnidadeMedidaModel(
                sigla: sigla,
                nome: nomeCtrl.text.trim().isEmpty ? null : nomeCtrl.text.trim(),
                detalhes: detalhesCtrl.text.trim().isEmpty ? null : detalhesCtrl.text.trim(),
                categoria: categoriaCtrl.text.trim().isEmpty ? null : categoriaCtrl.text.trim(),
                usuarioCadastrouNome: widget.usuarioLogado?.nome ?? user?.userMetadata?['nome']?.toString(),
                usuarioCadastrouMatricula: widget.usuarioLogado?.matricula?.toString(),
                dataHoraRegistro: DateTime.now(),
              );
              await _unidadeRepo.insert(u);
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
    siglaCtrl.dispose();
    nomeCtrl.dispose();
    detalhesCtrl.dispose();
    categoriaCtrl.dispose();
    if (result == true && mounted) await _carregarMarcasEUnidades();
  }

  String? _obterNomeUsuario() => widget.usuarioLogado?.nome ?? Supabase.instance.client.auth.currentUser?.userMetadata?['nome']?.toString();
  String? _obterMatriculaUsuario() => widget.usuarioLogado?.matricula?.toString();

  Future<void> _salvar() async {
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione ao menos um item (do banco ou cadastro manual).')));
      return;
    }
    for (final row in _itens) {
      if (row.isCadastroManual) {
        if (row.nomeItem.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item ${row.numeroItem}: Nome do item é obrigatório no cadastro manual.')));
          return;
        }
        if (row.marcaFabricanteId == null || row.marcaFabricanteId!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item ${row.numeroItem}: Marca/Fabricante é obrigatório no cadastro manual.')));
          return;
        }
        if (row.unidadeMedidaId == null || row.unidadeMedidaId!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item ${row.numeroItem}: Unidade de medida é obrigatória no cadastro manual.')));
          return;
        }
        final q = double.tryParse(row.quantidade.text.replaceAll(',', '.'));
        if (q == null || q <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item ${row.numeroItem}: Quantidade é obrigatória no cadastro manual.')));
          return;
        }
        if (moedaBrParaDouble(row.valorUnitario.text) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item ${row.numeroItem}: Valor unitário é obrigatório no cadastro manual.')));
          return;
        }
      }
    }
    setState(() => _salvando = true);
    try {
      final itens = <AtaCredorItemModel>[];
      final nomeUsuario = _obterNomeUsuario();
      final matriculaUsuario = _obterMatriculaUsuario();
      for (final row in _itens) {
        final qtd = double.tryParse(row.quantidade.text.replaceAll(',', '.')) ?? 0;
        final vUnit = moedaBrParaDouble(row.valorUnitario.text);
        itens.add(AtaCredorItemModel(
          ataCredorId: widget.credorId,
          numeroItem: row.numeroItem,
          descricao: row.nomeItem.text.trim().isEmpty ? null : row.nomeItem.text.trim(),
          nomeItem: row.nomeItem.text.trim().isEmpty ? null : row.nomeItem.text.trim(),
          especificacao: row.especificacao.text.trim().isEmpty ? null : row.especificacao.text.trim(),
          marcaFabricanteId: row.marcaFabricanteId,
          unidadeMedidaId: row.unidadeMedidaId,
          quantidade: qtd,
          valorUnitario: vUnit,
          valorTotal: row.valorTotal,
          codigoItemPadrao: row.codigo.isEmpty ? null : row.codigo,
          tipoItemPadrao: row.tipoItemPadrao,
          descricaoItemPadrao: row.descricaoInicial.isEmpty ? null : row.descricaoInicial,
          usuarioCadastrouNome: row.isCadastroManual ? nomeUsuario : null,
          usuarioCadastrouMatricula: row.isCadastroManual ? matriculaUsuario : null,
        ));
      }
      await _ataRepo.adicionarItensAta(widget.credorId, itens);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itens adicionados à ata.'), backgroundColor: Colors.green));
      if (widget.voltarParaDetalheAta) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(title: Text('Detalhar itens - ${widget.numeroAta}'), backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhar itens - ${widget.numeroAta}'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_erro != null) Padding(padding: const EdgeInsets.all(16), child: Text(_erro!, style: const TextStyle(color: Colors.red))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: () {
                setState(() {
                  _itens.add(_ItemDetalhe(
                    numeroItem: _itens.length + 1,
                    codigo: '',
                    descricaoInicial: '',
                    tipoItemPadrao: 'cadastro_manual',
                  ));
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar item manual (não está no banco)'),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _itens.length,
              itemBuilder: (context, index) {
                final row = _itens[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Item ${row.numeroItem}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            if (row.isCadastroManual) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: const Text('Cadastro manual', style: TextStyle(fontSize: 11)),
                                backgroundColor: Colors.orange.shade100,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: row.nomeItem,
                          decoration: InputDecoration(
                            labelText: 'Nome do item${row.isCadastroManual ? ' *' : ''}',
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: row.especificacao,
                          decoration: const InputDecoration(labelText: 'Especificação (se houver)', border: OutlineInputBorder()),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: row.marcaFabricanteId,
                                decoration: InputDecoration(
                                  labelText: 'Marca/Fabricante${row.isCadastroManual ? ' *' : ''}',
                                  border: const OutlineInputBorder(),
                                ),
                                items: _marcas.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nome))).toList(),
                                onChanged: (v) => setState(() => row.marcaFabricanteId = v),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () async {
                                await _abrirNovaMarca();
                                setState(() {});
                              },
                              tooltip: 'Cadastrar nova marca',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: row.unidadeMedidaId,
                                decoration: InputDecoration(
                                  labelText: 'Unidade de medida${row.isCadastroManual ? ' *' : ''}',
                                  border: const OutlineInputBorder(),
                                ),
                                items: _unidades.map((u) => DropdownMenuItem(value: u.id, child: Text(u.exibicao))).toList(),
                                onChanged: (v) => setState(() => row.unidadeMedidaId = v),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () async {
                                await _abrirNovaUnidade();
                                setState(() {});
                              },
                              tooltip: 'Cadastrar nova unidade',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: row.quantidade,
                                decoration: InputDecoration(
                                  labelText: 'Quantidade${row.isCadastroManual ? ' *' : ''}',
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                                  QuantidadeInputFormatter(),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: row.valorUnitario,
                                decoration: InputDecoration(
                                  labelText: 'Valor unitário R\$${row.isCadastroManual ? ' *' : ''}',
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [MoedaBrInputFormatter()],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Valor total: R\$ ${formatarMoedaBr(row.valorTotal)}', style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(_salvando ? 'Salvando...' : 'Salvar itens na ata'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
