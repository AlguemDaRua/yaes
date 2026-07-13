// Tradução fiel de _design/showcases/auxiliaries.jsx (componente Button + Spinner).

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

enum YaButtonVariant { primary, secondary, ghost, destructive, link }

enum YaButtonSize { sm, md, lg }

/// Botão YA — 5 variantes × 3 tamanhos × estados (hover/focus/pressed/disabled/loading).
///
/// Detecta hover, focus e pressed automaticamente via [MouseRegion],
/// [Focus] e [GestureDetector]. Loading desactiva o press e mostra spinner.
class YaButton extends StatefulWidget {
  const YaButton({
    required this.label,
    this.onPressed,
    this.variant = YaButtonVariant.secondary,
    this.size = YaButtonSize.md,
    this.icon,
    this.loading = false,
    super.key,
  });

  const factory YaButton.primary({
    required String label,
    VoidCallback? onPressed,
    YaButtonSize size,
    IconData? icon,
    bool loading,
    Key? key,
  }) = _Primary;

  const factory YaButton.secondary({
    required String label,
    VoidCallback? onPressed,
    YaButtonSize size,
    IconData? icon,
    bool loading,
    Key? key,
  }) = _Secondary;

  const factory YaButton.ghost({
    required String label,
    VoidCallback? onPressed,
    YaButtonSize size,
    IconData? icon,
    bool loading,
    Key? key,
  }) = _Ghost;

  const factory YaButton.destructive({
    required String label,
    VoidCallback? onPressed,
    YaButtonSize size,
    IconData? icon,
    bool loading,
    Key? key,
  }) = _Destructive;

  const factory YaButton.link({
    required String label,
    VoidCallback? onPressed,
    YaButtonSize size,
    IconData? icon,
    Key? key,
  }) = _Link;

  final String label;
  final VoidCallback? onPressed;
  final YaButtonVariant variant;
  final YaButtonSize size;
  final IconData? icon;
  final bool loading;

  @override
  State<YaButton> createState() => _YaButtonState();
}

class _Primary extends YaButton {
  const _Primary({
    required super.label,
    super.onPressed,
    super.size = YaButtonSize.md,
    super.icon,
    super.loading = false,
    super.key,
  }) : super(variant: YaButtonVariant.primary);
}

class _Secondary extends YaButton {
  const _Secondary({
    required super.label,
    super.onPressed,
    super.size = YaButtonSize.md,
    super.icon,
    super.loading = false,
    super.key,
  }) : super(variant: YaButtonVariant.secondary);
}

class _Ghost extends YaButton {
  const _Ghost({
    required super.label,
    super.onPressed,
    super.size = YaButtonSize.md,
    super.icon,
    super.loading = false,
    super.key,
  }) : super(variant: YaButtonVariant.ghost);
}

class _Destructive extends YaButton {
  const _Destructive({
    required super.label,
    super.onPressed,
    super.size = YaButtonSize.md,
    super.icon,
    super.loading = false,
    super.key,
  }) : super(variant: YaButtonVariant.destructive);
}

class _Link extends YaButton {
  const _Link({
    required super.label,
    super.onPressed,
    super.size = YaButtonSize.md,
    super.icon,
    super.key,
  }) : super(variant: YaButtonVariant.link, loading: false);
}

class _YaButtonState extends State<YaButton> {
  bool _hovering = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final dims = _dimensionsFor(widget.size);
    final palette = _palette(colors);

    final showIcon = widget.icon != null && !widget.loading;
    final showSpinner = widget.loading;

    final isLink = widget.variant == YaButtonVariant.link;
    final underline = isLink && _hovering;

    return Focus(
      canRequestFocus: _enabled,
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor:
            _enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTap: _enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: YaDurations.micro,
            curve: YaDurations.easeOut,
            height: dims.height,
            padding: EdgeInsets.symmetric(horizontal: dims.paddingH),
            decoration: BoxDecoration(
              color: palette.bg,
              borderRadius: YaRadius.brMd,
              border: palette.border,
              boxShadow: _focused
                  ? (widget.variant == YaButtonVariant.destructive
                      ? YaShadows.focusDanger
                      : YaShadows.focusBrand)
                  : YaShadows.none,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bounded = constraints.maxWidth.isFinite;
                final label = Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: YaText.sans(
                    size: dims.fontSize,
                    height: dims.fontSize * 1.2,
                    weight: FontWeight.w500,
                  ).copyWith(
                    color: palette.fg,
                    decoration: underline
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: palette.fg,
                  ),
                );

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showSpinner) ...[
                      _Spinner(size: 14, color: palette.fg),
                      SizedBox(width: dims.gap),
                    ] else if (showIcon) ...[
                      Icon(widget.icon, size: 14, color: palette.fg),
                      SizedBox(width: dims.gap),
                    ],
                    bounded ? Flexible(child: label) : label,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  _ButtonPalette _palette(YaColors c) {
    if (!_enabled && !widget.loading) {
      // disabled puro (sem onPressed)
      return _ButtonPalette(
        bg: c.bgSubtle,
        fg: c.textDisabled,
        border: Border.all(color: c.borderSubtle),
      );
    }

    switch (widget.variant) {
      case YaButtonVariant.primary:
        return _ButtonPalette(
          bg: _pressed ? c.brandActive : (_hovering ? c.brandHover : c.brand),
          fg: c.textInverse,
          border: null,
        );
      case YaButtonVariant.secondary:
        return _ButtonPalette(
          bg: _pressed
              ? c.bgElevated
              : (_hovering ? c.bgSubtle : Colors.transparent),
          fg: c.textPrimary,
          border: Border.all(color: c.borderDefault),
        );
      case YaButtonVariant.ghost:
        return _ButtonPalette(
          bg: _pressed
              ? c.bgElevated
              : (_hovering ? c.bgSubtle : Colors.transparent),
          fg: _hovering ? c.textPrimary : c.textSecondary,
          border: null,
        );
      case YaButtonVariant.destructive:
        // JSX usa #B91C1C no hover (red-700 do tailwind). Aproximação: danger.
        return _ButtonPalette(
          bg: _pressed || _hovering ? const Color(0xFFB91C1C) : c.danger,
          fg: c.textInverse,
          border: null,
        );
      case YaButtonVariant.link:
        return _ButtonPalette(
          bg: Colors.transparent,
          fg: _hovering ? c.brandHover : c.brand,
          border: null,
        );
    }
  }

  _ButtonDimensions _dimensionsFor(YaButtonSize s) => switch (s) {
        YaButtonSize.sm => const _ButtonDimensions(
            height: YaDimensions.buttonHeightSm,
            paddingH: 12,
            gap: 6,
            fontSize: 12,
          ),
        YaButtonSize.md => const _ButtonDimensions(
            height: YaDimensions.buttonHeightMd,
            paddingH: 16,
            gap: 8,
            fontSize: 13,
          ),
        YaButtonSize.lg => const _ButtonDimensions(
            height: YaDimensions.buttonHeightLg,
            paddingH: 20,
            gap: 8,
            fontSize: 14,
          ),
      };
}

class _ButtonDimensions {
  const _ButtonDimensions({
    required this.height,
    required this.paddingH,
    required this.gap,
    required this.fontSize,
  });
  final double height;
  final double paddingH;
  final double gap;
  final double fontSize;
}

class _ButtonPalette {
  const _ButtonPalette({
    required this.bg,
    required this.fg,
    required this.border,
  });
  final Color bg;
  final Color fg;
  final BoxBorder? border;
}

/// Spinner circular: anel 2px com topo transparente, rotação infinita 0.7s.
class _Spinner extends StatefulWidget {
  const _Spinner({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RotationTransition(
        turns: _controller,
        child: CustomPaint(
          painter: _SpinnerPainter(color: widget.color),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    // Arco de ~270° (3/4) — o resto fica "transparente" como o JSX faz com
    // borderTopColor: transparent.
    canvas.drawArc(rect, -1.5, 4.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter old) => old.color != color;
}
