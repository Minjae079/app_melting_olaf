import 'package:flutter/cupertino.dart';

import '../models/sensor_data.dart';

class HomePage extends StatelessWidget {
  final bool connected;
  final bool demoMode;
  final SensorSnapshot? data;
  final DateTime? lastUpdated;
  final String? error;
  final VoidCallback onOpenMenu;

  const HomePage({
    super.key,
    required this.connected,
    required this.demoMode,
    required this.data,
    required this.lastUpdated,
    required this.error,
    required this.onOpenMenu,
  });

  static const background = Color(0xFFF2F2F7);
  static const ink = Color(0xFF1C1C1E);
  static const secondary = Color(0xFF8E8E93);
  static const blue = Color(0xFF007AFF);
  static const green = Color(0xFF20A77A);
  static const orange = Color(0xFFFF9500);
  static const red = Color(0xFFFF3B30);

  String formatTime(DateTime? time) {
    if (time == null) return '기록 없음';

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(time.hour)}:'
        '${two(time.minute)}:'
        '${two(time.second)}';
  }

  Widget infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: secondary, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, color: ink),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: secondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final danger = connected && (data?.anyDanger ?? false);

    final sensorError = connected && (data?.anySensorError ?? false);

    final Color statusColor = !connected
        ? secondary
        : danger
        ? red
        : sensorError
        ? orange
        : green;

    final String statusTitle = !connected
        ? '연결을 확인해주세요'
        : danger
        ? '동파 위험이 감지됐어요'
        : sensorError
        ? '센서 점검이 필요해요'
        : '현재 배관은 안전해요';

    final String description = !connected
        ? '최근 센서 데이터를 수신하지 못했어요.'
        : danger
        ? '냉각 속도와 온도가 위험 기준에 도달했어요.'
        : sensorError
        ? '일부 센서의 측정값을 확인할 수 없어요.'
        : '현재 동파 위험 조건이 감지되지 않았어요.';

    final IconData statusIcon = !connected
        ? CupertinoIcons.wifi_slash
        : danger
        ? CupertinoIcons.exclamationmark_triangle_fill
        : sensorError
        ? CupertinoIcons.exclamationmark_circle_fill
        : CupertinoIcons.checkmark_shield_fill;

    final int working = connected ? (data?.workingCount ?? 0) : 0;

    return Container(
      color: background,
      child: ListView(
        key: const PageStorageKey('homeScroll'),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
        children: [
          const Text(
            'PIPE GUARD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: blue,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            '홈',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              color: ink,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            '오늘의 배관 안전 상태를 확인하세요.',
            style: TextStyle(fontSize: 15, color: secondary),
          ),

          const SizedBox(height: 30),

          // Main status card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 29),
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            connected
                                ? (danger
                                      ? '위험'
                                      : sensorError
                                      ? '점검 필요'
                                      : '모니터링 중')
                                : '연결 안 됨',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 27),

                Text(
                  statusTitle,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: ink,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: secondary,
                  ),
                ),

                const SizedBox(height: 24),

                Container(height: 1, color: const Color(0xFFF0F0F2)),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Icon(
                      CupertinoIcons.waveform_path,
                      color: statusColor,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        connected ? '센서 상태 실시간 확인 중' : '실시간 데이터 수신 중단',
                        style: const TextStyle(fontSize: 13, color: secondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 31),

          const Text(
            '시스템 요약',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                infoRow(CupertinoIcons.thermometer, '정상 센서', '$working / 2개'),

                const DividerLine(),

                infoRow(
                  CupertinoIcons.link,
                  '데이터 연결',
                  connected ? '연결됨' : '연결 안 됨',
                ),

                const DividerLine(),

                infoRow(
                  CupertinoIcons.square_grid_2x2,
                  '데이터 모드',
                  demoMode ? '테스트' : 'Arduino USB',
                ),

                const DividerLine(),

                infoRow(
                  CupertinoIcons.clock,
                  '마지막 수신',
                  formatTime(lastUpdated),
                ),
              ],
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: red, fontSize: 12)),
          ],

          const SizedBox(height: 26),

          CupertinoButton(
            color: blue,
            borderRadius: BorderRadius.circular(17),
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
            onPressed: onOpenMenu,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '센서 자세히 보기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
                Icon(CupertinoIcons.arrow_right, size: 18),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            '현재 버전은 앱을 실행 중일 때 위험을 알립니다. '
            '백그라운드 푸시 알림은 아직 지원하지 않습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.5, color: secondary),
          ),
        ],
      ),
    );
  }
}

// Thin iOS-style separator
class DividerLine extends StatelessWidget {
  const DividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: const Color(0xFFE5E5EA));
  }
}
