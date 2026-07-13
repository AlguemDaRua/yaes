// Tradução fiel de _design/showcases/forms-and-controls.jsx (textarea inline
// no ConfirmDialog). Multi-linha com border, error e focus ring.

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

/// Campo de texto multi-linha (resize vertical via [minLines]/[maxLines]).
///
/// Mesma decoração que [YaInput] (border, focus ring, error). Para campo
/// de uma só linha, usar [YaInput].
class YaTextarea extends StatefulWidget {
  const YaTextarea({
    this.controller,
    this.placeholder,
    this.errorText,
    this.minLines = 4,
    this.maxLines = 8,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final String? errorText;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<YaTextarea> createState() => _YaTextareaState();
}

class _YaTextareaState extends State<YaTextarea> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChange);
  bool _hovering = false;
  bool _focused = false;

  void _onFocusChange() => setState(() => _focused = _focusNode.hasFocus);

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

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: YaDurations.micro,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: YaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: widget.enabled ? colors.bgSurface : colors.bgSubtle,
          borderRadius: YaRadius.brMd,
          border: Border.all(color: borderColor),
          boxShadow: shadow,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          cursorColor: colors.brand,
          style: YaText.sm.copyWith(
            color: widget.enabled ? colors.textPrimary : colors.textDisabled,
          ),
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
    );
  }
}
