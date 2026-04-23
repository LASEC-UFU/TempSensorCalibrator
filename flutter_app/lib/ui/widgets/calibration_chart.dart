import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/calibration_point.dart';
import '../domain/sensor_model.dart';

class CalibrationChart extends StatelessWidget {
  const CalibrationChart({
    super.key,
    required this.sensor,
    required this.result,
    required this.points,
    required this.xMin,
    required this.xMax,
  });

  final SensorModel sensor;
  final CalibrationResult? result;
  final List<CalibrationPoint> points;
  final double xMin;
  final double xMax;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelLine = <FlSpot>[];
    if (result != null) {
      const n = 80;
      final lo = xMin;
      final hi = xMax > xMin ? xMax : xMin + 1;
      final dx = (hi - lo) / (n - 1);
      for (var i = 0; i < n; i++) {
        final t = lo + i * dx;
        try {
          final y = sensor.yFromX(result!, t);
          if (y.isFinite) modelLine.add(FlSpot(t, y));
        } catch (_) {}
      }
    }
    final dataDots = points.map((p) => FlSpot(p.x, p.y)).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: LineChart(
          LineChartData(
            minX: xMin,
            maxX: xMax > xMin ? xMax : xMin + 1,
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                axisNameWidget:
                    Text('Temperatura (${sensor.unitX})'),
                sideTitles: const SideTitles(showTitles: true, reservedSize: 28),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Text(sensor.unitY),
                sideTitles: const SideTitles(showTitles: true, reservedSize: 56),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            lineBarsData: [
              if (modelLine.isNotEmpty)
                LineChartBarData(
                  spots: modelLine,
                  isCurved: false,
                  color: theme.colorScheme.primary,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                ),
              if (dataDots.isNotEmpty)
                LineChartBarData(
                  spots: dataDots,
                  color: Colors.amberAccent,
                  barWidth: 0,
                  dotData: const FlDotData(show: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
