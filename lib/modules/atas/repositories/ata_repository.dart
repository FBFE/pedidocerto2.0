import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ata_credor_item_model.dart';
import '../models/ata_credor_model.dart';
import '../models/ata_model.dart';

class AtaRepository {
  final _supabase = Supabase.instance.client;

  Future<List<AtaModel>> getAtas() async {
    final response = await _supabase
        .from('atas')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => AtaModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<AtaModel?> getAtaById(String id) async {
    try {
      final response =
          await _supabase.from('atas').select().eq('id', id).single();
      return AtaModel.fromJson(Map<String, dynamic>.from(response));
    } catch (_) {
      return null;
    }
  }

  /// Salva ata manual (cabeçalho + um credor, sem itens). Retorna (ata, credorId) para depois adicionar itens.
  Future<({AtaModel ata, String credorId})> saveAtaManual({
    required AtaModel ata,
    required AtaCredorModel credor,
  }) async {
    final ataJson = ata.toJson();
    ataJson.remove('id');
    final ataResponse =
        await _supabase.from('atas').insert(ataJson).select().single();
    final ataInserida =
        AtaModel.fromJson(Map<String, dynamic>.from(ataResponse));
    final ataId = ataInserida.id!;

    final credorComAtaId = AtaCredorModel(
      ataId: ataId,
      fornecedorId: credor.fornecedorId,
      representanteId: credor.representanteId,
      cnpj: credor.cnpj,
      razaoSocial: credor.razaoSocial,
      nomeFantasia: credor.nomeFantasia,
      endereco: credor.endereco,
      contato: credor.contato,
      situacao: credor.situacao,
      representanteNome: credor.representanteNome,
      representanteCpf: credor.representanteCpf,
      representanteRg: credor.representanteRg,
      representanteContato: credor.representanteContato,
      representanteEmail: credor.representanteEmail,
    );
    final credorResponse = await _supabase
        .from('ata_credores')
        .insert(credorComAtaId.toJson())
        .select()
        .single();
    final credorInserido =
        AtaCredorModel.fromJson(Map<String, dynamic>.from(credorResponse));
    return (ata: ataInserida, credorId: credorInserido.id!);
  }

  /// Adiciona um credor (fornecedor) a uma ata já existente. Não verifica duplicidade aqui (validar CNPJ na UI).
  Future<String> addCredorToAta({required String ataId, required AtaCredorModel credor}) async {
    final json = credor.toJson()..remove('id');
    json['ata_id'] = ataId;
    final credorResponse = await _supabase
        .from('ata_credores')
        .insert(json)
        .select()
        .single();
    final credorInserido = AtaCredorModel.fromJson(Map<String, dynamic>.from(credorResponse));
    return credorInserido.id!;
  }

  /// Salva sub-ata (ata + um credor + itens). Pode haver várias atas com mesmo número (um por credor).
  Future<AtaModel> saveAtaCompleta({
    required AtaModel ata,
    required List<Map<String, dynamic>> credoresEItens,
  }) async {
    final ataJson = ata.toJson();
    ataJson.remove('id');
    final ataResponse =
        await _supabase.from('atas').insert(ataJson).select().single();
    final ataInserida =
        AtaModel.fromJson(Map<String, dynamic>.from(ataResponse));
    final ataId = ataInserida.id!;

    for (final credorMap in credoresEItens) {
      final cnpj = credorMap['cnpj']?.toString();
      final razaoSocial = credorMap['razaoSocial']?.toString();
      final itens = credorMap['itens'] as List<dynamic>? ?? [];
      final credor = AtaCredorModel(
        ataId: ataId,
        cnpj: cnpj,
        razaoSocial: razaoSocial,
        nomeFantasia: credorMap['nomeFantasia']?.toString(),
        endereco: credorMap['endereco']?.toString(),
        contato: credorMap['contato']?.toString(),
        situacao: credorMap['situacao']?.toString(),
        representanteNome: credorMap['representanteNome']?.toString(),
        representanteCpf: credorMap['representanteCpf']?.toString(),
        representanteRg: credorMap['representanteRg']?.toString(),
        representanteContato: credorMap['representanteContato']?.toString(),
        representanteEmail: credorMap['representanteEmail']?.toString(),
      );
      final credorResponse = await _supabase
          .from('ata_credores')
          .insert(credor.toJson())
          .select()
          .single();
      final credorInserido =
          AtaCredorModel.fromJson(Map<String, dynamic>.from(credorResponse));
      final credorId = credorInserido.id!;

      for (final itemMap in itens) {
        final item = AtaCredorItemModel(
          ataCredorId: credorId,
          numeroItem: itemMap['numeroItem'] is int
              ? itemMap['numeroItem'] as int
              : int.tryParse(itemMap['numeroItem']?.toString() ?? '0') ?? 0,
          descricao: itemMap['descricao']?.toString(),
          quantidade: (itemMap['quantidade'] as num?)?.toDouble() ?? 0,
          valorUnitario: (itemMap['valorUnitario'] as num?)?.toDouble() ?? 0,
          valorTotal: (itemMap['valorTotal'] as num?)?.toDouble() ?? 0,
          codigoItemPadrao: itemMap['codigoItemPadrao']?.toString(),
          tipoItemPadrao: itemMap['tipoItemPadrao']?.toString(),
          descricaoItemPadrao: itemMap['descricaoItemPadrao']?.toString(),
        );
        await _supabase.from('ata_credor_itens').insert(item.toJson());
      }
    }

    return ataInserida;
  }

  /// Credores de uma ata com seus itens (para exibição).
  Future<List<Map<String, dynamic>>> getCredoresComItens(String ataId) async {
    final credores = await _supabase
        .from('ata_credores')
        .select()
        .eq('ata_id', ataId) as List;
    final result = <Map<String, dynamic>>[];
    for (final c in credores) {
      final credorMap = Map<String, dynamic>.from(c as Map);
      final credorId = credorMap['id'] as String?;
      if (credorId == null) continue;
      final itensResponse = await _supabase
          .from('ata_credor_itens')
          .select()
          .eq('ata_credor_id', credorId) as List;
      final itens = itensResponse
          .map((e) =>
              AtaCredorItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      result.add({
        'id': credorId,
        'cnpj': credorMap['cnpj'],
        'razaoSocial': credorMap['razao_social'],
        'nomeFantasia': credorMap['nome_fantasia'],
        'endereco': credorMap['endereco'],
        'contato': credorMap['contato'],
        'situacao': credorMap['situacao'],
        'representanteNome': credorMap['representante_nome'],
        'representanteCpf': credorMap['representante_cpf'],
        'representanteRg': credorMap['representante_rg'],
        'representanteContato': credorMap['representante_contato'],
        'representanteEmail': credorMap['representante_email'],
        'itens': itens
            .map((i) => {
                  'id': i.id,
                  'ataCredorId': i.ataCredorId,
                  'numeroItem': i.numeroItem,
                  'descricao': i.descricao ?? i.nomeItem,
                  'nomeItem': i.nomeItem,
                  'especificacao': i.especificacao,
                  'quantidade': i.quantidade,
                  'valorUnitario': i.valorUnitario,
                  'valorTotal': i.valorTotal,
                  'codigoItemPadrao': i.codigoItemPadrao,
                  'tipoItemPadrao': i.tipoItemPadrao,
                  'descricaoItemPadrao': i.descricaoItemPadrao,
                  'marcaFabricanteId': i.marcaFabricanteId,
                  'unidadeMedidaId': i.unidadeMedidaId,
                  'usuarioCadastrouNome': i.usuarioCadastrouNome,
                  'usuarioCadastrouMatricula': i.usuarioCadastrouMatricula,
                  'createdAt': i.createdAt?.toIso8601String(),
                })
            .toList(),
      });
    }
    return result;
  }

  /// Atualiza apenas o cabeçalho da ata (tabela atas).
  Future<void> updateAta(AtaModel ata) async {
    if (ata.id == null) return;
    final json = ata.toJson();
    json.remove('id');
    json.remove('created_at');
    await _supabase.from('atas').update(json).eq('id', ata.id!);
  }

  /// Remove um item de ata_credor_itens.
  Future<void> deleteItem(String itemId) async {
    await _supabase.from('ata_credor_itens').delete().eq('id', itemId);
  }

  /// Atualiza um item em ata_credor_itens (o item deve ter id).
  Future<void> updateItem(AtaCredorItemModel item) async {
    if (item.id == null) return;
    final json = item.toJson();
    json.remove('id');
    json.remove('ata_credor_id'); // não alterar o vínculo
    await _supabase.from('ata_credor_itens').update(json).eq('id', item.id!);
  }

  Future<void> deleteAta(String id) async {
    final credores =
        await _supabase.from('ata_credores').select('id').eq('ata_id', id)
            as List;
    for (final c in credores) {
      final credorId = (c as Map)['id'] as String?;
      if (credorId != null) {
        await _supabase.from('ata_credor_itens').delete().eq('ata_credor_id', credorId);
      }
    }
    await _supabase.from('ata_credores').delete().eq('ata_id', id);
    await _supabase.from('atas').delete().eq('id', id);
  }

  /// Adiciona itens à ata (com detalhamento: nome, especificação, marca, unidade, valores).
  Future<void> adicionarItensAta(String ataCredorId, List<AtaCredorItemModel> itens) async {
    for (final item in itens) {
      final json = item.toJson();
      json.remove('id');
      json['ata_credor_id'] = ataCredorId;
      await _supabase.from('ata_credor_itens').insert(json);
    }
  }
}
