class ProcedimentoSigtapModel {
  final String coProcedimento;
  final String noProcedimento;
  final String? tpComplexidade;
  final String? tpSexo;
  final int? qtMaximaExecucao;
  final int? qtDiasPermanencia;
  final int? qtPontos;
  final int? vlIdadeMinima;
  final int? vlIdadeMaxima;
  final double? vlSh;
  final double? vlSa;
  final double? vlSp;
  final String? coFinanciamento;
  final String? coRubrica;
  final int? qtTempoPermanencia;
  final String? dtCompetencia;

  ProcedimentoSigtapModel({
    required this.coProcedimento,
    required this.noProcedimento,
    this.tpComplexidade,
    this.tpSexo,
    this.qtMaximaExecucao,
    this.qtDiasPermanencia,
    this.qtPontos,
    this.vlIdadeMinima,
    this.vlIdadeMaxima,
    this.vlSh,
    this.vlSa,
    this.vlSp,
    this.coFinanciamento,
    this.coRubrica,
    this.qtTempoPermanencia,
    this.dtCompetencia,
  });

  factory ProcedimentoSigtapModel.fromJson(Map<String, dynamic> json) {
    return ProcedimentoSigtapModel(
      coProcedimento: json['co_procedimento']?.toString() ?? '',
      noProcedimento: json['no_procedimento']?.toString() ?? '',
      tpComplexidade: json['tp_complexidade']?.toString(),
      tpSexo: json['tp_sexo']?.toString(),
      qtMaximaExecucao: json['qt_maxima_execucao'] as int?,
      qtDiasPermanencia: json['qt_dias_permanencia'] as int?,
      qtPontos: json['qt_pontos'] as int?,
      vlIdadeMinima: json['vl_idade_minima'] as int?,
      vlIdadeMaxima: json['vl_idade_maxima'] as int?,
      vlSh: (json['vl_sh'] as num?)?.toDouble(),
      vlSa: (json['vl_sa'] as num?)?.toDouble(),
      vlSp: (json['vl_sp'] as num?)?.toDouble(),
      coFinanciamento: json['co_financiamento']?.toString(),
      coRubrica: json['co_rubrica']?.toString(),
      qtTempoPermanencia: json['qt_tempo_permanencia'] as int?,
      dtCompetencia: json['dt_competencia']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'co_procedimento': coProcedimento,
      'no_procedimento': noProcedimento,
      'tp_complexidade': tpComplexidade,
      'tp_sexo': tpSexo,
      'qt_maxima_execucao': qtMaximaExecucao,
      'qt_dias_permanencia': qtDiasPermanencia,
      'qt_pontos': qtPontos,
      'vl_idade_minima': vlIdadeMinima,
      'vl_idade_maxima': vlIdadeMaxima,
      'vl_sh': vlSh,
      'vl_sa': vlSa,
      'vl_sp': vlSp,
      'co_financiamento': coFinanciamento,
      'co_rubrica': coRubrica,
      'qt_tempo_permanencia': qtTempoPermanencia,
      'dt_competencia': dtCompetencia,
    };
  }
}
