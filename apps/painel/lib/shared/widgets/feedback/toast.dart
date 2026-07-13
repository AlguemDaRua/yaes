// Tradução fiel de _design/showcases/auxiliaries.jsx (componente Toast).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/status_mapping.dart';
import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Toast com border-left semântica de 3px, ícone e título + descrição opcional.
///
/// Exibido top-right. O dispatcher (overlay/portal) é responsabilidade do
/// chamador — este widget é apenas a apresentação visual.
class YaToast extends StatefulWidget {
  const YaToast({
    required this.title,
    required this.variant,
    this.description,
    this.dismissable = true,
    this.onDismiss,
    this.autoDismiss = true,
    super.key,
  });

  final String title;
  final String? description;
  final StatusVariant variant;
  final bool dismissable;
  final VoidCallback? onDismiss;

  /// Se true (default), o toast dispara [onDismiss] automaticamente depois
  /// do tempo padrao: success = 4 s, info = 5 s. Outros variants nao tem timer.
  final bool autoDismiss;

  @override
  State<YaToast> createState() => _YaToastState();
}

class _YaToastState extends State<YaToast> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoDismiss && widget.onDismiss != null) {
      final delay = _defaultDelay(widget.variant);
      if (delay != null) {
        _timer = Timer(delay, widget.onDismiss!);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration? _defaultDelay(StatusVariant v) => switch (v) {
        StatusVariant.success => const Duration(seconds: 4),
        StatusVariant.info => const Duration(seconds: 5),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final accent = widget.variant.resolve(colors).text;
    final isLightShadow = Theme.of(context).brightness == Brightness.light;

    return Container(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: YaRadius.brMd,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: isLightShadow ? YaShadows.md : YaShadows.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(width: 3, color: accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: YaSpacing.lg,
                vertical: YaSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      _iconFor(widget.variant),
                      size: 16,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: YaText.smMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        if (widget.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.description!,
                            style: YaText.sans(size: 12, height: 16)
                                .copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.dismissable) ...[
                    const SizedBox(width: YaSpacing.sm),
                    _DismissButton(onTap: widget.onDismiss),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(StatusVariant v) => switch (v) {
        StatusVariant.success => LucideIcons.check,
        StatusVariant.info => LucideIcons.clock,
        StatusVariant.warning => LucideIcons.triangleAlert,
        StatusVariant.danger => LucideIcons.triangleAlert,
        StatusVariant.neutral => LucideIcons.info,
        StatusVariant.brand => LucideIcons.sparkles,
      };
}

class _DismissButton extends StatefulWidget {
  const _DismissButton({this.onTap});
  final VoidCallback? onTap;

  @override
  State<_DismissButton> createState() => _DismissButtonState();
}

class _DismissButtonState extends State<_DismissButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Icon(
          LucideIcons.x,
          size: 14,
          color: _hovering ? colors.textSecondary : colors.textMuted,
        ),
      ),
    );
  }
}
