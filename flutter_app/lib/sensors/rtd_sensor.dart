import '../domain/calibration_point.dart';
import '../domain/sensor_model.dart';
import '../math/linear_algebra.dart';

/// Sensor RTD (ex.: Pt100). Pontos: x = T(°C), y = R(Ω).
///
/// Curva principal:
///   R(T) = R0 · (1 + A·T + B·T² + C·T³)
/// 3 incógnitas (A, B, C) com R0 fixo. Mais de 3 pontos: LSQ.
///
/// Curva secundária:
///   R(T) = R0 · (1 + α·T)
/// conforme a aproximação linear apresentada no material de apoio.
class RtdSensor extends SensorModel {
  RtdSensor({this.r0 = 100.0, this.alpha = 0.0038459});

  final double r0;
  final double alpha;

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
        'α': alpha,
        'A': c[0],
        'B': c[1],
        'C': c[2],
      },
      notes:
          'Curvas exibidas: Callendar–Van Dusen e aproximação linear R(T) = R0·(1 + α·T).',
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

    // Mantém a calculadora principal baseada em CVD.
    return LinearAlgebra.newton(
      f: (t) => a * t + b * t * t + c * t * t * t - target,
      df: (t) => a + 2 * b * t + 3 * c * t * t,
      x0: target / (a == 0 ? alpha : a),
    );
  }

  double _alphaR(CalibrationResult r, double tC) {
    final r0 = r.coefficients['R0']!;
    final alpha = r.coefficients['α']!;
    return r0 * (1 + alpha * tC);
  }

  @override
  List<ModelCurve> curves(CalibrationResult result) => [
        ModelCurve(
          label: 'Callendar–Van Dusen',
          evaluate: (x) => yFromX(result, x),
        ),
        ModelCurve(
          label: 'Linear / α',
          evaluate: (x) => _alphaR(result, x),
        ),
      ];
}
