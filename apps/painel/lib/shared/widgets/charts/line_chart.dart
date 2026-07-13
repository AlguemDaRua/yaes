// Tradução fiel de _design/showcases/charts.jsx (LineChart + AreaChart).
// Wrapper sobre fl_chart com tokens YA.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/typography.dart';

/// Série de uma [YaLineChart].
@immutable
class YaLineSeries {
  const YaLineSeries({
    required this.values,
    required this.color,
    this.dashed = false,
  });
  final List<double> values;
  final Color color;
  final bool dashed;
}

/// Multi-linha com pontos. Eixos com tabular figures e grid tracejada.
class YaLineChart extends StatelessWidget {
  const YaLineChart({
    required this.series,
    required this.labels,
    this.yTicks = 4,
    this.area = false,
    super.key,
  });

  final List<YaLineSeries> series;
  final List<String> labels;
  final int yTicks;

  /// Se true, adiciona área sob a primeira série (gradient brand).
  final bool area;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);

    final allValues = series.expand((s) => s.values).toList();
    if (allValues.isEmpty) return const SizedBox.shrink();
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    const minY = 0.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (labels.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / yTicks,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.borderSubtle,
            strokeWidth: 1,
            dashArray: value == 0 ? null : const [2, 3],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: maxY / yTicks,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _formatTick(value),
                  style: YaText.mono(size: 10, height: 14)
                      .copyWith(color: colors.textMuted),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[i],
                    style: YaText.sans(size: 10, height: 14)
                        .copyWith(color: colors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          for (var i = 0; i < series.length; i++)
            _seriesToBarData(series[i], filled: area && i == 0),
        ],
      ),
    );
  }

  LineChartBarData _seriesToBarData(YaLineSeries s, {required bool filled}) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < s.values.length; i++)
          FlSpot(i.toDouble(), s.values[i]),
      ],
      color: s.color,
      isStrokeCapRound: true,
      dashArray: s.dashed ? const [4, 4] : null,
      dotData: FlDotData(
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 2.5,
          color: s.color,
        ),
      ),
      belowBarData: filled
          ? BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  s.color.withValues(alpha: 0.35),
                  s.color.withValues(alpha: 0.02),
                ],
              ),
            )
          : BarAreaData(),
    );
  }

  String _formatTick(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).round()}k';
    return v.round().toString();
  }
}
