// Tradução fiel de _design/showcases/forms-and-controls.jsx (componente FormDialog).
// Spec: _design/components.md §9.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';
import '../forms/ya_button.dart';

/// Dialog modal centrado para criação/edição.
///
/// Layout: Header (title + description + close) → ErrorBanner? → Body (slot
/// scrollable com fields) → Footer (Cancel + Confirm).
///
/// Mostrar via `showDialog(context, builder: (_) => FormDialog(...))`.
class FormDialog extends StatefulWidget {
  const FormDialog({
    required this.title,
    required this.children,
    required this.onConfirm,
    this.description,
    this.onCancel,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.destructive = false,
    this.submitting = false,
    this.confirmDisabled = false,
    this.errorBanner,
    this.maxWidth = 480,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final bool submitting;
  final bool confirmDisabled;
  final String? errorBanner;
  final double maxWidth;

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..forward();

  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: FadeTransition(
          opacity: _curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(_curved),
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
                  _buildHeader(context, colors),
                  if (widget.errorBanner != null) _buildErrorBanner(colors),
                  Flexible(child: _buildBody()),
                  _buildFooter(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismiss(BuildContext context) {
    final onCancel = widget.onCancel;
    if (onCancel != null) {
      onCancel();
      return;
    }

    Navigator.of(context).pop();
  }

  Widget _buildHeader(BuildContext context, YaColors colors) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: YaText.lg.copyWith(color: colors.textPrimary),
                ),
                if (widget.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.description!,
                    style: YaText.sm.copyWith(color: colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          _CloseButton(onTap: () => _dismiss(context)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(YaColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        YaSpacing.xxl,
        YaSpacing.lg,
        YaSpacing.xxl,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.dangerSubtle,
        borderRadius: YaRadius.brMd,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.triangleAlert, size: 14, color: colors.danger),
          const SizedBox(width: YaSpacing.sm),
          Expanded(
            child: Text(
              widget.errorBanner!,
              style: YaText.sans(size: 12, height: 16)
                  .copyWith(color: colors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(YaSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.children.length; i++) ...[
            widget.children[i],
            if (i < widget.children.length - 1)
              const SizedBox(height: YaSpacing.lg),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(YaColors colors) {
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
          Builder(
            builder: (context) {
              return YaButton.secondary(
                label: widget.cancelLabel,
                onPressed: widget.submitting ? null : () => _dismiss(context),
              );
            },
          ),
          const SizedBox(width: YaSpacing.sm),
          if (widget.destructive)
            YaButton.destructive(
              label: widget.submitting ? 'A guardar...' : widget.confirmLabel,
              loading: widget.submitting,
              onPressed: widget.confirmDisabled || widget.submitting
                  ? null
                  : widget.onConfirm,
            )
          else
            YaButton.primary(
              label: widget.submitting ? 'A guardar...' : widget.confirmLabel,
              loading: widget.submitting,
              onPressed: widget.confirmDisabled || widget.submitting
                  ? null
                  : widget.onConfirm,
            ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
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
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovering ? colors.bgSubtle : Colors.transparent,
            borderRadius: YaRadius.brXs,
          ),
          child: Icon(
            LucideIcons.x,
            size: 16,
            color: _hovering ? colors.textPrimary : colors.textMuted,
          ),
        ),
      ),
    );
  }
}
