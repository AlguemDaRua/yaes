// Tradução fiel de _design/showcases/data-table.jsx + forms-and-controls.jsx
// (chips em FilterBar, com variantes semânticas no estado active).
// Spec: _design/components.md §7.

import 'package:flutter/material.dart';

import '../../../core/constants/status_mapping.dart';
import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Chip de filtro com label + count opcional.
///
/// Quando `active`, usa cor semântica via [variant] (default: brand).
/// "Activos · online" usa `success`, "Pendentes" usa `warning`, etc.
class YaFilterChip extends StatefulWidget {
  const YaFilterChip({
    required this.label,
    this.count,
    this.active = false,
    this.variant = StatusVariant.brand,
    this.onTap,
    super.key,
  });

  final String label;
  final int? count;
  final bool active;

  /// Cor semântica quando active. Default `brand`.
  final StatusVariant variant;
  final VoidCallback? onTap;

  @override
  State<YaFilterChip> createState() => _YaFilterChipState();
}

class _YaFilterChipState extends State<YaFilterChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final active = widget.active;

    final Color bg;
    final Color borderColor;
    final Color fg;
    if (active) {
      final accent = widget.variant.resolve(colors);
      bg = _hovering ? _hoveredAccent(colors, widget.variant) : accent.bg;
      borderColor = _accentBorder(colors, widget.variant);
      fg = accent.text;
    } else {
      bg = _hovering ? colors.bgSubtle : Colors.transparent;
      borderColor = _hovering ? colors.borderDefault : colors.borderSubtle;
      fg = _hovering ? colors.textPrimary : colors.textSecondary;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: YaDurations.micro,
          curve: YaDurations.easeOut,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: YaSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: YaRadius.brFull,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: YaText.sans(
                  size: 12,
                  height: 16,
                  weight: active ? FontWeight.w500 : FontWeight.w400,
                ).copyWith(color: fg),
              ),
              if (widget.count != null) ...[
                const SizedBox(width: 6),
                Opacity(
                  opacity: 0.7,
                  child: Text(
                    widget.count!.toString(),
                    style: YaText.sans(size: 11, height: 14).copyWith(color: fg),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _hoveredAccent(YaColors c, StatusVariant v) => switch (v) {
        StatusVariant.brand => c.brandSubtleHover,
        // Para outras variantes, brand-subtle-hover não tem equivalente
        // semântico — escurecemos ligeiramente o subtle base.
        StatusVariant.success => Color.alphaBlend(
            c.success.withValues(alpha: 0.08), c.successSubtle,),
        StatusVariant.warning => Color.alphaBlend(
            c.warning.withValues(alpha: 0.08), c.warningSubtle,),
        StatusVariant.danger => Color.alphaBlend(
            c.danger.withValues(alpha: 0.08), c.dangerSubtle,),
        StatusVariant.info =>
          Color.alphaBlend(c.info.withValues(alpha: 0.08), c.infoSubtle),
        StatusVariant.neutral => Color.alphaBlend(
            c.neutral.withValues(alpha: 0.08), c.neutralSubtle,),
      };

  Color _accentBorder(YaColors c, StatusVariant v) => switch (v) {
        StatusVariant.brand => c.brandBorder,
        StatusVariant.success => c.successBorder,
        StatusVariant.warning => c.warningBorder,
        StatusVariant.danger => c.dangerBorder,
        StatusVariant.info => c.infoBorder,
        StatusVariant.neutral => c.neutralBorder,
      };
}
