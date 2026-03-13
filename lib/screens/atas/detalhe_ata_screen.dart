import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../modules/atas/models/ata_credor_item_model.dart';
import '../../modules/atas/models/ata_model.dart';
import '../../modules/atas/repositories/ata_repository.dart';
import '../../modules/marcas_fabricantes/models/marca_fabricante_model.dart';
import '../../modules/marcas_fabricantes/repositories/marca_fabricante_repository.dart';
import '../../modules/unidades_medida/models/unidade_medida_model.dart';
import '../../modules/unidades_medida/repositories/unidade_medida_repository.dart';
import '../../utils/input_formatters.dart';
import 'adicionar_credor_ata_screen.dart';
import 'editar_ata_screen.dart';
import 'selecionar_itens_ata_screen.dart';

/// Exibe os detalhes de uma ata já registrada: credores e itens de cada credor.
class DetalheAtaScreen extends StatefulWidget {
  final AtaModel ata;
  final VoidCallback? onExcluido;

  const DetalheAtaScreen({
    super.key,
    required this.ata,
    this.onExcluido,
  });

  @override
  State<DetalheAtaScreen> createState() => _DetalheAtaScreenState();
}

class _DetalheAtaScreenState extends State<DetalheAtaScreen> {
  final _repository = AtaRepository();
  late AtaModel _ata;
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _credoresComItens = [];

  @override
  void initState() {
    super.initState();
    _ata = widget.ata;
    _carregar();
  }

  Future<void> _carregar() async {
    if (_ata.id == null) {
      setState(() => _carregando = false);
      return;
    }
    setState(() => _carregando = true);
    try {
      final lista =
          await _repository.getCredoresComItens(_ata.id!);
      setState(() {
        _credoresComItens = lista;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _excluirAta() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ata'),
        content: const Text(
          'Excluir esta ata por completo? Todos os credores e itens serão removidos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repository.deleteAta(_ata.id!);
      if (!mounted) return;
      widget.onExcluido?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }

  Future<void> _excluirItem(String credorId, String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir item'),
        content: const Text('Remover este item da ata?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repository.deleteItem(itemId);
      if (mounted) _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir item: $e')));
      }
    }
  }

  Future<void> _editarItem(Map<String, dynamic> itemMap) async {
    final id = itemMap['id'] as String?;
    if (id == null) return;
    final nomeController = TextEditingController(text: itemMap['nomeItem']?.toString() ?? itemMap['descricao']?.toString() ?? '');
    final qtdController = TextEditingController(text: (itemMap['quantidade'] as num?)?.toString() ?? '0');
    final valorController = TextEditingController(text: formatarMoedaBr((itemMap['valorUnitario'] as num?)?.toDouble() ?? 0));
    final especController = TextEditingController(text: itemMap['especificacao']?.toString() ?? '');
    String? selectedMarcaId = itemMap['marcaFabricanteId']?.toString();
    String? selectedUnidadeId = itemMap['unidadeMedidaId']?.toString();

    List<MarcaFabricanteModel> marcas = [];
    List<UnidadeMedidaModel> unidades = [];
    try {
      final marcaRepo = MarcaFabricanteRepository();
      final unidadeRepo = UnidadeMedidaRepository();
      marcas = await marcaRepo.getAll();
      unidades = await unidadeRepo.getAll();
    } catch (_) {}

    if (!mounted) return;
    final salvo = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar item'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(labelText: 'Nome / Descrição', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedMarcaId?.isEmpty == true ? null : selectedMarcaId,
                            decoration: const InputDecoration(labelText: 'Marca / Fabricante', border: OutlineInputBorder()),
                            items: marcas.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nome))).toList(),
                            onChanged: (v) => setDialogState(() => selectedMarcaId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: OutlinedButton(
                            onPressed: () async {
                              final nomeMarca = await showDialog<String>(
                                context: context,
                                builder: (ctx2) {
                                  final c = TextEditingController();
                                  return AlertDialog(
                                    title: const Text('Cadastrar marca'),
                                    content: TextField(
                                      controller: c,
                                      decoration: const InputDecoration(
                                        labelText: 'Nome da marca / fabricante',
                                        border: OutlineInputBorder(),
                                      ),
                                      autofocus: true,
                                      onSubmitted: (_) => Navigator.pop(ctx2, c.text.trim()),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancelar')),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E)),
                                        onPressed: () => Navigator.pop(ctx2, c.text.trim()),
                                        child: const Text('Salvar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (nomeMarca != null && nomeMarca.isNotEmpty && mounted) {
                                try {
                                  final repo = MarcaFabricanteRepository();
                                  final nova = await repo.insert(MarcaFabricanteModel(nome: nomeMarca));
                                  marcas.add(nova);
                                  setDialogState(() => selectedMarcaId = nova.id);
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao cadastrar marca: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                            child: const Text('Cadastrar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnidadeId?.isEmpty == true ? null : selectedUnidadeId,
                            decoration: const InputDecoration(labelText: 'Unidade de medida', border: OutlineInputBorder()),
                            items: unidades.map((u) => DropdownMenuItem(value: u.id, child: Text(u.exibicao))).toList(),
                            onChanged: (v) => setDialogState(() => selectedUnidadeId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: OutlinedButton(
                            onPressed: () async {
                              final result = await showDialog<Map<String, String>>(
                                context: context,
                                builder: (ctx2) {
                                  final siglaController = TextEditingController();
                                  final nomeController = TextEditingController();
                                  return AlertDialog(
                                    title: const Text('Cadastrar unidade de medida'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: siglaController,
                                          decoration: const InputDecoration(
                                            labelText: 'Sigla (ex.: UN, CX, ML) *',
                                            border: OutlineInputBorder(),
                                            hintText: 'Obrigatório e não pode repetir',
                                          ),
                                          textCapitalization: TextCapitalization.characters,
                                          autofocus: true,
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: nomeController,
                                          decoration: const InputDecoration(
                                            labelText: 'Nome (opcional)',
                                            border: OutlineInputBorder(),
                                            hintText: 'Ex.: Unidade, Caixa',
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancelar')),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E)),
                                        onPressed: () => Navigator.pop(ctx2, {
                                          'sigla': siglaController.text.trim(),
                                          'nome': nomeController.text.trim(),
                                        }),
                                        child: const Text('Salvar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (result == null || !mounted) return;
                              final sigla = result['sigla']?.trim() ?? '';
                              final nome = result['nome']?.trim();
                              if (sigla.isEmpty) return;
                              final siglaUpper = sigla.toUpperCase();
                              try {
                                final repo = UnidadeMedidaRepository();
                                final existente = await repo.getPorSigla(siglaUpper);
                                if (existente != null) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Já existe uma unidade com esta sigla. Cadastre outra sigla.'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                  return;
                                }
                                final nova = await repo.insert(UnidadeMedidaModel(
                                  sigla: siglaUpper,
                                  nome: (nome != null && nome.isNotEmpty) ? nome : null,
                                ));
                                unidades.add(nova);
                                setDialogState(() => selectedUnidadeId = nova.id);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erro ao cadastrar unidade: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: const Text('Cadastrar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtdController,
                      decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]')), QuantidadeInputFormatter()],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valorController,
                      decoration: const InputDecoration(labelText: 'Valor unitário R\$', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]')), MoedaBrInputFormatter()],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: especController,
                      decoration: const InputDecoration(labelText: 'Especificação', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    if (salvo != true || !mounted) return;
    final qtd = double.tryParse(qtdController.text.replaceAll(',', '.')) ?? 0;
    final vUnit = moedaBrParaDouble(valorController.text);
    final vTotal = qtd * vUnit;
    final item = AtaCredorItemModel(
      id: id,
      ataCredorId: itemMap['ataCredorId'] as String? ?? '',
      numeroItem: itemMap['numeroItem'] is int ? itemMap['numeroItem'] as int : int.tryParse(itemMap['numeroItem']?.toString() ?? '0') ?? 0,
      descricao: nomeController.text.trim().isEmpty ? null : nomeController.text.trim(),
      nomeItem: nomeController.text.trim().isEmpty ? null : nomeController.text.trim(),
      especificacao: especController.text.trim().isEmpty ? null : especController.text.trim(),
      quantidade: qtd,
      valorUnitario: vUnit,
      valorTotal: vTotal,
      codigoItemPadrao: itemMap['codigoItemPadrao']?.toString(),
      tipoItemPadrao: itemMap['tipoItemPadrao']?.toString(),
      descricaoItemPadrao: itemMap['descricaoItemPadrao']?.toString(),
      marcaFabricanteId: selectedMarcaId,
      unidadeMedidaId: selectedUnidadeId,
      usuarioCadastrouNome: itemMap['usuarioCadastrouNome']?.toString(),
      usuarioCadastrouMatricula: itemMap['usuarioCadastrouMatricula']?.toString(),
      createdAt: itemMap['createdAt'] != null ? DateTime.tryParse(itemMap['createdAt'] as String) : null,
    );
    try {
      await _repository.updateItem(item);
      if (mounted) _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ata = _ata;
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe da ata'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar ata',
            onPressed: () async {
              final updated = await Navigator.of(context).push<AtaModel>(
                MaterialPageRoute(
                  builder: (context) => EditarAtaScreen(ata: ata),
                ),
              );
              if (updated != null) setState(() => _ata = updated);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Excluir ata',
            onPressed: _excluirAta,
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
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_erro!, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ata.numeroExibicao,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold),
                              ),
                              if (ata.usuarioCadastrouNome != null && ata.usuarioCadastrouNome!.isNotEmpty)
                                _linha('Cadastrado por', '${ata.usuarioCadastrouNome}${ata.usuarioCadastrouMatricula != null && ata.usuarioCadastrouMatricula!.isNotEmpty ? " (Mat. ${ata.usuarioCadastrouMatricula})" : ""}'),
                              if (ata.dataHoraRegistro != null)
                                _linha('Data/hora registro', DateFormat('dd/MM/yyyy HH:mm:ss').format(ata.dataHoraRegistro!.toLocal())),
                              if (ata.modalidade != null && ata.modalidade!.isNotEmpty)
                                _linha('Modalidade', ata.modalidade!),
                              if (ata.numeroModalidade != null && ata.numeroModalidade!.isNotEmpty)
                                _linha('Número modalidade', ata.numeroModalidade!),
                              if (ata.vigenciaInicio != null || ata.vigenciaFim != null)
                                _linha('Vigência', '${ata.vigenciaInicio != null ? DateFormat('dd/MM/yyyy').format(ata.vigenciaInicio!) : '?'} a ${ata.vigenciaFim != null ? DateFormat('dd/MM/yyyy').format(ata.vigenciaFim!) : '?'}'),
                              if (ata.statusVigencia != null && ata.statusVigencia!.isNotEmpty)
                                _linha('Status vigência', ata.statusVigencia!),
                              if (ata.detalhamento != null && ata.detalhamento!.isNotEmpty)
                                _linha('Detalhamento', ata.detalhamento!),
                              if (ata.anoCompetencia != null)
                                _linha('Ano competência', ata.anoCompetencia.toString()),
                              if (ata.numeroProcessoAdministrativo != null && ata.numeroProcessoAdministrativo!.isNotEmpty)
                                _linha('Processo administrativo', ata.numeroProcessoAdministrativo!),
                              if (ata.linkProcessoAdministrativo != null && ata.linkProcessoAdministrativo!.isNotEmpty)
                                _linha('Link processo', ata.linkProcessoAdministrativo!),
                              if (ata.tipoAta != null && ata.tipoAta!.isNotEmpty)
                                _linha('Tipo da ata', ata.tipoAta!),
                              if (ata.orgao != null && ata.orgao!.isNotEmpty)
                                _linha('Órgão', ata.orgao!),
                              if (ata.objeto != null && ata.objeto!.isNotEmpty)
                                _linha('Objeto', ata.objeto!),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Credores e itens',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_business),
                        label: const Text('Cadastrar mais credores'),
                        onPressed: () async {
                          final cnpjsJaNaAta = _credoresComItens
                              .map((c) => (c['cnpj']?.toString() ?? '').replaceAll(RegExp(r'[^\d]'), ''))
                              .where((c) => c.length == 14)
                              .toList();
                          final adicionou = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => AdicionarCredorAtaScreen(
                                ataId: _ata.id!,
                                numeroAta: _ata.numeroExibicao,
                                cnpjsJaNaAta: cnpjsJaNaAta,
                              ),
                            ),
                          );
                          if (adicionou == true) _carregar();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E1E1E),
                          side: const BorderSide(color: Color(0xFF1E1E1E)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_credoresComItens.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Nenhum credor registrado para esta ata.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        )
                      else
                        ..._credoresComItens.map((credor) {
                          final razao =
                              credor['razaoSocial']?.toString() ?? 'Credor';
                          final cnpj =
                              credor['cnpj']?.toString() ?? '';
                          final nomeFantasia = credor['nomeFantasia']?.toString();
                          final endereco = credor['endereco']?.toString();
                          final contato = credor['contato']?.toString();
                          final situacao = credor['situacao']?.toString();
                          final repNome = credor['representanteNome']?.toString();
                          final repCpf = credor['representanteCpf']?.toString();
                          final repRg = credor['representanteRg']?.toString();
                          final repContato = credor['representanteContato']?.toString();
                          final repEmail = credor['representanteEmail']?.toString();
                          final itens =
                              credor['itens'] as List<dynamic>? ?? [];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Text(
                                razao,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (cnpj.isNotEmpty) Text('CNPJ: $cnpj'),
                                  if (nomeFantasia != null && nomeFantasia.isNotEmpty) Text('Nome fantasia: $nomeFantasia'),
                                  if (repNome != null && repNome.isNotEmpty) Text('Representante: $repNome'),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (endereco != null && endereco.isNotEmpty) _linha('Endereço', endereco),
                                      if (contato != null && contato.isNotEmpty) _linha('Contato', contato),
                                      if (situacao != null && situacao.isNotEmpty) _linha('Situação', situacao),
                                      if (repCpf != null && repCpf.isNotEmpty) _linha('CPF rep.', mascararCpf(repCpf)),
                                      if (repRg != null && repRg.isNotEmpty) _linha('RG rep.', mascararRg(repRg)),
                                      if (repContato != null && repContato.isNotEmpty) _linha('Contato rep.', repContato),
                                      if (repEmail != null && repEmail.isNotEmpty) _linha('E-mail rep.', repEmail),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Itens', style: Theme.of(context).textTheme.titleSmall),
                                          TextButton.icon(
                                            icon: const Icon(Icons.add_circle_outline, size: 18),
                                            label: const Text('Cadastrar mais itens'),
                                            onPressed: () async {
                                              final credorId = credor['id'] as String?;
                                              final tipoAta = ata.tipoAta ?? 'medicamento';
                                              if (credorId == null) return;
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => SelecionarItensAtaScreen(
                                                    ataId: ata.id!,
                                                    credorId: credorId,
                                                    tipoAta: tipoAta,
                                                    numeroAta: ata.numeroExibicao,
                                                    usuarioLogado: null,
                                                    voltarParaDetalheAta: true,
                                                  ),
                                                ),
                                              );
                                              if (mounted) _carregar();
                                            },
                                          ),
                                        ],
                                      ),
                                      ...itens
                                        .map<Widget>((e) {
                                          final item = Map<String, dynamic>.from(
                                              e is Map ? e : <String, dynamic>{});
                                          final desc = item['descricao']?.toString() ?? item['nomeItem']?.toString() ?? 'Item ${item['numeroItem']}';
                                          final qtd = (item['quantidade'] as num?)?.toDouble() ?? 0.0;
                                          final vUnit = (item['valorUnitario'] as num?)?.toDouble() ?? 0.0;
                                          final vTotal = (item['valorTotal'] as num?)?.toDouble() ?? 0.0;
                                          final isManual = item['tipoItemPadrao'] == 'cadastro_manual' ||
                                              (item['usuarioCadastrouNome'] != null && (item['usuarioCadastrouNome'] as String).isNotEmpty);
                                          final nomeCadastrou = item['usuarioCadastrouNome']?.toString();
                                          final matriculaCadastrou = item['usuarioCadastrouMatricula']?.toString();
                                          final createdAt = item['createdAt'];
                                          DateTime? dt;
                                          if (createdAt != null) {
                                            if (createdAt is DateTime) dt = createdAt;
                                            else if (createdAt is String) dt = DateTime.tryParse(createdAt);
                                          }
                                          final dataHoraStr = dt != null
                                              ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                                              : null;
                                          final itemId = item['id'] as String?;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      if (isManual)
                                                        Padding(
                                                          padding: const EdgeInsets.only(bottom: 4),
                                                          child: Chip(
                                                            label: const Text('Cadastro manual', style: TextStyle(fontSize: 11)),
                                                            backgroundColor: Colors.orange.shade100,
                                                            padding: EdgeInsets.zero,
                                                          ),
                                                        ),
                                                      Text(
                                                        desc,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500),
                                                      ),
                                                      Text(
                                                        'Qtd: $qtd · Unit: ${nf.format(vUnit)} · Total: ${nf.format(vTotal)}',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                      ),
                                                      if (isManual && (nomeCadastrou != null || matriculaCadastrou != null || dataHoraStr != null))
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 4),
                                                          child: Text(
                                                            'Cadastrado por ${nomeCadastrou ?? '—'}${matriculaCadastrou != null ? ' ($matriculaCadastrou)' : ''}${dataHoraStr != null ? ' em $dataHoraStr' : ''}',
                                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (itemId != null)
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit, size: 20),
                                                        tooltip: 'Editar item',
                                                        onPressed: () => _editarItem(item),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.delete, size: 20, color: Colors.red.shade700),
                                                        tooltip: 'Excluir item',
                                                        onPressed: () => _excluirItem(credor['id'] as String? ?? '', itemId),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _linha(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
