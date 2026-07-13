// Tradução fiel de _design/showcases/forms-and-controls.jsx (componente
// ConfirmDialog destrutivo).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/status_mapping.dart';
import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';
import '../forms/ya_button.dart';

/// Dialog de confirmação com ícone semântico, title + description.
///
/// Body é opcional (usado quando precisas de campo adicional como motivo
/// de suspensão). Variante `destructive` deixa o confirm a vermelho.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.title,
    required this.description,
    this.body,
    this.icon = LucideIcons.triangleAlert,
    this.variant = StatusVariant.danger,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.confirmDisabled = false,
    this.submitting = false,
    this.onCancel,
    this.onConfirm,
    super.key,
  });

  final String title;
  final String description;
  final Widget? body;
  final IconData icon;
  final StatusVariant variant;
  final String confirmLabel;
  final String cancelLabel;
  final bool confirmDisabled;
  final bool submitting;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = variant.resolve(colors);
    final destructive = variant == StatusVariant.danger;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: YaRadius.brXl,
            border: Border.all(color: colors.borderSubtle),
            boxShadow: isLight ? YaShadows.lg : YaShadows.none,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(colors, accent),
              if (body != null)
                Padding(
                  padding: const EdgeInsets.all(YaSpacing.xxl),
                  child: body,
                ),
              _buildFooter(context, destructive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(YaColors colors, ({Color text, Color bg}) accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        YaSpacing.xxl,
        YaSpacing.xxl,
        YaSpacing.xxl,
        YaSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.bg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: accent.text),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: YaText.mdMedium.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  // JSX: lineHeight 1.5 → 13 * 1.5 = 19.5
                  style: YaText.sans(size: 13, height: 19.5)
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool destructive) {
    final colors = YaColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        YaSpacing.xxl,
        YaSpacing.lg,
        YaSpacing.xxl,
        YaSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          YaButton.secondary(
            label: cancelLabel,
            onPressed: submitting
                ? null
                : onCancel ?? () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: YaSpacing.sm),
          if (destructive)
            YaButton.destructive(
              label: submitting ? 'A processar...' : confirmLabel,
              loading: submitting,
              onPressed: confirmDisabled || submitting ? null : onConfirm,
            )
          else
            YaButton.primary(
              label: submitting ? 'A processar...' : confirmLabel,
              loading: submitting,
              onPressed: confirmDisabled || submitting ? null : onConfirm,
            ),
        ],
      ),
    );
  }
}
