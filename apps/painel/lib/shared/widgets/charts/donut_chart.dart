// Tradução fiel de _design/showcases/charts.jsx (componente DonutChart).
// Layout: anel à esquerda + legenda à direita.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Slice de uma [YaDonutChart].
@immutable
class YaDonutSlice {
  const YaDonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;
}

/// Donut com legenda. Centro mostra `centerValue` + `centerLabel`.
class YaDonutChart extends StatelessWidget {
  const YaDonutChart({
    required this.slices,
    this.centerValue,
    this.centerLabel,
    this.size = 180,
    this.thickness = 28,
    super.key,
  });

  final List<YaDonutSlice> slices;
  final String? centerValue;
  final String? centerLabel;
  final double size;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final total = slices.fold<double>(0, (s, e) => s + e.value);

    final chart = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: (size - thickness * 2) / 2,
              sectionsSpace: 0,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(enabled: false),
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.value,
                    color: s.color,
                    radius: thickness,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          if (centerValue != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerValue!,
                  style: YaText.serif(
                    size: 20,
                    height: 24,
                    weight: FontWeight.w500,
                  ).copyWith(color: colors.textPrimary),
                ),
                if (centerLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    centerLabel!.toUpperCase(),
                    style: YaText.sans(
                      size: 10,
                      height: 14,
                      letterSpacing: 0.5, // 0.05em * 10
                    ).copyWith(color: colors.textMuted),
                  ),
                ],
              ],
            ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth.isFinite &&
            constraints.maxWidth < size + 180 + YaSpacing.xxl;

        if (compact) {
          return Column(
            children: [
              chart,
              const SizedBox(height: YaSpacing.lg),
              _Legend(slices: slices, total: total),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            chart,
            const SizedBox(width: YaSpacing.xxl),
            Flexible(child: _Legend(slices: slices, total: total)),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.slices, required this.total});
  final List<YaDonutSlice> slices;
  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < slices.length; i++) ...[
          if (i > 0) const SizedBox(height: YaSpacing.sm),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: slices[i].color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: YaSpacing.sm),
              Expanded(
                child: Text(
                  slices[i].label,
                  style: YaText.sans(size: 12, height: 16)
                      .copyWith(color: colors.textSecondary),
                ),
              ),
              Text(
                '${(slices[i].value / total * 100).round()}%',
                style: YaText.mono(size: 12, height: 16)
                    .copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
