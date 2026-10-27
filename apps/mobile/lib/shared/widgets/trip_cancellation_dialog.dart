import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The callback must finish persisting the cancellation before the dialog closes.
Future<bool?> showTripCancellationDialog(
  BuildContext context, {
  required Future<void> Function(String reason) onConfirm,
  bool driverTheme = false,
  bool interrupting = false,
}) {
  final theme = Theme.of(context);
  final colors =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFE5A400),
        brightness: driverTheme ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: driverTheme
            ? const Color(0xFFFFD740)
            : const Color(0xFFE5A400),
        onPrimary: const Color(0xFF202124),
        surface: driverTheme ? const Color(0xFF202124) : Colors.white,
      );
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Theme(
      data: theme.copyWith(
        colorScheme: colors,
        textTheme: GoogleFonts.poppinsTextTheme(
          theme.textTheme,
        ).apply(bodyColor: colors.onSurface, displayColor: colors.onSurface),
      ),
      child: _TripCancellationDialog(
        onConfirm: onConfirm,
        interrupting: interrupting,
      ),
    ),
  );
}

class _TripCancellationDialog extends StatefulWidget {
  const _TripCancellationDialog({
    required this.onConfirm,
    required this.interrupting,
  });

  final Future<void> Function(String reason) onConfirm;
  final bool interrupting;

  @override
  State<_TripCancellationDialog> createState() =>
      _TripCancellationDialogState();
}

class _TripCancellationDialogState extends State<_TripCancellationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onConfirm(_reasonController.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'Não foi possível confirmar o cancelamento. Verifica a ligação '
            'e o estado da viagem antes de tentar novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.onErrorContainer,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.interrupting
                        ? 'Interromper esta viagem?'
                        : 'Cancelar esta viagem?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Indica o motivo para confirmar. O motivo ficará '
                    'registado na viagem.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _reasonController,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Motivo do cancelamento',
                      hintText: 'Explica o que aconteceu…',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: colors.onSurface.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) {
                      final reason = value?.trim() ?? '';
                      if (reason.isEmpty) {
                        return 'Introduz o motivo para continuar.';
                      }
                      if (reason.length > 500) return 'Usa até 500 caracteres.';
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _confirm,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: 'A guardar o cancelamento',
                            ),
                          )
                        : Text(
                            widget.interrupting
                                ? 'Confirmar interrupção'
                                : 'Confirmar cancelamento',
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Continuar viagem'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
