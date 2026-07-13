import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

class InfoCardRow {
  const InfoCardRow(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool highlight;
}

class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.rows, super.key});
  final String title;
  final List<InfoCardRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: YaSpacing.cardMd,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: YaRadius.brLg,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: isLight ? YaShadows.sm : YaShadows.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: YaText.smMedium.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: YaSpacing.md),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: YaSpacing.md * 2,
                thickness: 1,
                color: colors.borderSubtle,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 5,
                  child: Text(
                    rows[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: YaText.sm.copyWith(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(width: YaSpacing.sm),
                Flexible(
                  flex: 6,
                  child: Text(
                    rows[i].value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: YaText.monoBase.copyWith(
                      color: rows[i].highlight
                          ? colors.danger
                          : colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
