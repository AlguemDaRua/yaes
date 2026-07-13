// Tradução fiel de _design/showcases/status-badge.jsx (StatusBadge primitivo
// definido em _design/ya-primitives.jsx).
// Pill de estado semântico. Spec em _design/components.md §8.

import 'package:flutter/material.dart';

import '../../../core/constants/status_mapping.dart';
import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Badge de estado: pill com dot ou ícone + label.
///
/// Ícone tem prioridade sobre dot (mutuamente exclusivos). Label deve estar
/// em sentence case ("Activo", não "ACTIVO").
///
/// Para usar com mapeamentos canónicos do domínio:
/// `StatusBadge.fromMapping(YaStatus.partnerActive)`.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.variant,
    required this.label,
    this.dot = true,
    this.icon,
    this.size = StatusBadgeSize.md,
    super.key,
  });

  /// Conveniência: cria badge a partir de um [StatusMapping] canónico.
  factory StatusBadge.fromMapping(
    StatusMapping mapping, {
    bool dot = true,
    IconData? icon,
    StatusBadgeSize size = StatusBadgeSize.md,
  }) {
    return StatusBadge(
      variant: mapping.variant,
      label: mapping.label,
      dot: dot,
      icon: icon,
      size: size,
    );
  }

  final StatusVariant variant;
  final String label;

  /// Mostrar dot indicador (default true). Ignorado se [icon] fornecido.
  final bool dot;
  final IconData? icon;
  final StatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final palette = variant.resolve(colors);

    // JSX: h = sm? 18 : 22; fs = sm? 10 : 11; padding sm='0 8px', md='2px 10px'.
    // dot, icon e gap são iguais em ambos os tamanhos no JSX.
    final dimensions = switch (size) {
      StatusBadgeSize.sm => const _BadgeDimensions(
          height: 18,
          paddingH: 8,
          fontSize: 10,
        ),
      StatusBadgeSize.md => const _BadgeDimensions(
          height: 22,
          paddingH: 10,
          fontSize: 11,
        ),
    };

    return Semantics(
      label: 'Estado: $label',
      child: Container(
        height: dimensions.height,
        padding: EdgeInsets.symmetric(horizontal: dimensions.paddingH),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: YaRadius.brFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: palette.text),
              const SizedBox(width: 5),
            ] else if (dot) ...[
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.text,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                style: YaText.sans(
                  size: dimensions.fontSize,
                  height: dimensions.fontSize, // lineHeight: 1 no JSX
                  weight: FontWeight.w500,
                ).copyWith(color: palette.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum StatusBadgeSize { sm, md }

class _BadgeDimensions {
  const _BadgeDimensions({
    required this.height,
    required this.paddingH,
    required this.fontSize,
  });
  final double height;
  final double paddingH;
  final double fontSize;
}
