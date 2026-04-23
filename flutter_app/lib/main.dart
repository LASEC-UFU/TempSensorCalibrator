import 'package:flutter/material.dart';

import 'domain/calibration_point.dart';
import 'domain/sensor_model.dart';
import 'sensors/sensor_registry.dart';
import 'ui/about_dialog.dart';
import 'ui/sensor_config_panel.dart';
import 'ui/theme/app_palette.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/calibration_chart.dart';

void main() => runApp(const TempCalibratorApp());

class TempCalibratorApp extends StatelessWidget {
  const TempCalibratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temp Sensor Calibrator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const ShellPage(),
    );
  }
}

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;
  bool _leftOpen = true;
  bool _rightOpen = true;

  // Estado do painel direito (espelhado para o gráfico).
  SensorPanelState? _panel;

  static const double _leftWidth = 240;
  static const double _rightWidth = 420;
  static const double _railWidth = 56;
  static const double _wideBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    final sensors = SensorRegistry.sensors;
    final selected = sensors[_index];
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > _wideBreakpoint;

    // Em telas estreitas, painéis vão para drawers.
    final useDrawers = !isWide;

    return Scaffold(
      backgroundColor: AppPalette.background,
      drawer: useDrawers
          ? _SensorDrawer(
              sensors: sensors,
              index: _index,
              onSelect: (i) {
                setState(() => _index = i);
                Navigator.of(context).pop();
              },
            )
          : null,
      endDrawer: useDrawers
          ? Drawer(
              backgroundColor: AppPalette.surface,
              width: 380,
              child: SafeArea(
                child: SensorConfigPanel(
                  key: ValueKey('cfg-${selected.id}'),
                  sensor: selected,
                  onChanged: (s) => setState(() => _panel = s),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          _AppHeader(
            sensor: selected,
            useDrawers: useDrawers,
            leftOpen: _leftOpen,
            rightOpen: _rightOpen,
            onToggleLeft: () => setState(() => _leftOpen = !_leftOpen),
            onToggleRight: () => setState(() => _rightOpen = !_rightOpen),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    width: _leftOpen ? _leftWidth : _railWidth,
                    decoration: const BoxDecoration(
                      color: AppPalette.surface,
                      border: Border(
                          right: BorderSide(color: AppPalette.border)),
                    ),
                    child: _LeftNav(
                      sensors: sensors,
                      index: _index,
                      collapsed: !_leftOpen,
                      onSelect: (i) => setState(() => _index = i),
                      onToggle: () =>
                          setState(() => _leftOpen = !_leftOpen),
                    ),
                  ),
                Expanded(
                  child: _ChartCenter(
                    sensor: selected,
                    panel: _panel,
                  ),
                ),
                if (isWide)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    width: _rightOpen ? _rightWidth : _railWidth,
                    decoration: const BoxDecoration(
                      color: AppPalette.surface,
                      border: Border(
                          left: BorderSide(color: AppPalette.border)),
                    ),
                    child: _rightOpen
                        ? Column(
                            children: [
                              _RightHeader(
                                sensor: selected,
                                onCollapse: () =>
                                    setState(() => _rightOpen = false),
                              ),
                              Expanded(
                                child: SensorConfigPanel(
                                  key: ValueKey('cfg-${selected.id}'),
                                  sensor: selected,
                                  onChanged: (s) =>
                                      setState(() => _panel = s),
                                ),
                              ),
                            ],
                          )
                        : _CollapsedRail(
                            icon: Icons.tune,
                            label: 'CONFIGURAÇÕES',
                            onTap: () => setState(() => _rightOpen = true),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCenter extends StatelessWidget {
  const _ChartCenter({required this.sensor, required this.panel});
  final SensorModel sensor;
  final SensorPanelState? panel;

  @override
  Widget build(BuildContext context) {
    final r = sensor.defaultRange();
    final xMin = panel?.xMin ?? r.$1;
    final xMax = panel?.xMax ?? r.$2;
    final pts = panel?.points ?? const <CalibrationPoint>[];
    final result = panel?.result;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppPalette.forSensorId(sensor.id)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.show_chart,
                    color: AppPalette.forSensorId(sensor.id),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${sensor.unitY} × ${sensor.unitX}',
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  sensor.displayName,
                  style: const TextStyle(
                    color: AppPalette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppPalette.divider),
            const SizedBox(height: 10),
            Expanded(
              child: CalibrationChart(
                sensor: sensor,
                result: result,
                points: pts,
                xMin: xMin,
                xMax: xMax,
                accentColor: AppPalette.forSensorId(sensor.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.sensor,
    required this.useDrawers,
    required this.leftOpen,
    required this.rightOpen,
    required this.onToggleLeft,
    required this.onToggleRight,
  });
  final SensorModel sensor;
  final bool useDrawers;
  final bool leftOpen;
  final bool rightOpen;
  final VoidCallback onToggleLeft;
  final VoidCallback onToggleRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppPalette.headerGradient),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Builder(builder: (ctx) {
              return IconButton(
                tooltip: 'Sensores',
                icon: Icon(
                  useDrawers
                      ? Icons.menu
                      : (leftOpen
                          ? Icons.chevron_left
                          : Icons.menu_open),
                  color: Colors.white,
                ),
                onPressed: () => useDrawers
                    ? Scaffold.of(ctx).openDrawer()
                    : onToggleLeft(),
              );
            }),
            const SizedBox(width: 4),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.science_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temperature Sensor Calibrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'NTC · RTD · Termopares — ${sensor.displayName}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'WASM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sobre o modelo',
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () =>
                  showSensorAboutDialog(context, sensor: sensor),
            ),
            Builder(builder: (ctx) {
              return IconButton(
                tooltip: 'Configurações',
                icon: Icon(
                  useDrawers
                      ? Icons.tune
                      : (rightOpen ? Icons.chevron_right : Icons.tune),
                  color: Colors.white,
                ),
                onPressed: () => useDrawers
                    ? Scaffold.of(ctx).openEndDrawer()
                    : onToggleRight(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RightHeader extends StatelessWidget {
  const _RightHeader({required this.sensor, required this.onCollapse});
  final SensorModel sensor;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final accent = AppPalette.forSensorId(sensor.id);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'CONFIGURAÇÕES',
              style: TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Esconder painel',
            onPressed: onCollapse,
            icon: const Icon(Icons.chevron_right),
            color: AppPalette.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _LeftNav extends StatelessWidget {
  const _LeftNav({
    required this.sensors,
    required this.index,
    required this.collapsed,
    required this.onSelect,
    required this.onToggle,
  });
  final List<SensorModel> sensors;
  final int index;
  final bool collapsed;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return _CollapsedRail(
        icon: Icons.sensors,
        label: 'SENSORES',
        onTap: onToggle,
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppPalette.border)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'SENSORES',
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Esconder painel',
                onPressed: onToggle,
                icon: const Icon(Icons.chevron_left),
                color: AppPalette.textSecondary,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              for (var i = 0; i < sensors.length; i++)
                _NavTile(
                  sensor: sensors[i],
                  selected: i == index,
                  onTap: () => onSelect(i),
                ),
              const SizedBox(height: 16),
              const _Footer(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollapsedRail extends StatelessWidget {
  const _CollapsedRail({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: AppPalette.textSecondary, size: 20),
            const SizedBox(height: 12),
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppPalette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.sensor,
    required this.selected,
    required this.onTap,
  });
  final SensorModel sensor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppPalette.forSensorId(sensor.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: selected ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(_iconFor(sensor.id), color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sensor.displayName,
                    style: TextStyle(
                      color: selected
                          ? AppPalette.textPrimary
                          : AppPalette.textSecondary,
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.school_outlined,
                  size: 14, color: AppPalette.textMuted),
              const SizedBox(width: 6),
              Text(
                'LASEC · UFU',
                style: TextStyle(
                  color: AppPalette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Calibração de sensores de temperatura',
            style: TextStyle(
              color: AppPalette.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorDrawer extends StatelessWidget {
  const _SensorDrawer({
    required this.sensors,
    required this.index,
    required this.onSelect,
  });
  final List<SensorModel> sensors;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppPalette.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration:
                  const BoxDecoration(gradient: AppPalette.headerGradient),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_outlined, color: Colors.white, size: 28),
                  SizedBox(height: 10),
                  Text(
                    'Temp Calibrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'NTC · RTD · Termopares',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  for (var i = 0; i < sensors.length; i++)
                    _NavTile(
                      sensor: sensors[i],
                      selected: i == index,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String id) {
  if (id == 'ntc') return Icons.thermostat_auto;
  if (id == 'rtd') return Icons.cable;
  return Icons.flash_on;
}
