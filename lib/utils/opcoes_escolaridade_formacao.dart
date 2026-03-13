/// Opções predefinidas para Escolaridade e Formação (nível + área).
/// Permite "Outra (especificar)" para cadastros não listados.
library;

const String outraEspecificar = 'Outra (especificar)';
const String outroEspecificar = 'Outro (especificar)';

const List<String> opcoesEscolaridade = [
  'Analfabeto',
  'Lê e escreve (ou Alfabetizado)',
  'Ensino Fundamental Incompleto',
  'Ensino Fundamental Completo',
  'Ensino Médio Incompleto',
  'Ensino Médio Completo',
  'Ensino Superior Incompleto',
  'Ensino Superior Completo',
  'Pós-graduação (Especialização/Lato Sensu) Incompleta',
  'Pós-graduação (Especialização/Lato Sensu) Completa',
  'Mestrado',
  'Doutorado',
  'Pós-Doutorado',
  outraEspecificar,
];

const List<String> opcoesNivelFormacao = [
  'Ensino Técnico Integrado (Junto com o Ensino Médio)',
  'Ensino Técnico Concomitante/Subsequente (Após o Ensino Médio)',
  'Curso Profissionalizante / Qualificação Básica',
  'Bacharelado',
  'Licenciatura',
  'Tecnólogo',
  'Aperfeiçoamento / Extensão',
  'Especialização',
  'MBA',
  'Residência Médica',
  'Residência Multiprofissional em Saúde',
  'Mestrado Profissional',
  'Mestrado Acadêmico',
  'Doutorado Profissional',
  'Doutorado Acadêmico',
  'Pós-Doutorado',
  'Livre-Docência',
  outroEspecificar,
];

const List<String> opcoesAreaFormacao = [
  'Ciências Exatas e da Terra',
  'Ciências Biológicas',
  'Engenharias',
  'Ciências da Saúde',
  'Ciências Agrárias',
  'Ciências Sociais Aplicadas',
  'Ciências Humanas',
  'Linguística, Letras e Artes',
  outroEspecificar,
];

/// Separador usado para armazenar nível|área|específico no campo formacao.
const String formacaoSeparador = '|||';

String montarFormacao(String? nivel, String? area, String? especifico) {
  final parts = <String>[
    nivel?.trim() ?? '',
    area?.trim() ?? '',
    especifico?.trim() ?? '',
  ];
  return parts.join(formacaoSeparador);
}

/// Retorna [nivel, area, especifico].
List<String> parseFormacao(String? formacao) {
  if (formacao == null || formacao.isEmpty) return ['', '', ''];
  final parts = formacao.split(formacaoSeparador);
  return [
    parts.isNotEmpty ? parts[0] : '',
    parts.length > 1 ? parts[1] : '',
    parts.length > 2 ? parts[2] : '',
  ];
}
