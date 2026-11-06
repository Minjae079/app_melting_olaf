import 'package:flutter/cupertino.dart';

import '../models/sensor_data.dart';
import '../widgets/temperature_chart.dart';

class MenuPage extends StatelessWidget {
  final bool connected;
  final bool demoMode;
  final SensorSnapshot? data;
  final String? error;

  final List<TemperaturePoint> history1;
  final List<TemperaturePoint> history2;

  final ValueChanged<bool> onModeChanged;

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

  static const background = Color(0xFFF2F2F7);
  static const ink = Color(0xFF1C1C1E);
  static const secondary = Color(0xFF8E8E93);
  static const blue = Color(0xFF007AFF);
  static const mint = Color(0xFF22AA93);
  static const green = Color(0xFF22A878);
  static const orange = Color(0xFFFF9500);
  static const red = Color(0xFFFF3B30);

  String temperatureText(double? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(2);
  }

  String slopeText(double? value) {
    if (value == null) return '분석 중';
    return '${value.toStringAsFixed(3)} °C/min';
  }

  String etaText(SensorData? sensor) {
    if (sensor == null || !sensor.ok) {
      return '측정 불가';
    }

    if (sensor.temperature != null && sensor.temperature! <= 2) {
      return '2°C 이하';
    }

    if (sensor.etaMinutes == null) {
      return '예측 불가';
    }

    return '${sensor.etaMinutes!.toStringAsFixed(1)}분';
  }

  Widget statusPill(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget sensorCard({
    required String title,
    required String pin,
    required SensorData? sensor,
    required Color accent,
  }) {
    final bool ok =
        connected && sensor?.ok == true && sensor?.temperature != null;

    final bool danger = ok && sensor!.danger;

    final Color statusColor = !connected
        ? secondary
        : !ok
        ? orange
        : danger
        ? red
        : green;

    final String statusText = !connected
        ? '대기 중'
        : !ok
        ? '연결 오류'
        : danger
        ? '동파 위험'
        : '정상';

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  CupertinoIcons.thermometer,
                  color: accent,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pin,
                      style: const TextStyle(fontSize: 12, color: secondary),
                    ),
                  ],
                ),
              ),

              statusPill(statusText, statusColor),
            ],
          ),

          const SizedBox(height: 27),

          if (ok)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  temperatureText(sensor?.temperature),
                  style: const TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.8,
                    color: ink,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 5, bottom: 8),
                  child: Text(
                    '°C',
                    style: TextStyle(fontSize: 22, color: secondary),
                  ),
                ),
              ],
            )
          else
            const Text(
              '측정 불가',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w600,
                color: secondary,
              ),
            ),

          const SizedBox(height: 8),

          Text(
            ok
                ? (danger ? '온도 하락에 주의가 필요해요.' : '현재 온도를 측정하고 있어요.')
                : (connected ? '센서 연결을 확인해주세요.' : '데이터 연결을 기다리고 있어요.'),
            style: const TextStyle(fontSize: 13, color: secondary),
          ),

          const SizedBox(height: 24),

          Container(height: 1, color: const Color(0xFFF0F0F2)),

          const SizedBox(height: 19),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '냉각 기울기',
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      ok ? slopeText(sensor?.slope) : '--',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),

              Container(width: 1, height: 38, color: const Color(0xFFE5E5EA)),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2°C 도달 예상',
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      ok ? etaText(sensor) : '--',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: ListView(
        key: const PageStorageKey('sensorScroll'),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
        children: [
          const Text(
            'LIVE MONITORING',
            style: TextStyle(
              color: blue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            '센서',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              color: ink,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            '실시간 온도와 냉각 속도',
            style: TextStyle(fontSize: 15, color: secondary),
          ),

          const SizedBox(height: 25),

          // Data source setting
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.waveform_path,
                    color: blue,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '테스트 데이터',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        demoMode ? '가상 온도 데이터 사용 중' : 'Arduino USB 데이터 수신',
                        style: const TextStyle(fontSize: 12, color: secondary),
                      ),
                    ],
                  ),
                ),

                CupertinoSwitch(
                  value: demoMode,
                  activeTrackColor: blue,
                  onChanged: onModeChanged,
                ),
              ],
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: red, fontSize: 12)),
          ],

          const SizedBox(height: 25),

          const Text(
            '연결된 센서',
            style: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 13),

          sensorCard(
            title: '센서 1',
            pin: 'Arduino D2',
            sensor: data?.sensor1,
            accent: blue,
          ),

          const SizedBox(height: 13),

          sensorCard(
            title: '센서 2',
            pin: 'Arduino D3',
            sensor: data?.sensor2,
            accent: mint,
          ),

          const SizedBox(height: 29),

          const Text(
            '온도 변화',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),

          const SizedBox(height: 13),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TemperatureChart(history1: history1, history2: history2),
          ),

          const SizedBox(height: 18),

          if (connected && data?.anyDanger == true)
            statusMessage(
              '동파 위험이 감지되었습니다.',
              CupertinoIcons.exclamationmark_triangle,
              red,
            ),

          if (connected && data?.anySensorError == true)
            statusMessage(
              '일부 센서의 연결을 확인해주세요.',
              CupertinoIcons.exclamationmark_circle,
              orange,
            ),
        ],
      ),
    );
  }

  Widget statusMessage(String message, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
