import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/status_mapping.dart';
import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Banner inline de alerta para paginas e detalhes de entidades.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.message,
    this.variant = StatusVariant.warning,
    this.action,
    this.actionLabel,
    this.onDismiss,
    super.key,
  });

  final String message;
  final StatusVariant variant;
  final VoidCallback? action;
  final String? actionLabel;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final palette = variant.resolve(colors);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YaSpacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(
          left: BorderSide(color: palette.text, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(_iconFor(variant), size: 14, color: palette.text),
          const SizedBox(width: YaSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: YaText.sans(size: 12, height: 16)
                  .copyWith(color: colors.textSecondary),
            ),
          ),
          if (action != null && actionLabel != null) ...[
            const SizedBox(width: YaSpacing.md),
            GestureDetector(
              onTap: action,
              child: Text(
                actionLabel!,
                style: YaText.smMedium.copyWith(color: palette.text),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: YaSpacing.sm),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(LucideIcons.x, size: 14, color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(StatusVariant variant) => switch (variant) {
        StatusVariant.danger => LucideIcons.triangleAlert,
        StatusVariant.warning => LucideIcons.triangleAlert,
        StatusVariant.info => LucideIcons.info,
        StatusVariant.success => LucideIcons.circleCheck,
        _ => LucideIcons.info,
      };
}
