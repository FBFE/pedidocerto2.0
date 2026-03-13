import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resposta da BrasilAPI GET https://brasilapi.com.br/api/cnpj/v1/{CNPJ}
/// Mapeada para preencher dados do fornecedor.
class BrasilApiCnpjService {
  static const String baseUrl = 'https://brasilapi.com.br/api/cnpj/v1';

  /// Busca dados do CNPJ na BrasilAPI e retorna um Map com os campos do fornecedor.
  /// Campos: cnpj, razao_social, nome_fantasia, endereco, contato, situacao.
  /// Lança em caso de erro de rede ou CNPJ inválido.
  static Future<Map<String, String?>> buscarPorCnpj(String cnpj) async {
    final apenasNumeros = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (apenasNumeros.length != 14) {
      throw Exception('CNPJ deve ter 14 dígitos.');
    }
    final uri = Uri.parse('$baseUrl/$apenasNumeros');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        throw Exception('CNPJ não encontrado.');
      }
      throw Exception('Erro ao consultar CNPJ: ${response.statusCode}');
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return _mapearResposta(map);
  }

  static Map<String, String?> _mapearResposta(Map<String, dynamic> map) {
    final logradouro = map['logradouro']?.toString().trim();
    final numero = map['numero']?.toString().trim();
    final complemento = map['complemento']?.toString().trim();
    final bairro = map['bairro']?.toString().trim();
    final municipio = map['municipio']?.toString().trim();
    final uf = map['uf']?.toString().trim();
    final cep = map['cep']?.toString().trim();
    final parts = <String>[];
    if (logradouro != null && logradouro.isNotEmpty) parts.add(logradouro);
    if (numero != null && numero.isNotEmpty) parts.add('nº $numero');
    if (complemento != null && complemento.isNotEmpty) parts.add(complemento);
    if (bairro != null && bairro.isNotEmpty) parts.add(bairro);
    if (municipio != null && municipio.isNotEmpty) parts.add(municipio);
    if (uf != null && uf.isNotEmpty) parts.add(uf);
    if (cep != null && cep.isNotEmpty) parts.add('CEP $cep');
    final endereco = parts.isEmpty ? null : parts.join(', ');

    String? contato;
    final tel1 = map['ddd_telefone_1']?.toString().trim();
    final tel2 = map['ddd_telefone_2']?.toString().trim();
    if (tel1 != null && tel1.isNotEmpty) {
      contato = tel2 != null && tel2.isNotEmpty ? '$tel1 / $tel2' : tel1;
    } else if (tel2 != null && tel2.isNotEmpty) {
      contato = tel2;
    }

    return {
      'cnpj': map['cnpj']?.toString().trim(),
      'razao_social': map['razao_social']?.toString().trim(),
      'nome_fantasia': map['nome_fantasia']?.toString().trim(),
      'endereco': endereco,
      'contato': contato,
      'situacao': map['descricao_situacao_cadastral']?.toString().trim(),
    };
  }
}
