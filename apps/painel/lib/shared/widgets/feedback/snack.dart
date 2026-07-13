import 'package:flutter/material.dart';

import '../../../core/constants/status_mapping.dart';
import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/typography.dart';

/// One-call floating snack used across the panel (admin/support).
/// Mirrors the partner/support area toasts but lives in shared so any area can
/// surface success/error feedback without importing another area's code.
void yaSnack(
  BuildContext context,
  String message, {
  StatusVariant variant = StatusVariant.success,
}) {
  final YaColors colors = YaColors.of(context);
  final ({Color bg, Color fg}) palette = switch (variant) {
    StatusVariant.danger => (bg: colors.dangerSubtle, fg: colors.danger),
    StatusVariant.warning => (bg: colors.warningSubtle, fg: colors.warning),
    StatusVariant.info => (bg: colors.infoSubtle, fg: colors.info),
    StatusVariant.success => (bg: colors.successSubtle, fg: colors.success),
    _ => (bg: colors.bgElevated, fg: colors.textPrimary),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content:
            Text(message, style: YaText.smMedium.copyWith(color: palette.fg)),
        backgroundColor: palette.bg,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
}
