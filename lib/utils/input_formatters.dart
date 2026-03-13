import 'package:flutter/services.dart';

/// Converte digitação para letras minúsculas (ex.: e-mail).
class LowercaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.toLowerCase() == newValue.text) return newValue;
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

/// Formata digitação para CNPJ: 00.000.000/0000-00
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 14) return oldValue;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formata digitação para CPF: 000.000.000-00
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 11) return oldValue;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formata digitação para telefone BR: fixo (XX) XXXX-XXXX ou móvel (XX) 9 XXXX-XXXX.
/// Reconhece móvel quando o 3º dígito (após DDD) é 9 (11 dígitos).
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 11) return oldValue;
    final formatted = _formatarTelefoneDigitos(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formata digitação para RG (até 12 dígitos): 00.000.000-00
class RgInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 12) return oldValue;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Conectivos que permanecem em minúsculo no nome (exceto no início do nome).
const _conectivos = {'de', 'do', 'da', 'dos', 'das', 'e', 'o', 'a', 'em', 'no', 'na', 'nos', 'nas', 'um', 'uma', 'del', 'della', 'du'};

/// Aplica capitalização no nome: primeira letra de cada palavra maiúscula,
/// conectivos (de, do, da, etc.) em minúsculo. Ex.: "ALESSANDRA FERNANDA DE SOUZA" → "Alessandra Fernanda de Souza".
String nomeTitleCase(String? texto) {
  if (texto == null || texto.trim().isEmpty) return texto ?? '';
  final palavras = texto.trim().toLowerCase().split(RegExp(r'\s+'));
  final resultado = <String>[];
  for (var i = 0; i < palavras.length; i++) {
    final p = palavras[i];
    if (p.isEmpty) continue;
    final conectivo = _conectivos.contains(p);
    if (conectivo) {
      resultado.add(p);
    } else {
      resultado.add(p.length > 1
          ? '${p[0].toUpperCase()}${p.substring(1)}'
          : p.toUpperCase());
    }
  }
  return resultado.join(' ');
}

/// Aplica title case preservando espaços no início e no fim (para não apagar o espaço enquanto o usuário digita).
String _nomeTitleCasePreservandoEspacos(String texto) {
  if (texto.isEmpty) return texto;
  final meio = texto.trim();
  if (meio.isEmpty) return texto;
  final start = texto.indexOf(meio[0]);
  final end = start + meio.length;
  final leading = texto.substring(0, start);
  final trailing = texto.substring(end);
  return leading + nomeTitleCase(meio) + trailing;
}

/// Formata o texto do nome em tempo real: primeira letra de cada palavra maiúscula, conectivos em minúsculo.
/// Preserva espaços no início e no fim para permitir digitar nomes com mais de uma palavra.
class NomeTitleCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final formatted = _nomeTitleCasePreservandoEspacos(newValue.text);
    if (formatted == newValue.text) return newValue;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length.clamp(0, formatted.length)),
    );
  }
}

/// Formata digitação para data: DD/MM/AAAA (insere as barras automaticamente)
class DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 8) return oldValue;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Retorna só dígitos do CNPJ (para salvar ou validar)
String cnpjApenasDigitos(String? s) => s?.replaceAll(RegExp(r'[^\d]'), '') ?? '';

/// Formata CNPJ para exibição (00.000.000/0000-00)
String formatarCnpjParaExibicao(String? s) {
  final d = cnpjApenasDigitos(s);
  if (d.length > 14) return s ?? '';
  final buffer = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 2 || i == 5) buffer.write('.');
    if (i == 8) buffer.write('/');
    if (i == 12) buffer.write('-');
    buffer.write(d[i]);
  }
  return buffer.toString();
}

/// Retorna só dígitos do CPF (para salvar ou validar)
String cpfApenasDigitos(String? s) => s?.replaceAll(RegExp(r'[^\d]'), '') ?? '';

/// Retorna só dígitos do RG (para salvar ou validar)
String rgApenasDigitos(String? s) => s?.replaceAll(RegExp(r'[^\d]'), '') ?? '';

/// Retorna só dígitos do telefone (para salvar ou validar)
String telefoneApenasDigitos(String? s) => s?.replaceAll(RegExp(r'[^\d]'), '') ?? '';

/// Formata CPF para exibição (000.000.000-00)
String formatarCpfParaExibicao(String? s) {
  final d = cpfApenasDigitos(s);
  if (d.length > 11) return s ?? '';
  final buffer = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 3 || i == 6) buffer.write('.');
    if (i == 9) buffer.write('-');
    buffer.write(d[i]);
  }
  return buffer.toString();
}

/// Formata apenas os dígitos para (XX) XXXX-XXXX (fixo) ou (XX) 9 XXXX-XXXX (móvel).
String _formatarTelefoneDigitos(String digits) {
  if (digits.isEmpty) return '';
  final buffer = StringBuffer();
  final isMovel = digits.length >= 3 && digits[2] == '9';
  for (var i = 0; i < digits.length; i++) {
    if (i == 0) buffer.write('(');
    if (i == 2) buffer.write(') ');
    if (isMovel) {
      if (i == 3) buffer.write(' ');
      if (i == 7) buffer.write('-');
    } else {
      if (i == 6) buffer.write('-');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Formata telefone para exibição: fixo (XX) XXXX-XXXX ou móvel (XX) 9 XXXX-XXXX
String formatarTelefoneParaExibicao(String? s) {
  final d = telefoneApenasDigitos(s);
  if (d.isEmpty) return s ?? '';
  if (d.length > 11) return s ?? '';
  return _formatarTelefoneDigitos(d);
}

/// Retorna 'Fixo' ou 'Móvel' conforme o número (BR: 10 dígitos = fixo, 11 com 9 após DDD = móvel). Null se inválido/vazio.
String? tipoTelefoneBR(String? s) {
  final d = telefoneApenasDigitos(s);
  if (d.length != 10 && d.length != 11) return null;
  if (d.length == 11 && d[2] == '9') return 'Móvel';
  if (d.length == 10) return 'Fixo';
  return null;
}

// --- Mascaramento de dados sensíveis (representante). Uso na UI; em documentos use o valor completo. ---

/// CPF mascarado para exibição: ***.***.***-XX (mostra só os 2 últimos dígitos).
String mascararCpf(String? s) {
  final d = cpfApenasDigitos(s);
  if (d.length < 2) return '***.***.***-**';
  return '***.***.***-${d.substring(d.length - 2)}';
}

/// RG mascarado para exibição: ******-XX (mostra só os 2 últimos caracteres).
String mascararRg(String? s) {
  final d = rgApenasDigitos(s);
  if (d.isEmpty) return '******-**';
  if (d.length <= 2) return '******-$d';
  return '${'*' * (d.length - 2)}-${d.substring(d.length - 2)}';
}

/// E-mail mascarado: primeira letra + *** + @ + domínio (ex.: a***@empresa.com.br).
String mascararEmail(String? s) {
  if (s == null || s.trim().isEmpty) return '***@***.***';
  final t = s.trim().toLowerCase();
  final idx = t.indexOf('@');
  if (idx <= 0) return '***@***.***';
  final local = t.substring(0, idx);
  final domain = t.substring(idx + 1);
  if (domain.isEmpty) return '***@***.***';
  return '${local[0]}***@$domain';
}

/// Telefone mascarado: (**) *****-XXXX (mostra só os 4 últimos dígitos).
String mascararTelefone(String? s) {
  final d = telefoneApenasDigitos(s);
  if (d.length < 4) return '(**) *****-****';
  return '(**) *****-${d.substring(d.length - 4)}';
}

// --- Moeda R$ 0.000,00 (armazena em centavos como inteiro; exibição com ponto milhar e vírgula decimal) ---

/// Formata digitação para R$ 0.000,00 (apenas dígitos; os 2 últimos são centavos).
/// Inicia em 0,00 e formata ao digitar; remove zeros à esquerda da parte inteira.
class MoedaBrInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 15) return oldValue;
    final len = digits.length;
    final intPartRaw = len <= 2 ? '0' : digits.substring(0, len - 2);
    final decPart = len == 0 ? '00' : (len == 1 ? '${digits[0]}0' : digits.substring(len - 2));
    // Remove zeros à esquerda da parte inteira (evita "00.089,80"); mantém "0" se tudo for zero.
    final intPart = intPartRaw.replaceFirst(RegExp(r'^0+'), '');
    final intPartStr = intPart.isEmpty ? '0' : intPart;
    final buffer = StringBuffer();
    for (var i = 0; i < intPartStr.length; i++) {
      if (i > 0 && (intPartStr.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPartStr[i]);
    }
    buffer.write(',');
    buffer.write(decPart);
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formata quantidade ao digitar: só números e vírgula/ponto decimal; remove zeros à esquerda (04 → 4).
class QuantidadeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String t = newValue.text.replaceAll(',', '.');
    if (t.contains('.')) {
      final parts = t.split('.');
      if (parts.length > 2) return oldValue;
      final intPart = parts[0].replaceAll(RegExp(r'[^\d]'), '');
      final decPart = parts[1].replaceAll(RegExp(r'[^\d]'), '');
      t = '$intPart.$decPart';
    } else {
      t = t.replaceAll(RegExp(r'[^\d]'), '');
    }
    final dotIndex = t.indexOf('.');
    final intPartRaw = dotIndex < 0 ? t : t.substring(0, dotIndex);
    final decPart = dotIndex < 0 ? '' : t.substring(dotIndex + 1);
    final intPart = intPartRaw.replaceFirst(RegExp(r'^0+'), '');
    final intPartStr = intPart.isEmpty ? '0' : intPart;
    final result = decPart.isEmpty ? intPartStr : '$intPartStr,$decPart';
    if (result.length > 20) return oldValue;
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

/// Converte valor exibido (1.234,56) para double.
double moedaBrParaDouble(String? s) {
  if (s == null || s.trim().isEmpty) return 0;
  final t = s.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(t) ?? 0;
}

/// Formata double para exibição R$ 0.000,00.
String formatarMoedaBr(double value) {
  final str = value.toStringAsFixed(2).replaceAll('.', ',');
  final parts = str.split(',');
  var intPart = parts[0];
  final neg = intPart.startsWith('-');
  if (neg) intPart = intPart.substring(1);
  final formatted = intPart.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '${neg ? '-' : ''}$formatted,${parts[1]}';
}
