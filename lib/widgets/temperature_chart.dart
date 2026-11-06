import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/sensor_data.dart';

class TemperatureChart extends StatelessWidget {
  final List<TemperaturePoint> history1;
  final List<TemperaturePoint> history2;

  const TemperatureChart({
    super.key,
    required this.history1,
    required this.history2,
  });

  static const blue = Color(0xFF007AFF);
  static const mint = Color(0xFF22AA93);
  static const secondary = Color(0xFF8E8E93);

  List<FlSpot> makeSpots(List<TemperaturePoint> history, DateTime now) {
    return history.map((point) {
      final secondsAgo = now.difference(point.time).inMilliseconds / 1000.0;

      final x = (60.0 - secondsAgo).clamp(0.0, 60.0).toDouble();

      return FlSpot(x, point.value);
    }).toList();
  }

  Widget legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontSize: 12, color: secondary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = [...history1, ...history2];

    if (all.length < 2) {
      return const SizedBox(
        height: 210,
        child: Center(
          child: Text(
            '온도 데이터를 수집하고 있어요...',
            style: TextStyle(color: secondary, fontSize: 13),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final spots1 = makeSpots(history1, now);
    final spots2 = makeSpots(history2, now);

    final values = all.map((point) => point.value).toList();

    final minTemp = values.reduce(math.min);
    final maxTemp = values.reduce(math.max);

    final double bottom = minTemp - 0.7;
    final double top = maxTemp + 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '최근 60초',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),

        const SizedBox(height: 15),

        Row(
          children: [
            legendDot('센서 1', blue),
            const SizedBox(width: 18),
            legendDot('센서 2', mint),
          ],
        ),

        const SizedBox(height: 21),

        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 60,
              minY: bottom,
              maxY: top,

              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return const FlLine(color: Color(0xFFF0F0F2), strokeWidth: 1);
                },
              ),

              borderData: FlBorderData(show: false),

              titlesData: const FlTitlesData(show: false),

              lineBarsData: [
                if (spots1.isNotEmpty)
                  LineChartBarData(
                    spots: spots1,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: blue,
                    barWidth: 2.8,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: blue.withOpacity(0.06),
                    ),
                  ),

                if (spots2.isNotEmpty)
                  LineChartBarData(
                    spots: spots2,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: mint,
                    barWidth: 2.8,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('60초 전', style: TextStyle(fontSize: 11, color: secondary)),
            Text('현재', style: TextStyle(fontSize: 11, color: secondary)),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          '측정 범위  '
          '${minTemp.toStringAsFixed(1)}'
          ' ~ '
          '${maxTemp.toStringAsFixed(1)} °C',
          style: const TextStyle(fontSize: 12, color: secondary),
        ),
      ],
    );
  }
}
