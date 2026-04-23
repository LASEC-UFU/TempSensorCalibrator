import '../domain/calibration_point.dart';
import '../domain/sensor_model.dart';
import '../math/linear_algebra.dart';

/// Sensor RTD (ex.: Pt100). Pontos: x = T(°C), y = R(Ω).
///
/// Modelo Callendar–Van Dusen (positivo, T ≥ 0):
///   R(T) = R0 · (1 + A·T + B·T² + C·T³)
/// 3 incógnitas (A, B, C) com R0 fixo. Mais de 3 pontos: LSQ.
class RtdSensor extends SensorModel {
  RtdSensor({this.r0 = 100.0});
  final double r0;

  @override
  String get id => 'rtd';
  @override
  String get displayName => 'RTD (Pt100/Pt1000)';
  @override
  String get unitX => '°C';
  @override
  String get unitY => 'Ω';
  @override
  int get minPoints => 3;
  @override
  int get maxPoints => 8;

  @override
  List<CalibrationPoint> get defaultPoints => const [
        CalibrationPoint(x: 5, y: 101.8),
        CalibrationPoint(x: 32, y: 113.0),
        CalibrationPoint(x: 36.2, y: 113.8),
      ];

  @override
  (double, double) defaultRange() => (0, 100);

  @override
  CalibrationResult compute(List<CalibrationPoint> points) {
    if (points.length < 3) {
      throw ArgumentError('RTD exige no mínimo 3 pontos.');
    }
    if (points.any((p) => p.y <= 0)) {
      throw ArgumentError('Resistência deve ser > 0.');
    }
    // y_i = R_i/R0 - 1 = A·T + B·T² + C·T³
    final x = <List<double>>[];
    final y = <double>[];
    for (final p in points) {
      x.add([p.x, p.x * p.x, p.x * p.x * p.x]);
      y.add(p.y / r0 - 1.0);
    }
    final c = LinearAlgebra.leastSquares(x, y);

    return CalibrationResult(
      modelId: id,
      coefficients: {
        'R0': r0,
        'A': c[0],
        'B': c[1],
        'C': c[2],
      },
      notes:
          'R(T) = R0·(1 + A·T + B·T² + C·T³) — Callendar–Van Dusen (T ≥ 0 °C).',
    );
  }

  @override
  double yFromX(CalibrationResult r, double tC) {
    final r0 = r.coefficients['R0']!;
    final a = r.coefficients['A']!;
    final b = r.coefficients['B']!;
    final c = r.coefficients['C']!;
    return r0 * (1 + a * tC + b * tC * tC + c * tC * tC * tC);
  }

  @override
  double xFromY(CalibrationResult r, double resistance) {
    final r0 = r.coefficients['R0']!;
    final a = r.coefficients['A']!;
    final b = r.coefficients['B']!;
    final c = r.coefficients['C']!;
    final target = resistance / r0 - 1.0;
    // Resolve A·T + B·T² + C·T³ = target por Newton.
    return LinearAlgebra.newton(
      f: (t) => a * t + b * t * t + c * t * t * t - target,
      df: (t) => a + 2 * b * t + 3 * c * t * t,
      x0: target / (a == 0 ? 3.85e-3 : a),
    );
  }
}
