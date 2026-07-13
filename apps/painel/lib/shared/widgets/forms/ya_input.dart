// Tradução fiel de _design/showcases/auxiliaries.jsx (componente Input).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

enum YaInputSize { md, lg }

/// Campo de texto YA com label, hint, error e ícone à esquerda.
///
/// Estados são detectados automaticamente (hover, focus). Erro tem prioridade
/// sobre hint. Disabled mostra fundo `bg-subtle`.
class YaInput extends StatefulWidget {
  const YaInput({
    this.controller,
    this.label,
    this.placeholder,
    this.hint,
    this.errorText,
    this.icon,
    this.size = YaInputSize.md,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? hint;
  final String? errorText;
  final IconData? icon;
  final YaInputSize size;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<YaInput> createState() => _YaInputState();
}

class _YaInputState extends State<YaInput> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChange);
  bool _hovering = false;
  bool _focused = false;

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final hasError = widget.errorText != null;
    final height = widget.size == YaInputSize.lg
        ? YaDimensions.inputHeightLarge
        : YaDimensions.inputHeight;

    final Color borderColor;
    if (!widget.enabled) {
      borderColor = colors.borderSubtle;
    } else if (hasError) {
      borderColor = colors.danger;
    } else if (_focused) {
      borderColor = colors.brandBorder;
    } else if (_hovering) {
      borderColor = colors.borderDefault;
    } else {
      borderColor = colors.borderSubtle;
    }

    final List<BoxShadow> shadow;
    shadow = YaShadows.none;

    final bg = widget.enabled ? colors.bgSurface : colors.bgSubtle;
    final textColor = widget.enabled ? colors.textPrimary : colors.textDisabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: YaText.sans(size: 12, height: 16, weight: FontWeight.w500)
                .copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
        ],
        MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.text
              : SystemMouseCursors.forbidden,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedContainer(
            duration: YaDurations.micro,
            curve: YaDurations.easeOut,
            height: height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: YaRadius.brMd,
              border: Border.all(color: borderColor),
              boxShadow: shadow,
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  const SizedBox(width: 10),
                  Icon(widget.icon, size: 14, color: colors.textMuted),
                ],
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: widget.icon != null ? 8 : 12,
                      right: 12,
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      autofocus: widget.autofocus,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      cursorColor: colors.brand,
                      style: YaText.sm.copyWith(color: textColor),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hintText: widget.placeholder,
                        hintStyle: YaText.sm.copyWith(color: colors.textMuted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(LucideIcons.triangleAlert, size: 12, color: colors.danger),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.errorText!,
                  style: YaText.sans(size: 12, height: 16)
                      .copyWith(color: colors.danger),
                ),
              ),
            ],
          ),
        ] else if (widget.hint != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.hint!,
            style: YaText.sans(size: 12, height: 16)
                .copyWith(color: colors.textMuted),
          ),
        ],
      ],
    );
  }
}
