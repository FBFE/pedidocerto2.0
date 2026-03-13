import 'package:flutter/material.dart';

import '../../modules/unidades_lotacao/models/governo_model.dart';
import '../../modules/unidades_lotacao/models/secretaria_adjunta_model.dart';
import '../../modules/unidades_lotacao/models/secretaria_model.dart';
import '../../modules/unidades_lotacao/models/setor_model.dart';
import '../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../modules/unidades_lotacao/repositories/governo_repository.dart';
import '../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';

// ---------------------------------------------------------------------------
// Dados do organograma
// ---------------------------------------------------------------------------

class OrganogramaData {
  OrganogramaData({
    required this.governo,
    required this.secretarias,
    required this.adjuntasBySecretaria,
    required this.unidadesBySecretaria,
    required this.setoresByAdjunta,
    required this.setoresByUnidade,
  });

  final GovernoModel governo;
  final List<SecretariaModel> secretarias;
  final Map<String, List<SecretariaAdjuntaModel>> adjuntasBySecretaria;
  final Map<String, List<UnidadeHospitalarModel>> unidadesBySecretaria;
  final Map<String, List<SetorModel>> setoresByAdjunta;
  final Map<String, List<SetorModel>> setoresByUnidade;
}

// ---------------------------------------------------------------------------
// Constantes de layout (vínculo visual claro e proporcional)
// ---------------------------------------------------------------------------

const _cardW = 200.0;
const _gap = 12.0;
const _lineW = 3.0;
const _vertH = 20.0;
const _dropH = 16.0;

double _rowWidth(int n) => n * _cardW + (n > 1 ? (n - 1) * _gap : 0);

const _cores = [
  Color(0xFF1B4965),
  Color(0xFF009688),
  Color(0xFFE91E63),
  Color(0xFFFF9800),
  Color(0xFF2196F3),
];

// ---------------------------------------------------------------------------
// Conector: vertical → horizontal → uma vertical por filho
// ---------------------------------------------------------------------------

class _Conector extends StatelessWidget {
  const _Conector({required this.n, this.cor});

  final int n;
  final Color? cor;

  Color get c => cor ?? _cores[0];

  @override
  Widget build(BuildContext context) {
    if (n <= 0) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(child: Container(width: _lineW, height: _vertH, color: c)),
        Container(height: _lineW, width: _rowWidth(n), color: c),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              SizedBox(
                width: _cardW,
                child: Center(
                  child: Container(width: _lineW, height: _dropH, color: c),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card de nó: título, "Vinculado a: X", botão alterar vínculo, ações
// ---------------------------------------------------------------------------

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.titulo,
    this.subtitulo,
    this.logoUrl,
    required this.cor,
    this.vinculadoA,
    this.onAlterarVinculo,
    this.onAdd,
    this.onEdit,
    this.addTooltip,
  });

  final String titulo;
  final String? subtitulo;
  final String? logoUrl;
  final Color cor;
  final String? vinculadoA;
  final VoidCallback? onAlterarVinculo;
  final VoidCallback? onAdd;
  final VoidCallback? onEdit;
  final String? addTooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _cardW,
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logoUrl != null && logoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                logoUrl!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.business, color: Colors.white, size: 36),
              ),
            ),
          if (logoUrl != null && logoUrl!.isNotEmpty) const SizedBox(height: 6),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitulo != null && subtitulo!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitulo!,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (vinculadoA != null && vinculadoA!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.link, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Vinculado a: $vinculadoA',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onAlterarVinculo != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz,
                        size: 18, color: Colors.white),
                    onPressed: onAlterarVinculo,
                    tooltip: 'Alterar vínculo',
                    style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(28, 28)),
                  ),
                ],
              ],
            ),
          ],
          if (onAdd != null || onEdit != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onAdd != null)
                  IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          size: 20, color: Colors.white),
                      onPressed: onAdd,
                      tooltip: addTooltip ?? 'Adicionar'),
                if (onEdit != null)
                  IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: Colors.white),
                      onPressed: onEdit,
                      tooltip: 'Editar'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Árvore do organograma (com expandir/recolher)
// ---------------------------------------------------------------------------

class OrganogramaTree extends StatefulWidget {
  const OrganogramaTree({
    super.key,
    required this.data,
    required this.governoRepo,
    required this.unidadeRepo,
    this.onGovernoEdit,
    this.onAddSecretaria,
    this.onAddFilhoSecretaria,
    this.onSecretariaEdit,
    this.onAdjuntaEdit,
    this.onUnidadeEdit,
    this.onSetorAdd,
    this.onSetorEdit,
    this.onAlterarVinculoSecretaria,
    this.onAlterarVinculoAdjunta,
    this.onAlterarVinculoUnidade,
    this.onAlterarVinculoSetor,
  });

  final OrganogramaData data;
  final GovernoRepository governoRepo;
  final UnidadeHospitalarRepository unidadeRepo;
  final VoidCallback? onGovernoEdit;
  final VoidCallback? onAddSecretaria;
  final void Function(SecretariaModel)? onAddFilhoSecretaria;
  final void Function(SecretariaModel)? onSecretariaEdit;
  final void Function(SecretariaAdjuntaModel)? onAdjuntaEdit;
  final void Function(UnidadeHospitalarModel)? onUnidadeEdit;
  final void Function(String parentId, bool isAdjunta)? onSetorAdd;
  final void Function(SetorModel)? onSetorEdit;
  final void Function(SecretariaModel)? onAlterarVinculoSecretaria;
  final void Function(SecretariaAdjuntaModel)? onAlterarVinculoAdjunta;
  final void Function(UnidadeHospitalarModel)? onAlterarVinculoUnidade;
  final void Function(SetorModel)? onAlterarVinculoSetor;

  @override
  State<OrganogramaTree> createState() => _OrganogramaTreeState();
}

class _OrganogramaTreeState extends State<OrganogramaTree> {
  final Set<String> _secretariaAberta = {};
  final Set<String> _filhoAberto = {};

  bool _secAberta(String? id) => id != null && !_secretariaAberta.contains(id);
  bool _filhoAbertoF(String? id) => id != null && !_filhoAberto.contains(id);

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final gov = d.governo;
    final govLogo = gov.logoUrl != null && gov.logoUrl!.isNotEmpty
        ? widget.governoRepo.logoPublicUrl(gov.logoUrl)
        : null;
    final temSecretarias = d.secretarias.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Governo
            _NodeCard(
              titulo: gov.nome,
              subtitulo: gov.sigla,
              logoUrl: govLogo,
              cor: _cores[0],
              onAdd: widget.onAddSecretaria,
              onEdit: widget.onGovernoEdit,
              addTooltip: 'Adicionar Secretaria',
            ),
            if (temSecretarias) ...[
              const SizedBox(height: 12),
              _Conector(n: d.secretarias.length, cor: _cores[1]),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < d.secretarias.length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: _cardW,
                      child: _ColunaSecretaria(
                        governoNome: gov.nome,
                        secretaria: d.secretarias[i],
                        adjuntas:
                            d.adjuntasBySecretaria[d.secretarias[i].id] ?? [],
                        unidades:
                            d.unidadesBySecretaria[d.secretarias[i].id] ?? [],
                        setoresByAdjunta: d.setoresByAdjunta,
                        setoresByUnidade: d.setoresByUnidade,
                        unidadeRepo: widget.unidadeRepo,
                        cor: _cores[(i % (_cores.length - 1)) + 1],
                        aberta: _secAberta(d.secretarias[i].id),
                        onToggle: () => setState(() {
                          final id = d.secretarias[i].id ?? '';
                          if (_secretariaAberta.contains(id)) {
                            _secretariaAberta.remove(id);
                          } else {
                            _secretariaAberta.add(id);
                          }
                        }),
                        filhoAberto: _filhoAbertoF,
                        onToggleFilho: (id) => setState(() {
                          if (_filhoAberto.contains(id)) {
                            _filhoAberto.remove(id);
                          } else {
                            _filhoAberto.add(id);
                          }
                        }),
                        onSecretariaEdit: widget.onSecretariaEdit,
                        onAddFilho: widget.onAddFilhoSecretaria,
                        onAdjuntaEdit: widget.onAdjuntaEdit,
                        onUnidadeEdit: widget.onUnidadeEdit,
                        onSetorAdd: widget.onSetorAdd,
                        onSetorEdit: widget.onSetorEdit,
                        onAlterarVinculoSecretaria:
                            widget.onAlterarVinculoSecretaria,
                        onAlterarVinculoAdjunta: widget.onAlterarVinculoAdjunta,
                        onAlterarVinculoUnidade: widget.onAlterarVinculoUnidade,
                        onAlterarVinculoSetor: widget.onAlterarVinculoSetor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Uma coluna: Secretaria + (se aberta) conector + filhos (adjuntas + unidades)
// ---------------------------------------------------------------------------

class _ColunaSecretaria extends StatelessWidget {
  const _ColunaSecretaria({
    required this.governoNome,
    required this.secretaria,
    required this.adjuntas,
    required this.unidades,
    required this.setoresByAdjunta,
    required this.setoresByUnidade,
    required this.unidadeRepo,
    required this.cor,
    required this.aberta,
    required this.onToggle,
    required this.filhoAberto,
    required this.onToggleFilho,
    this.onSecretariaEdit,
    this.onAddFilho,
    this.onAdjuntaEdit,
    this.onUnidadeEdit,
    this.onSetorAdd,
    this.onSetorEdit,
    this.onAlterarVinculoSecretaria,
    this.onAlterarVinculoAdjunta,
    this.onAlterarVinculoUnidade,
    this.onAlterarVinculoSetor,
  });

  final String governoNome;
  final SecretariaModel secretaria;
  final List<SecretariaAdjuntaModel> adjuntas;
  final List<UnidadeHospitalarModel> unidades;
  final Map<String, List<SetorModel>> setoresByAdjunta;
  final Map<String, List<SetorModel>> setoresByUnidade;
  final UnidadeHospitalarRepository unidadeRepo;
  final Color cor;
  final bool aberta;
  final VoidCallback onToggle;
  final bool Function(String? id) filhoAberto;
  final void Function(String id) onToggleFilho;
  final void Function(SecretariaModel)? onSecretariaEdit;
  final void Function(SecretariaModel)? onAddFilho;
  final void Function(SecretariaAdjuntaModel)? onAdjuntaEdit;
  final void Function(UnidadeHospitalarModel)? onUnidadeEdit;
  final void Function(String, bool)? onSetorAdd;
  final void Function(SetorModel)? onSetorEdit;
  final void Function(SecretariaModel)? onAlterarVinculoSecretaria;
  final void Function(SecretariaAdjuntaModel)? onAlterarVinculoAdjunta;
  final void Function(UnidadeHospitalarModel)? onAlterarVinculoUnidade;
  final void Function(SetorModel)? onAlterarVinculoSetor;

  static const _coresFilho = [
    Color(0xFF009688),
    Color(0xFFE91E63),
    Color(0xFFFF9800),
    Color(0xFF2196F3)
  ];

  @override
  Widget build(BuildContext context) {
    final total = adjuntas.length + unidades.length;
    final temFilhos = total > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: temFilhos ? onToggle : null,
          child: _NodeCard(
            titulo: secretaria.nome,
            subtitulo: secretaria.sigla,
            cor: cor,
            vinculadoA: governoNome,
            onAlterarVinculo: onAlterarVinculoSecretaria != null
                ? () => onAlterarVinculoSecretaria!(secretaria)
                : null,
            onEdit: onSecretariaEdit != null
                ? () => onSecretariaEdit!(secretaria)
                : null,
            onAdd: onAddFilho != null ? () => onAddFilho!(secretaria) : null,
            addTooltip: 'Adicionar (Adjunta ou Unidade)',
          ),
        ),
        if (temFilhos && aberta) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _rowWidth(total),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Conector(n: total, cor: cor),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...adjuntas.asMap().entries.map((e) {
                        final idx = e.key;
                        final a = e.value;
                        return Padding(
                          padding: EdgeInsets.only(
                              right: (idx < adjuntas.length - 1) ||
                                      unidades.isNotEmpty
                                  ? _gap
                                  : 0),
                          child: SizedBox(
                            width: _cardW,
                            child: _FilhoNode(
                              titulo: a.nome,
                              subtitulo: a.sigla,
                              vinculadoA: secretaria.nome,
                              cor: _coresFilho[idx % _coresFilho.length],
                              setores: setoresByAdjunta[a.id] ?? [],
                              parentNome: a.nome,
                              setoresAberto: filhoAberto(a.id),
                              onToggleSetores: () => onToggleFilho(a.id ?? ''),
                              onEdit: a.id != null
                                  ? () => onAdjuntaEdit?.call(a)
                                  : null,
                              onSetorAdd: a.id != null
                                  ? () => onSetorAdd?.call(a.id!, true)
                                  : null,
                              onSetorEdit: onSetorEdit,
                              onAlterarVinculo: onAlterarVinculoAdjunta != null
                                  ? () => onAlterarVinculoAdjunta!(a)
                                  : null,
                              onAlterarVinculoSetor: onAlterarVinculoSetor,
                            ),
                          ),
                        );
                      }),
                      ...unidades.asMap().entries.map((e) {
                        final idx = e.key;
                        final u = e.value;
                        final logoUrl =
                            u.logoUrl != null && u.logoUrl!.isNotEmpty
                                ? unidadeRepo.logoPublicUrl(u.logoUrl)
                                : null;
                        return Padding(
                          padding: EdgeInsets.only(
                              right: idx < unidades.length - 1 ? _gap : 0),
                          child: SizedBox(
                            width: _cardW,
                            child: _FilhoNode(
                              titulo: u.nome,
                              subtitulo: u.cnes ?? u.municipio ?? u.sigla,
                              logoUrl: logoUrl,
                              vinculadoA: secretaria.nome,
                              cor: _coresFilho[(idx + 1) % _coresFilho.length],
                              setores: setoresByUnidade[u.id] ?? [],
                              parentNome: u.nome,
                              setoresAberto: filhoAberto(u.id),
                              onToggleSetores: () => onToggleFilho(u.id ?? ''),
                              onEdit: u.id != null
                                  ? () => onUnidadeEdit?.call(u)
                                  : null,
                              onSetorAdd: u.id != null
                                  ? () => onSetorAdd?.call(u.id!, false)
                                  : null,
                              onSetorEdit: onSetorEdit,
                              onAlterarVinculo: onAlterarVinculoUnidade != null
                                  ? () => onAlterarVinculoUnidade!(u)
                                  : null,
                              onAlterarVinculoSetor: onAlterarVinculoSetor,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Um filho (Adjunta ou Unidade) + opcionalmente setores
// ---------------------------------------------------------------------------

class _FilhoNode extends StatelessWidget {
  const _FilhoNode({
    required this.titulo,
    this.subtitulo,
    this.logoUrl,
    required this.vinculadoA,
    required this.cor,
    required this.setores,
    required this.parentNome,
    required this.setoresAberto,
    required this.onToggleSetores,
    this.onEdit,
    this.onSetorAdd,
    this.onSetorEdit,
    this.onAlterarVinculo,
    this.onAlterarVinculoSetor,
  });

  final String titulo;
  final String? subtitulo;
  final String? logoUrl;
  final String vinculadoA;
  final Color cor;
  final List<SetorModel> setores;
  final String parentNome;
  final bool setoresAberto;
  final VoidCallback onToggleSetores;
  final VoidCallback? onEdit;
  final VoidCallback? onSetorAdd;
  final void Function(SetorModel)? onSetorEdit;
  final VoidCallback? onAlterarVinculo;
  final void Function(SetorModel)? onAlterarVinculoSetor;

  @override
  Widget build(BuildContext context) {
    final temSetores = setores.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: temSetores ? onToggleSetores : null,
          child: _NodeCard(
            titulo: titulo,
            subtitulo: subtitulo,
            logoUrl: logoUrl,
            cor: cor,
            vinculadoA: vinculadoA,
            onAlterarVinculo: onAlterarVinculo,
            onEdit: onEdit,
            onAdd: onSetorAdd,
            addTooltip: 'Adicionar Setor',
          ),
        ),
        if (temSetores && setoresAberto) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _rowWidth(setores.length),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Conector(n: setores.length, cor: cor),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < setores.length; i++) ...[
                        if (i > 0) const SizedBox(width: _gap),
                        SizedBox(
                          width: _cardW,
                          child: _NodeCard(
                            titulo: setores[i].nome,
                            subtitulo: setores[i].sigla,
                            cor: cor.withValues(alpha: 0.85),
                            vinculadoA: parentNome,
                            onAlterarVinculo: onAlterarVinculoSetor != null
                                ? () => onAlterarVinculoSetor!(setores[i])
                                : null,
                            onEdit: () => onSetorEdit?.call(setores[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
