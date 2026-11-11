import 'package:flutter/material.dart';

import '../models/sensor_data.dart';
import '../widgets/temperature_chart.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({
    super.key,
    required this.connected,
    required this.demoMode,
    required this.data,
    required this.error,
    required this.history1,
    required this.history2,
    required this.onModeChanged,
  });

  final bool connected;
  final bool demoMode;
  final SensorSnapshot? data;
  final String? error;
  final List<TemperaturePoint> history1;
  final List<TemperaturePoint> history2;
  final ValueChanged<bool> onModeChanged;

  String _temperature(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)}°';
  String _slope(double? value) =>
      value == null ? '계산 중' : '${value.toStringAsFixed(2)} °C/min';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          '모니터링',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -1),
        ),
        const SizedBox(height: 8),
        const Text('최근 온도와 변화 속도', style: TextStyle(color: Color(0xFF777872))),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SensorCard(
                label: '센서 1',
                sensor: data?.sensor1,
                connected: connected,
                temperature: _temperature,
                slope: _slope,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                label: '센서 2',
                sensor: data?.sensor2,
                connected: connected,
                temperature: _temperature,
                slope: _slope,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: TemperatureChart(history1: history1, history2: history2),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 4,
            ),
            title: const Text('데모 데이터'),
            subtitle: Text(demoMode ? '가상 측정값 사용 중' : 'Supabase 데이터 사용 중'),
            value: demoMode,
            activeTrackColor: const Color(0xFF7A7D76),
            onChanged: onModeChanged,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: const TextStyle(color: Color(0xFF76554D), fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.label,
    required this.sensor,
    required this.connected,
    required this.temperature,
    required this.slope,
  });

  final String label;
  final SensorData? sensor;
  final bool connected;
  final String Function(double?) temperature;
  final String Function(double?) slope;

  @override
  Widget build(BuildContext context) {
    final ok = connected && sensor?.ok == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Color(0xFF777872)),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ok
                        ? const Color(0xFF626A63)
                        : const Color(0xFF8A756F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              ok ? temperature(sensor?.temperature) : '--',
              style: const TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w500,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ok ? slope(sensor?.slope) : '데이터 없음',
              style: const TextStyle(fontSize: 12, color: Color(0xFF858680)),
            ),
          ],
        ),
      ),
    );
  }
}
