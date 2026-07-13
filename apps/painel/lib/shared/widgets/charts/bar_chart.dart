// Tradução fiel de _design/showcases/charts.jsx (componente BarChart).
// Wrapper sobre fl_chart com tokens YA. Suporta empilhado (stacked).

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/typography.dart';

/// Bar chart vertical: barras simples ou empilhadas (primary + secondary).
class YaBarChart extends StatelessWidget {
  const YaBarChart({
    required this.values,
    required this.labels,
    this.secondary,
    this.primaryColor,
    this.secondaryColor,
    this.barWidth = 36,
    this.yTicks = 4,
    super.key,
  });

  final List<double> values;
  final List<String> labels;

  /// Se fornecido, barras ficam empilhadas (primary em baixo, secondary em cima).
  final List<double>? secondary;

  final Color? primaryColor;
  final Color? secondaryColor;
  final double barWidth;
  final int yTicks;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final pColor = primaryColor ?? colors.brand;
    final sColor = secondaryColor ?? colors.info;

    final stacked = secondary != null;
    final totals = stacked
        ? [for (var i = 0; i < values.length; i++) values[i] + secondary![i]]
        : values;
    final rawMax =
        totals.isEmpty ? 0.0 : totals.reduce((a, b) => a > b ? a : b);
    // Guard against an all-zero/empty dataset: fl_chart asserts that the grid
    // interval (maxY / yTicks) is non-zero.
    final maxY = rawMax <= 0 ? 1.0 : rawMax;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        barTouchData: const BarTouchData(enabled: false),
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
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: stacked ? values[i] + secondary![i] : values[i],
                  width: barWidth,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                  rodStackItems: stacked
                      ? [
                          BarChartRodStackItem(0, values[i], pColor),
                          BarChartRodStackItem(
                            values[i],
                            values[i] + secondary![i],
                            sColor,
                          ),
                        ]
                      : [],
                  color: stacked ? null : pColor,
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatTick(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).round()}k';
    return v.round().toString();
  }
}
