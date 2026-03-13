import 'package:flutter/material.dart';

import '../../modules/catmed/repositories/catmed_repository.dart';
import '../../modules/renem/repositories/renem_repository.dart';
import 'detalhar_itens_ata_screen.dart';

/// Tela para selecionar itens do banco (medicamento/material/opme). Em seguida abre a etapa de detalhar itens.
class SelecionarItensAtaScreen extends StatefulWidget {
  const SelecionarItensAtaScreen({
    super.key,
    required this.ataId,
    required this.credorId,
    required this.tipoAta,
    required this.numeroAta,
    this.usuarioLogado,
    this.voltarParaDetalheAta = false,
  });

  final String ataId;
  final String credorId;
  final String tipoAta;
  final String numeroAta;
  final dynamic usuarioLogado;
  /// Quando true, após salvar itens volta para a tela de detalhe da ata em vez do início.
  final bool voltarParaDetalheAta;

  @override
  State<SelecionarItensAtaScreen> createState() => _SelecionarItensAtaScreenState();
}

class _SelecionarItensAtaScreenState extends State<SelecionarItensAtaScreen> {
  final _catmedRepo = CatmedRepository();
  final _renemRepo = RenemRepository();

  List<Map<String, dynamic>> _itensBanco = [];
  final Set<int> _selecionados = {};
  final _termoBusca = TextEditingController();
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  @override
  void dispose() {
    _termoBusca.dispose();
    super.dispose();
  }

  Future<void> _carregarItens() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _itensBanco = [];
    });
    try {
      if (widget.tipoAta == 'medicamento') {
        final list = await _catmedRepo.getMedicamentos(termoBusca: _termoBusca.text.trim().isEmpty ? null : _termoBusca.text.trim(), limite: 200);
        setState(() {
          _itensBanco = list.asMap().entries.map((e) {
            final m = e.value;
            return {
              'index': e.key,
              'codigo': m.codigoSiag,
              'descricao': m.descritivoTecnico ?? m.codigoSiag,
              'tipo_item_padrao': 'catmed',
            };
          }).toList();
          _carregando = false;
        });
      } else {
        // material e opme: renem_equipamentos (OPME usa o mesmo banco; filtrar por classificacao 'OPME' se existir)
        final list = await _renemRepo.getEquipamentos(
          termoBusca: _termoBusca.text.trim().isEmpty ? null : _termoBusca.text.trim(),
          classificacaoFiltro: widget.tipoAta == 'opme' ? 'OPME' : null,
          limite: 200,
        );
        // Se tipo opme e não há classificacao OPME no banco, busca todos
        final listaRenem = list.isNotEmpty
            ? list
            : await _renemRepo.getEquipamentos(termoBusca: _termoBusca.text.trim().isEmpty ? null : _termoBusca.text.trim(), limite: 200);
        setState(() {
          _itensBanco = listaRenem.asMap().entries.map((e) {
            final r = e.value;
            return {
              'index': e.key,
              'codigo': r.codItem,
              'descricao': r.item ?? r.definicao ?? r.codItem,
              'tipo_item_padrao': 'renem',
            };
          }).toList();
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  void _irParaDetalharItens() {
    final itensSelecionados = _selecionados
        .where((idx) => idx < _itensBanco.length)
        .map((idx) => Map<String, dynamic>.from(_itensBanco[idx]))
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalharItensAtaScreen(
          ataId: widget.ataId,
          credorId: widget.credorId,
          tipoAta: widget.tipoAta,
          numeroAta: widget.numeroAta,
          itensSelecionados: itensSelecionados,
          usuarioLogado: widget.usuarioLogado,
          voltarParaDetalheAta: widget.voltarParaDetalheAta,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipoLabel = widget.tipoAta == 'medicamento'
        ? 'Medicamentos (CATMED)'
        : widget.tipoAta == 'opme'
            ? 'OPME (RENEM)'
            : 'Material (RENEM)';

    return Scaffold(
      appBar: AppBar(
        title: Text('Itens da ata ${widget.numeroAta}'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _termoBusca,
                    decoration: const InputDecoration(
                      labelText: 'Buscar',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _carregarItens(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _carregando ? null : _carregarItens,
                  tooltip: 'Buscar',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              tipoLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(height: 8),
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_erro!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _itensBanco.isEmpty
                    ? const Center(child: Text('Nenhum item encontrado. Faça uma busca ou altere o filtro.'))
                    : ListView.builder(
                        itemCount: _itensBanco.length,
                        itemBuilder: (context, index) {
                          final item = _itensBanco[index];
                          final codigo = item['codigo'] as String? ?? '';
                          final descricao = item['descricao'] as String? ?? '';
                          final selected = _selecionados.contains(index);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selecionados.add(index);
                                } else {
                                  _selecionados.remove(index);
                                }
                              });
                            },
                            title: Text(descricao, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(codigo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('${_selecionados.length} item(ns) selecionado(s)', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _irParaDetalharItens,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Próximo: detalhar itens'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
