// Tradução fiel de _design/showcases/charts.jsx (componente ChartCard).

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Card visual de um chart: título + subtítulo + action opcional + área do gráfico.
class ChartCard extends StatelessWidget {
  const ChartCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.chartHeight = 240,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(YaSpacing.lg),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth.isFinite && constraints.maxWidth < 420;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: YaText.smMedium.copyWith(color: colors.textPrimary),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: YaText.sans(size: 11, height: 14)
                          .copyWith(color: colors.textMuted),
                    ),
                  ],
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    if (action != null) ...[
                      const SizedBox(height: YaSpacing.sm),
                      action!,
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  if (action != null) action!,
                ],
              );
            },
          ),
          const SizedBox(height: YaSpacing.md),
          SizedBox(height: chartHeight, child: child),
        ],
      ),
    );
  }
}
