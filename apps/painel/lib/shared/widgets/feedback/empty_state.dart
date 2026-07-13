// Tradução fiel de _design/showcases/empty-skeleton.jsx (componente EmptyState).

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';
import '../forms/ya_button.dart';

/// Estado vazio com ícone, título, descrição e CTA opcional.
///
/// Centrado horizontalmente, max-width 400. Usa-se em listas/tabelas sem
/// resultados, dashboards sem dados, ou erros de carregamento.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCta,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final showCta = ctaLabel != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 48,
            horizontal: YaSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colors.bgSubtle,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.85,
                  child: Icon(icon, size: 40, color: colors.textMuted),
                ),
              ),
              const SizedBox(height: YaSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: YaText.mdMedium.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: YaSpacing.sm),
              Text(
                description,
                textAlign: TextAlign.center,
                // JSX: lineHeight 1.5 → 13 * 1.5 = 19.5
                style: YaText.sans(size: 13, height: 19.5)
                    .copyWith(color: colors.textSecondary),
              ),
              if (showCta) ...[
                const SizedBox(height: YaSpacing.xl),
                YaButton.primary(label: ctaLabel!, onPressed: onCta),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
