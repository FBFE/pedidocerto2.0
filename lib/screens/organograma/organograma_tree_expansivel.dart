import 'package:flutter/material.dart';

import '../../modules/unidades_lotacao/models/secretaria_adjunta_model.dart';
import '../../modules/unidades_lotacao/models/secretaria_model.dart';
import '../../modules/unidades_lotacao/models/setor_model.dart';
import '../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../modules/unidades_lotacao/repositories/governo_repository.dart';
import '../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';
import 'organograma_tree.dart';

/// Organograma em formato de conjuntos e subconjuntos expansíveis (lista vertical que "explode" ao clicar).
class OrganogramaTreeExpansivel extends StatelessWidget {
  const OrganogramaTreeExpansivel({
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gov = data.governo;
    final govLogo = gov.logoUrl != null && gov.logoUrl!.isNotEmpty
        ? governoRepo.logoPublicUrl(gov.logoUrl)
        : null;

    return ListView(
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        RepaintBoundary(
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: govLogo != null && govLogo.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(govLogo,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.account_balance,
                              color: theme.colorScheme.onPrimaryContainer)),
                    )
                  : Icon(Icons.account_balance,
                      color: theme.colorScheme.onPrimaryContainer),
            ),
            title: Text(gov.nome,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: gov.sigla != null && gov.sigla!.isNotEmpty
                ? Text('${gov.sigla}', style: theme.textTheme.bodySmall)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onAddSecretaria != null)
                  IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: onAddSecretaria,
                      tooltip: 'Adicionar Secretaria'),
                if (onGovernoEdit != null)
                  IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onGovernoEdit,
                      tooltip: 'Editar'),
              ],
            ),
            children: data.secretarias.isEmpty
                ? [
                    ListTile(
                        title: Text('Nenhuma secretaria',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline)))
                  ]
                : data.secretarias
                    .map((s) => _SecretariaTile(
                          secretaria: s,
                          adjuntas: data.adjuntasBySecretaria[s.id] ?? [],
                          unidades: data.unidadesBySecretaria[s.id] ?? [],
                          setoresByAdjunta: data.setoresByAdjunta,
                          setoresByUnidade: data.setoresByUnidade,
                          governoNome: gov.nome,
                          unidadeRepo: unidadeRepo,
                          onAddFilho: onAddFilhoSecretaria,
                          onEdit: onSecretariaEdit,
                          onAlterarVinculo: onAlterarVinculoSecretaria,
                          onAdjuntaEdit: onAdjuntaEdit,
                          onUnidadeEdit: onUnidadeEdit,
                          onSetorAdd: onSetorAdd,
                          onSetorEdit: onSetorEdit,
                          onAlterarVinculoAdjunta: onAlterarVinculoAdjunta,
                          onAlterarVinculoUnidade: onAlterarVinculoUnidade,
                          onAlterarVinculoSetor: onAlterarVinculoSetor,
                        ))
                    .toList(),
          ),
        ),
      ],
    );
  }
}

class _SecretariaTile extends StatelessWidget {
  const _SecretariaTile({
    required this.secretaria,
    required this.adjuntas,
    required this.unidades,
    required this.setoresByAdjunta,
    required this.setoresByUnidade,
    required this.governoNome,
    required this.unidadeRepo,
    this.onAddFilho,
    this.onEdit,
    this.onAlterarVinculo,
    this.onAdjuntaEdit,
    this.onUnidadeEdit,
    this.onSetorAdd,
    this.onSetorEdit,
    this.onAlterarVinculoAdjunta,
    this.onAlterarVinculoUnidade,
    this.onAlterarVinculoSetor,
  });

  final SecretariaModel secretaria;
  final List<SecretariaAdjuntaModel> adjuntas;
  final List<UnidadeHospitalarModel> unidades;
  final Map<String, List<SetorModel>> setoresByAdjunta;
  final Map<String, List<SetorModel>> setoresByUnidade;
  final String governoNome;
  final UnidadeHospitalarRepository unidadeRepo;
  final void Function(SecretariaModel)? onAddFilho;
  final void Function(SecretariaModel)? onEdit;
  final void Function(SecretariaModel)? onAlterarVinculo;
  final void Function(SecretariaAdjuntaModel)? onAdjuntaEdit;
  final void Function(UnidadeHospitalarModel)? onUnidadeEdit;
  final void Function(String, bool)? onSetorAdd;
  final void Function(SetorModel)? onSetorEdit;
  final void Function(SecretariaAdjuntaModel)? onAlterarVinculoAdjunta;
  final void Function(UnidadeHospitalarModel)? onAlterarVinculoUnidade;
  final void Function(SetorModel)? onAlterarVinculoSetor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filhos = <Widget>[
      ...adjuntas.map((a) => _FilhoTile(
            tipo: 'Secretaria Adjunta',
            titulo: a.nome,
            subtitulo: a.sigla,
            vinculadoA: secretaria.nome,
            setores: setoresByAdjunta[a.id] ?? [],
            onEdit: a.id != null ? () => onAdjuntaEdit?.call(a) : null,
            onSetorAdd:
                a.id != null ? () => onSetorAdd?.call(a.id!, true) : null,
            onAlterarVinculo: onAlterarVinculoAdjunta != null
                ? () => onAlterarVinculoAdjunta!(a)
                : null,
            onSetorEdit: onSetorEdit,
            onAlterarVinculoSetor: onAlterarVinculoSetor,
          )),
      ...unidades.map((u) {
        final logoUrl = u.logoUrl != null && u.logoUrl!.isNotEmpty
            ? unidadeRepo.logoPublicUrl(u.logoUrl)
            : null;
        return _FilhoTile(
          tipo: 'Unidade',
          titulo: u.nome,
          subtitulo: u.cnes ?? u.municipio ?? u.sigla,
          logoUrl: logoUrl,
          vinculadoA: secretaria.nome,
          setores: setoresByUnidade[u.id] ?? [],
          onEdit: u.id != null ? () => onUnidadeEdit?.call(u) : null,
          onSetorAdd:
              u.id != null ? () => onSetorAdd?.call(u.id!, false) : null,
          onAlterarVinculo: onAlterarVinculoUnidade != null
              ? () => onAlterarVinculoUnidade!(u)
              : null,
          onSetorEdit: onSetorEdit,
          onAlterarVinculoSetor: onAlterarVinculoSetor,
        );
      }),
    ];
    if (filhos.isEmpty) {
      filhos.add(ListTile(
        dense: true,
        title: Text('Nenhuma Secretaria Adjunta ou Unidade',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline)),
      ));
    }

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(left: 24),
        child: ExpansionTile(
          leading:
              Icon(Icons.business_center, color: theme.colorScheme.primary),
          title: Text(secretaria.nome,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              Icon(Icons.link, size: 14, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Expanded(
                  child: Text('Vinculado a: $governoNome',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAddFilho != null)
                IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    onPressed: () => onAddFilho!(secretaria),
                    tooltip: 'Adicionar Adjunta ou Unidade'),
              if (onEdit != null)
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 22),
                    onPressed: () => onEdit!(secretaria),
                    tooltip: 'Editar'),
              if (onAlterarVinculo != null)
                IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 22),
                    onPressed: () => onAlterarVinculo!(secretaria),
                    tooltip: 'Alterar vínculo'),
            ],
          ),
          children: filhos,
        ),
      ),
    );
  }
}

class _FilhoTile extends StatelessWidget {
  const _FilhoTile({
    required this.tipo,
    required this.titulo,
    this.subtitulo,
    this.logoUrl,
    required this.vinculadoA,
    required this.setores,
    this.onEdit,
    this.onSetorAdd,
    this.onAlterarVinculo,
    this.onSetorEdit,
    this.onAlterarVinculoSetor,
  });

  final String tipo;
  final String titulo;
  final String? subtitulo;
  final String? logoUrl;
  final String vinculadoA;
  final List<SetorModel> setores;
  final VoidCallback? onEdit;
  final VoidCallback? onSetorAdd;
  final VoidCallback? onAlterarVinculo;
  final void Function(SetorModel)? onSetorEdit;
  final void Function(SetorModel)? onAlterarVinculoSetor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final setorTiles = <Widget>[
      ...setores.map((s) => Padding(
            padding: const EdgeInsets.only(left: 48),
            child: ListTile(
              dense: true,
              leading: Icon(Icons.folder_outlined,
                  size: 20, color: theme.colorScheme.outline),
              title: Text(s.nome, style: theme.textTheme.bodyMedium),
              subtitle: Text('Vinculado a: $titulo',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onSetorEdit != null)
                    IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => onSetorEdit!(s),
                        tooltip: 'Editar'),
                  if (onAlterarVinculoSetor != null)
                    IconButton(
                        icon: const Icon(Icons.swap_horiz, size: 20),
                        onPressed: () => onAlterarVinculoSetor!(s),
                        tooltip: 'Alterar vínculo'),
                ],
              ),
            ),
          ))
    ];
    if (setorTiles.isEmpty) {
      setorTiles.add(Padding(
        padding: const EdgeInsets.only(left: 48),
        child: ListTile(
          dense: true,
          title: Text('Nenhum setor',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          trailing: onSetorAdd != null
              ? IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onSetorAdd,
                  tooltip: 'Adicionar Setor')
              : null,
        ),
      ));
    } else if (onSetorAdd != null) {
      setorTiles.add(Padding(
        padding: const EdgeInsets.only(left: 48),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.add, size: 20),
          title: Text('Adicionar setor',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary)),
          onTap: onSetorAdd,
        ),
      ));
    }

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(left: 24),
        child: ExpansionTile(
          leading: logoUrl != null && logoUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(logoUrl!),
                  onBackgroundImageError: (_, __) {},
                  child: Icon(Icons.business,
                      size: 18, color: theme.colorScheme.onSurface))
              : Icon(
                  tipo == 'Secretaria Adjunta'
                      ? Icons.folder_special
                      : Icons.local_hospital,
                  color: theme.colorScheme.secondary,
                  size: 28),
          title: Text(titulo, style: theme.textTheme.titleSmall),
          subtitle: Row(
            children: [
              Icon(Icons.link, size: 12, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Expanded(
                  child: Text('Vinculado a: $vinculadoA',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Editar'),
              if (onAlterarVinculo != null)
                IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    onPressed: onAlterarVinculo,
                    tooltip: 'Alterar vínculo'),
            ],
          ),
          children: setorTiles,
        ),
      ),
    );
  }
}
