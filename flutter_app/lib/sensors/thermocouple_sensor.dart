import '../domain/calibration_point.dart';
import '../domain/sensor_model.dart';
import '../math/linear_algebra.dart';

/// Sensor Termopar — calibração polinomial estilo NIST/ITS-90.
///
/// Pontos: x = T(°C), y = E(mV).
/// O usuário fornece N pontos (T, mV) levantados em laboratório e o
/// modelo ajusta um polinômio de grau "degree" pelos mínimos quadrados:
///   E(T) = c0 + c1·T + c2·T² + ... + c_n·Tⁿ
///
/// Conversão inversa (E → T) por Newton.
class ThermocoupleSensor extends SensorModel {
  ThermocoupleSensor({
    this.typeLabel = 'K',
    this.degree = 4,
    List<CalibrationPoint>? defaults,
  }) : _defaults = defaults ?? _defaultsForType(typeLabel);

  final String typeLabel; // K, J, T, E, N, R, S, B (rótulo informativo)
  final int degree;
  final List<CalibrationPoint> _defaults;

  @override
  String get id => 'tc_$typeLabel';
  @override
  String get displayName => 'Termopar tipo $typeLabel';
  @override
  String get unitX => '°C';
  @override
  String get unitY => 'mV';
  @override
  int get minPoints => degree + 1;
  @override
  int get maxPoints => 12;

  @override
  List<CalibrationPoint> get defaultPoints => _defaults;

  @override
  (double, double) defaultRange() {
    final xs = _defaults.map((p) => p.x).toList()..sort();
    return (xs.first, xs.last);
  }

  @override
  CalibrationResult compute(List<CalibrationPoint> points) {
    if (points.length < minPoints) {
      throw ArgumentError(
        'Termopar grau $degree exige no mínimo $minPoints pontos.',
      );
    }
    final x = <List<double>>[];
    final y = <double>[];
    for (final p in points) {
      final row = <double>[];
      var pw = 1.0;
      for (var i = 0; i <= degree; i++) {
        row.add(pw);
        pw *= p.x;
      }
      x.add(row);
      y.add(p.y);
    }
    final c = LinearAlgebra.leastSquares(x, y);
    final coeffs = <String, double>{};
    for (var i = 0; i < c.length; i++) {
      coeffs['c$i'] = c[i];
    }
    return CalibrationResult(
      modelId: id,
      coefficients: coeffs,
      notes:
          'E(mV) = c0 + c1·T + … + c$degree·T^$degree — ajuste LSQ (referência tipo $typeLabel).',
    );
  }

  List<double> _polyCoeffs(CalibrationResult r) {
    final list = <double>[];
    for (var i = 0; i <= degree; i++) {
      list.add(r.coefficients['c$i'] ?? 0.0);
    }
    return list;
  }

  @override
  double yFromX(CalibrationResult r, double tC) {
    return LinearAlgebra.polyEval(_polyCoeffs(r), tC);
  }

  @override
  double xFromY(CalibrationResult r, double mV) {
    final coeffs = _polyCoeffs(r);
    // Estimativa inicial: linear (c0 + c1·T = mV)
    final c1 = coeffs.length > 1 ? coeffs[1] : 1.0;
    final x0 = c1.abs() < 1e-12 ? 0.0 : (mV - coeffs[0]) / c1;
    return LinearAlgebra.newton(
      f: (t) => LinearAlgebra.polyEval(coeffs, t) - mV,
      df: (t) => LinearAlgebra.polyDerivEval(coeffs, t),
      x0: x0,
    );
  }

  // -------------------------------------------------------------------
  // Pontos de referência (extraídos de tabelas NIST E230-02) para
  // pré-popular a UI. Servem como "default" a calibrar.
  // -------------------------------------------------------------------
  static List<CalibrationPoint> _defaultsForType(String type) {
    switch (type.toUpperCase()) {
      case 'K':
        return const [
          CalibrationPoint(x: 0, y: 0.0),
          CalibrationPoint(x: 100, y: 4.096),
          CalibrationPoint(x: 200, y: 8.138),
          CalibrationPoint(x: 400, y: 16.397),
          CalibrationPoint(x: 700, y: 29.129),
          CalibrationPoint(x: 1000, y: 41.276),
        ];
      case 'J':
        return const [
          CalibrationPoint(x: 0, y: 0.0),
          CalibrationPoint(x: 100, y: 5.269),
          CalibrationPoint(x: 200, y: 10.779),
          CalibrationPoint(x: 400, y: 21.848),
          CalibrationPoint(x: 600, y: 33.102),
          CalibrationPoint(x: 760, y: 42.281),
        ];
      case 'T':
        return const [
          CalibrationPoint(x: 0, y: 0.0),
          CalibrationPoint(x: 50, y: 2.036),
          CalibrationPoint(x: 100, y: 4.279),
          CalibrationPoint(x: 200, y: 9.288),
          CalibrationPoint(x: 300, y: 14.862),
          CalibrationPoint(x: 400, y: 20.872),
        ];
      case 'E':
        return const [
          CalibrationPoint(x: 0, y: 0.0),
          CalibrationPoint(x: 100, y: 6.319),
          CalibrationPoint(x: 200, y: 13.421),
          CalibrationPoint(x: 500, y: 37.005),
          CalibrationPoint(x: 700, y: 53.112),
          CalibrationPoint(x: 1000, y: 76.373),
        ];
      case 'N':
        return const [
          CalibrationPoint(x: 0, y: 0.0),
          CalibrationPoint(x: 100, y: 2.774),
          CalibrationPoint(x: 200, y: 5.913),
          CalibrationPoint(x: 500, y: 16.748),
          CalibrationPoint(x: 800, y: 28.455),
          CalibrationPoint(x: 1200, y: 43.846),
        ];
      case 'S':
        return const [
          CalibrationPoint(x: 0, y: 0.0),
          CalibrationPoint(x: 200, y: 1.441),
          CalibrationPoint(x: 500, y: 4.233),
          CalibrationPoint(x: 1000, y: 9.587),
          CalibrationPoint(x: 1300, y: 13.155),
          CalibrationPoint(x: 1500, y: 15.582),
        ];
      case 'R':
        return const [
          CalibrationPoint(x: 0, y: 0.0),
          CalibrationPoint(x: 200, y: 1.469),
          CalibrationPoint(x: 500, y: 4.471),
          CalibrationPoint(x: 1000, y: 10.506),
          CalibrationPoint(x: 1300, y: 14.624),
          CalibrationPoint(x: 1600, y: 18.842),
        ];
      case 'B':
        return const [
          CalibrationPoint(x: 250, y: 0.291),
          CalibrationPoint(x: 500, y: 1.241),
          CalibrationPoint(x: 800, y: 3.154),
          CalibrationPoint(x: 1200, y: 6.786),
          CalibrationPoint(x: 1500, y: 10.094),
          CalibrationPoint(x: 1800, y: 13.591),
        ];
      default:
        return const [
          CalibrationPoint(x: 0, y: 0.0),
          CalibrationPoint(x: 100, y: 4.0),
          CalibrationPoint(x: 200, y: 8.0),
          CalibrationPoint(x: 400, y: 16.0),
          CalibrationPoint(x: 700, y: 29.0),
          CalibrationPoint(x: 1000, y: 41.0),
        ];
    }
  }
}
