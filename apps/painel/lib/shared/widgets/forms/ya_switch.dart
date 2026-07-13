import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Wrapper de Switch com tokens YA.
class YaSwitch extends StatelessWidget {
  const YaSwitch({
    required this.value,
    required this.onChanged,
    this.label,
    this.subtitle,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);

    final hasCopy = label != null || subtitle != null;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: YaText.smMedium.copyWith(color: colors.textPrimary),
          ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: YaText.sans(size: 12, height: 16)
                .copyWith(color: colors.textMuted),
          ),
      ],
    );

    final control = Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: colors.brand,
      activeTrackColor: colors.brandSubtle,
      inactiveThumbColor: colors.textMuted,
      inactiveTrackColor: colors.bgSubtle,
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (!constraints.maxWidth.isFinite) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCopy) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: copy,
              ),
              const SizedBox(width: YaSpacing.sm),
            ],
            control,
          ],
        );
      }

      return Row(
        children: [
          if (hasCopy) Expanded(child: copy),
          control,
        ],
      );
    },);
  }
}
