import 'package:flutter/material.dart';

import 'domain/sensor_model.dart';
import 'sensors/sensor_registry.dart';
import 'ui/sensor_calibration_page.dart';

void main() => runApp(const TempCalibratorApp());

class TempCalibratorApp extends StatelessWidget {
  const TempCalibratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0EA5E9),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Temp Sensor Calibrator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        cardTheme: CardThemeData(
          color: scheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          border: OutlineInputBorder(),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final sensors = SensorRegistry.sensors;
    final selected = sensors[_index];
    final wide = MediaQuery.sizeOf(context).width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.thermostat, color: Color(0xFF0EA5E9)),
            const SizedBox(width: 10),
            const Text('Temp Sensor Calibrator'),
            const Spacer(),
            Text(
              selected.displayName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      drawer: wide
          ? null
          : _SensorDrawer(
              sensors: sensors,
              index: _index,
              onSelect: (i) {
                setState(() => _index = i);
                Navigator.of(context).pop();
              },
            ),
      body: Row(
        children: [
          if (wide)
            _SideNav(
              sensors: sensors,
              index: _index,
              onSelect: (i) => setState(() => _index = i),
            ),
          Expanded(
            child: SensorCalibrationPage(
              key: ValueKey(selected.id),
              sensor: selected,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.sensors,
    required this.index,
    required this.onSelect,
  });
  final List<SensorModel> sensors;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 230,
      color: theme.colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: sensors.length,
        itemBuilder: (_, i) {
          final s = sensors[i];
          final selected = i == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Material(
              color: selected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelect(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _iconFor(s.id),
                        size: 18,
                        color: selected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.displayName,
                          style: TextStyle(
                            color: selected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text(
                'Sensores',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            for (var i = 0; i < sensors.length; i++)
              ListTile(
                leading: Icon(_iconFor(sensors[i].id)),
                title: Text(sensors[i].displayName),
                selected: i == index,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String id) {
  if (id == 'ntc') return Icons.device_thermostat;
  if (id == 'rtd') return Icons.cable;
  return Icons.electric_bolt;
}
