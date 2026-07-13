// Tradução fiel de _design/showcases/auxiliaries.jsx (componente TooltipPreview).

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Tooltip YA: bg em `text-primary` (inverso), texto em `text-inverse`,
/// fonte 12px, padding 6/10, radius 4, sem arrow.
///
/// Wrapper sobre [Tooltip] do Material com tema YA aplicado.
class YaTooltip extends StatelessWidget {
  const YaTooltip({
    required this.message,
    required this.child,
    this.preferBelow = false,
    super.key,
  });

  final String message;
  final Widget child;
  final bool preferBelow;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      waitDuration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.textPrimary,
        borderRadius: YaRadius.brXs,
        boxShadow: isLight ? YaShadows.md : YaShadows.none,
      ),
      textStyle: YaText.sans(size: 12, height: 16)
          .copyWith(color: colors.textInverse),
      child: child,
    );
  }
}
