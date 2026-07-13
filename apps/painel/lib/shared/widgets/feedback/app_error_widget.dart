import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';
import '../forms/ya_button.dart';

/// Fallback visual para erros de build não tratados pela árvore normal.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({required this.details, super.key});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);

    return Material(
      color: colors.bgBase,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(YaSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.triangleAlert,
                  size: 48,
                  color: colors.danger,
                ),
                const SizedBox(height: YaSpacing.lg),
                Text(
                  'Ocorreu um erro inesperado',
                  style: YaText.lg.copyWith(color: colors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: YaSpacing.sm),
                  Text(
                    details.exceptionAsString(),
                    style: YaText.sm.copyWith(color: colors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: YaSpacing.xxl),
                YaButton.secondary(
                  label: 'Voltar',
                  icon: LucideIcons.arrowLeft,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
