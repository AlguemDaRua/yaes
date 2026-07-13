// Tradução fiel de _design/showcases/forms-and-controls.jsx (componente Field).
// Wrapper label + child + hint, usado quando o campo não é um YaInput
// (ex: textarea, dropdown custom, file picker).

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/typography.dart';

/// Wrapper de campo de formulário: label em cima, hint em baixo.
class YaField extends StatelessWidget {
  const YaField({
    required this.label,
    required this.child,
    this.hint,
    this.errorText,
    super.key,
  });

  final String label;
  final Widget child;
  final String? hint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: YaText.sans(size: 12, height: 16, weight: FontWeight.w500)
              .copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 6),
        child,
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: YaText.sans(size: 12, height: 16)
                .copyWith(color: colors.danger),
          ),
        ] else if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            style: YaText.sans(size: 12, height: 16)
                .copyWith(color: colors.textMuted),
          ),
        ],
      ],
    );
  }
}
