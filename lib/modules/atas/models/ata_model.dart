/// Ata registrada no banco (cabeçalho) – cadastro manual.
class AtaModel {
  final String? id;
  final DateTime? createdAt;

  /// Nome do usuário que cadastrou
  final String? usuarioCadastrouNome;
  /// Matrícula do usuário que cadastrou
  final String? usuarioCadastrouMatricula;
  /// Data e hora do registro (exibição: dd/mm/yyyy hh:mm:ss)
  final DateTime? dataHoraRegistro;

  /// Número da ata
  final String numeroAta;
  /// Modalidade: ADESÃO CARONA, CHAMAMENTO PÚBLICO, DISPENSA DE LICITAÇÃO, INEXIGIBILIDADE, PREGÃO ELETRÔNICO
  final String? modalidade;
  /// Número da modalidade
  final String? numeroModalidade;

  /// Vigência
  final DateTime? vigenciaInicio;
  final DateTime? vigenciaFim;
  final String? statusVigencia;

  /// Detalhamento
  final String? detalhamento;
  final int? anoCompetencia;
  final String? numeroProcessoAdministrativo;
  final String? linkProcessoAdministrativo;

  /// Tipo da ata: medicamento | material | opme (define de qual banco puxar itens)
  final String? tipoAta;

  final String? orgao;
  final String? objeto;
  final String? classificacao;

  AtaModel({
    this.id,
    this.createdAt,
    this.usuarioCadastrouNome,
    this.usuarioCadastrouMatricula,
    this.dataHoraRegistro,
    this.numeroAta = '',
    this.modalidade,
    this.numeroModalidade,
    this.vigenciaInicio,
    this.vigenciaFim,
    this.statusVigencia,
    this.detalhamento,
    this.anoCompetencia,
    this.numeroProcessoAdministrativo,
    this.linkProcessoAdministrativo,
    this.tipoAta,
    this.orgao,
    this.objeto,
    this.classificacao,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  factory AtaModel.fromJson(Map<String, dynamic> json) {
    return AtaModel(
      id: json['id'] as String?,
      createdAt: _parseDate(json['created_at']),
      usuarioCadastrouNome: json['usuario_cadastrou_nome'] as String?,
      usuarioCadastrouMatricula: json['usuario_cadastrou_matricula'] as String?,
      dataHoraRegistro: _parseDate(json['data_hora_registro']),
      numeroAta: json['numero_ata'] as String? ?? '',
      modalidade: json['modalidade'] as String?,
      numeroModalidade: json['numero_modalidade'] as String?,
      vigenciaInicio: _parseDate(json['vigencia_inicio']),
      vigenciaFim: _parseDate(json['vigencia_fim']),
      statusVigencia: json['status_vigencia'] as String?,
      detalhamento: json['detalhamento'] as String?,
      anoCompetencia: json['ano_competencia'] as int?,
      numeroProcessoAdministrativo: json['numero_processo_administrativo'] as String?,
      linkProcessoAdministrativo: json['link_processo_administrativo'] as String?,
      tipoAta: json['tipo_ata'] as String?,
      orgao: json['orgao'] as String?,
      objeto: json['objeto'] as String?,
      classificacao: json['classificacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'usuario_cadastrou_nome': usuarioCadastrouNome,
      'usuario_cadastrou_matricula': usuarioCadastrouMatricula,
      'data_hora_registro': dataHoraRegistro?.toUtc().toIso8601String(),
      'numero_ata': numeroAta,
      'modalidade': modalidade,
      'numero_modalidade': numeroModalidade,
      'vigencia_inicio': vigenciaInicio != null
          ? '${vigenciaInicio!.year}-${vigenciaInicio!.month.toString().padLeft(2, '0')}-${vigenciaInicio!.day.toString().padLeft(2, '0')}'
          : null,
      'vigencia_fim': vigenciaFim != null
          ? '${vigenciaFim!.year}-${vigenciaFim!.month.toString().padLeft(2, '0')}-${vigenciaFim!.day.toString().padLeft(2, '0')}'
          : null,
      'status_vigencia': statusVigencia,
      'detalhamento': detalhamento,
      'ano_competencia': anoCompetencia,
      'numero_processo_administrativo': numeroProcessoAdministrativo,
      'link_processo_administrativo': linkProcessoAdministrativo,
      'tipo_ata': tipoAta,
      'orgao': orgao,
      'objeto': objeto,
      'classificacao': classificacao,
    };
  }

  /// Exibe número da ata (cadastro manual).
  String get numeroExibicao => numeroAta.isNotEmpty ? numeroAta : '—';

  /// Modalidades permitidas
  static const List<String> modalidades = [
    'ADESÃO CARONA',
    'CHAMAMENTO PÚBLICO',
    'DISPENSA DE LICITAÇÃO',
    'INEXIGIBILIDADE',
    'PREGÃO ELETRÔNICO',
  ];

  /// Tipos de ata (banco de itens)
  static const List<String> tiposAta = ['medicamento', 'material', 'opme'];
}
