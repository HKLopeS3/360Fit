/// Protocolos de avaliação física — funções puras, testadas em
/// test/protocolos_test.dart com valores de referência da literatura.
///
/// Referências: Pollock & Jackson (1978/1980), Petroski (1995),
/// Siri (1961), Epley (1985), Brzycki (1993), Cooper (1968).
library;

import 'dart:math' as math;

enum Sexo { masculino, feminino }

/// Sítios de dobras cutâneas (mm) usados pelos protocolos.
class Dobras {
  const Dobras({
    this.tricipital,
    this.subescapular,
    this.peitoral,
    this.axilarMedia,
    this.suprailiaca,
    this.abdominal,
    this.coxa,
    this.panturrilha,
  });

  final double? tricipital;
  final double? subescapular;
  final double? peitoral;
  final double? axilarMedia;
  final double? suprailiaca;
  final double? abdominal;
  final double? coxa;
  final double? panturrilha;

  double get somaSete =>
      (tricipital ?? 0) +
      (subescapular ?? 0) +
      (peitoral ?? 0) +
      (axilarMedia ?? 0) +
      (suprailiaca ?? 0) +
      (abdominal ?? 0) +
      (coxa ?? 0);
}

/// % de gordura a partir da densidade corporal — equação de Siri.
double percentualGorduraSiri(double densidade) =>
    (495 / densidade) - 450;

/// Pollock 3 dobras.
/// Homens: peitoral + abdominal + coxa. Mulheres: tríceps + suprailíaca + coxa.
double densidadePollock3({
  required Sexo sexo,
  required int idade,
  required Dobras dobras,
}) {
  if (sexo == Sexo.masculino) {
    final soma =
        (dobras.peitoral ?? 0) + (dobras.abdominal ?? 0) + (dobras.coxa ?? 0);
    return 1.10938 -
        0.0008267 * soma +
        0.0000016 * soma * soma -
        0.0002574 * idade;
  }
  final soma = (dobras.tricipital ?? 0) +
      (dobras.suprailiaca ?? 0) +
      (dobras.coxa ?? 0);
  return 1.0994921 -
      0.0009929 * soma +
      0.0000023 * soma * soma -
      0.0001392 * idade;
}

/// Pollock 7 dobras (ambos os sexos usam a soma das 7).
double densidadePollock7({
  required Sexo sexo,
  required int idade,
  required Dobras dobras,
}) {
  final soma = dobras.somaSete;
  if (sexo == Sexo.masculino) {
    return 1.112 -
        0.00043499 * soma +
        0.00000055 * soma * soma -
        0.00028826 * idade;
  }
  return 1.097 -
      0.00046971 * soma +
      0.00000056 * soma * soma -
      0.00012828 * idade;
}

/// Petroski (adultos) — 4 dobras.
/// Homens: subescapular + tríceps + suprailíaca + panturrilha.
/// Mulheres: axilar média + suprailíaca + coxa + panturrilha.
double densidadePetroski({
  required Sexo sexo,
  required int idade,
  required Dobras dobras,
}) {
  if (sexo == Sexo.masculino) {
    final soma = (dobras.subescapular ?? 0) +
        (dobras.tricipital ?? 0) +
        (dobras.suprailiaca ?? 0) +
        (dobras.panturrilha ?? 0);
    return 1.10726863 -
        0.00081201 * soma +
        0.00000212 * soma * soma -
        0.00041761 * idade;
  }
  final soma = (dobras.axilarMedia ?? 0) +
      (dobras.suprailiaca ?? 0) +
      (dobras.coxa ?? 0) +
      (dobras.panturrilha ?? 0);
  return 1.1954713 -
      0.07513507 * _log10(soma) -
      0.00041072 * idade;
}

double _log10(double x) => math.log(x) / math.ln10;

// ------------------------------------------------------------------ força

/// 1RM estimado por Epley: carga × (1 + reps/30).
double umRmEpley(double cargaKg, int repeticoes) =>
    cargaKg * (1 + repeticoes / 30);

/// 1RM estimado por Brzycki: carga × 36 / (37 − reps).
double umRmBrzycki(double cargaKg, int repeticoes) =>
    cargaKg * 36 / (37 - repeticoes);

// ------------------------------------------------------------------ cardio

/// VO₂ máx (ml/kg/min) pelo teste de Cooper (distância em metros em 12 min).
double vo2Cooper(double distanciaMetros) =>
    (distanciaMetros - 504.9) / 44.73;

/// Classificação simplificada do VO₂ máx para adultos.
String classificacaoVo2(double vo2, {required Sexo sexo}) {
  final cortes = sexo == Sexo.masculino
      ? const [35.0, 42.0, 50.0]
      : const [30.0, 37.0, 45.0];
  if (vo2 < cortes[0]) return 'Fraco';
  if (vo2 < cortes[1]) return 'Regular';
  if (vo2 < cortes[2]) return 'Bom';
  return 'Excelente';
}

// ------------------------------------------------------------- flexibilidade

/// Classificação do Banco de Wells (cm) — referência adulta simplificada.
String classificacaoWells(double cm, {required Sexo sexo}) {
  final cortes = sexo == Sexo.masculino
      ? const [24.0, 34.0, 39.0]
      : const [29.0, 37.0, 43.0];
  if (cm < cortes[0]) return 'Fraco';
  if (cm < cortes[1]) return 'Regular';
  if (cm < cortes[2]) return 'Bom';
  return 'Excelente';
}
