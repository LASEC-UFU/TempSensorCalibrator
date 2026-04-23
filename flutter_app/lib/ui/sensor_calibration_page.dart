import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/calibration_point.dart';
import '../domain/sensor_model.dart';
import '../math/num_utils.dart';
import 'widgets/calibration_chart.dart';
import 'widgets/section_card.dart';

/// Página genérica de calibração para qualquer SensorModel.
///
/// SOLID:
///  - SRP: somente UI / coordenação.
///  - OCP/DIP: depende da abstração SensorModel; novos sensores
///    se "encaixam" sem alterar este arquivo.
class SensorCalibrationPage extends StatefulWidget {
  const SensorCalibrationPage({super.key, required this.sensor});
  final SensorModel sensor;

  @override
  State<SensorCalibrationPage> createState() => _SensorCalibrationPageState();
}

class _SensorCalibrationPageState extends State<SensorCalibrationPage> {
  late List<CalibrationPoint> _points;
  late List<TextEditingController> _xCtrls;
  late List<TextEditingController> _yCtrls;

  CalibrationResult? _result;
  String? _error;

  final _calcXCtrl = TextEditingController();
  final _calcYCtrl = TextEditingController();
  String _calcYOut = '—';
  String _calcXOut = '—';

  late TextEditingController _xMinCtrl;
  late TextEditingController _xMaxCtrl;

  @override
  void initState() {
    super.initState();
    _resetPoints();
    final r = widget.sensor.defaultRange();
    _xMinCtrl = TextEditingController(text: r.$1.toString());
    _xMaxCtrl = TextEditingController(text: r.$2.toString());
    _autoCompute();
  }

  @override
  void didUpdateWidget(covariant SensorCalibrationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sensor.id != widget.sensor.id) {
      _resetPoints();
      final r = widget.sensor.defaultRange();
      _xMinCtrl.text = r.$1.toString();
      _xMaxCtrl.text = r.$2.toString();
      _result = null;
      _error = null;
      _calcYOut = '—';
      _calcXOut = '—';
      _autoCompute();
    }
  }

  void _resetPoints() {
    _points = List.of(widget.sensor.defaultPoints);
    _xCtrls = _points
        .map((p) => TextEditingController(text: _fmt(p.x)))
        .toList();
    _yCtrls = _points
        .map((p) => TextEditingController(text: _fmt(p.y)))
        .toList();
    _calcXCtrl.text = _fmt(_points.first.x);
    _calcYCtrl.text = _fmt(_points.first.y);
  }

  String _fmt(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e15) {
      return v.toStringAsFixed(0);
    }
    return v.toString();
  }

  String _fmtCoeff(double v) {
    final a = v.abs();
    if (a == 0) return '0';
    if (a < 1e-3 || a >= 1e6) return v.toStringAsExponential(6);
    return v.toStringAsPrecision(8);
  }

  @override
  void dispose() {
    for (final c in _xCtrls) {
      c.dispose();
    }
    for (final c in _yCtrls) {
      c.dispose();
    }
    _calcXCtrl.dispose();
    _calcYCtrl.dispose();
    _xMinCtrl.dispose();
    _xMaxCtrl.dispose();
    super.dispose();
  }

  List<CalibrationPoint> _readPoints() {
    return List.generate(_xCtrls.length, (i) {
      return CalibrationPoint(
        x: normFloat(_xCtrls[i].text),
        y: normFloat(_yCtrls[i].text),
      );
    });
  }

  void _autoCompute() {
    try {
      final pts = _readPoints();
      final r = widget.sensor.compute(pts);
      setState(() {
        _points = pts;
        _result = r;
        _error = null;
      });
    } catch (_) {
      // silencioso na auto-compute inicial
    }
  }

  void _onCompute() {
    try {
      final pts = _readPoints();
      final r = widget.sensor.compute(pts);
      setState(() {
        _points = pts;
        _result = r;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _onReset() {
    setState(() {
      _resetPoints();
      _result = null;
      _error = null;
      _calcYOut = '—';
      _calcXOut = '—';
    });
    _autoCompute();
  }

  void _addPoint() {
    if (_xCtrls.length >= widget.sensor.maxPoints) return;
    setState(() {
      _xCtrls.add(TextEditingController(text: '0'));
      _yCtrls.add(TextEditingController(text: '0'));
    });
  }

  void _removePoint(int i) {
    if (_xCtrls.length <= widget.sensor.minPoints) return;
    setState(() {
      _xCtrls.removeAt(i).dispose();
      _yCtrls.removeAt(i).dispose();
    });
  }

  void _calcYFromX() {
    if (_result == null) {
      _onCompute();
      if (_result == null) return;
    }
    try {
      final v = normFloat(_calcXCtrl.text);
      final y = widget.sensor.yFromX(_result!, v);
      setState(() => _calcYOut =
          '${y.toStringAsFixed(widget.sensor.unitY == 'mV' ? 4 : 3)} ${widget.sensor.unitY}');
    } catch (e) {
      setState(() => _calcYOut = 'erro: $e');
    }
  }

  void _calcXFromY() {
    if (_result == null) {
      _onCompute();
      if (_result == null) return;
    }
    try {
      final v = normFloat(_calcYCtrl.text);
      final x = widget.sensor.xFromY(_result!, v);
      setState(() => _calcXOut = '${x.toStringAsFixed(3)} ${widget.sensor.unitX}');
    } catch (e) {
      setState(() => _calcXOut = 'erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.sensor;

    final isWide = MediaQuery.sizeOf(context).width > 1100;

    final inputs = SectionCard(
      title: 'PONTOS DE CALIBRAÇÃO  (${s.unitX}, ${s.unitY})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _xCtrls.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text('${i + 1}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ),
                  Expanded(
                    child: _NumField(
                      controller: _xCtrls[i],
                      label: 'T (${s.unitX})',
                      onSubmitted: (_) => _onCompute(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumField(
                      controller: _yCtrls[i],
                      label: s.unitY == 'mV'
                          ? 'E (mV)'
                          : 'R (${s.unitY})',
                      onSubmitted: (_) => _onCompute(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remover',
                    onPressed: _xCtrls.length > s.minPoints
                        ? () => _removePoint(i)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _onCompute,
                icon: const Icon(Icons.calculate),
                label: const Text('Calcular'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _onReset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
              const Spacer(),
              if (s.maxPoints > s.minPoints)
                IconButton.filledTonal(
                  tooltip: 'Adicionar ponto',
                  onPressed: _xCtrls.length < s.maxPoints ? _addPoint : null,
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ],
      ),
    );

    final coeffsCard = SectionCard(
      title: 'COEFICIENTES',
      child: _result == null
          ? Text(
              'Preencha os pontos e clique em Calcular.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in _result!.coefficients.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        SelectableText(
                          _fmtCoeff(entry.value),
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (_result!.notes.isNotEmpty) ...[
                  const Divider(height: 18),
                  Text(_result!.notes,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
    );

    final calcCard = SectionCard(
      title: 'CALCULADORA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _NumField(
                  controller: _calcXCtrl,
                  label: '${s.unitX} →',
                  onSubmitted: (_) => _calcYFromX(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: _calcYFromX, child: const Text('=')),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(_calcYOut),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumField(
                  controller: _calcYCtrl,
                  label: '${s.unitY} →',
                  onSubmitted: (_) => _calcXFromY(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: _calcXFromY, child: const Text('=')),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(_calcXOut),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final rangeCard = SectionCard(
      title: 'GRÁFICO — FAIXA (${s.unitX})',
      child: Row(
        children: [
          Expanded(
            child: _NumField(
              controller: _xMinCtrl,
              label: 'mín',
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumField(
              controller: _xMaxCtrl,
              label: 'máx',
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => setState(() {}),
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );

    double xMin, xMax;
    try {
      xMin = normFloat(_xMinCtrl.text);
      xMax = normFloat(_xMaxCtrl.text);
    } catch (_) {
      final r = s.defaultRange();
      xMin = r.$1;
      xMax = r.$2;
    }

    final chart = SectionCard(
      title: '${s.unitY} × ${s.unitX}',
      child: SizedBox(
        height: 360,
        child: CalibrationChart(
          sensor: s,
          result: _result,
          points: _points,
          xMin: xMin,
          xMax: xMax,
        ),
      ),
    );

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        inputs,
        const SizedBox(height: 12),
        coeffsCard,
        const SizedBox(height: 12),
        calcCard,
        const SizedBox(height: 12),
        rangeCard,
      ],
    );

    final body = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 460, child: left),
              const SizedBox(width: 16),
              Expanded(child: chart),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 12), chart],
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: body,
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.label,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9eE\.\,\-\+]')),
      ],
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      textAlign: TextAlign.right,
    );
  }
}
