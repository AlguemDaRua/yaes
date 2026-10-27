import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';

enum MobileWalletMethod {
  mpesa('mpesa', 'M-Pesa', AssetPaths.mpesa, Color(0xFFDF2027)),
  emola('emola', 'E-Mola', AssetPaths.emola, Color(0xFFF28200));

  const MobileWalletMethod(this.key, this.label, this.imageAsset, this.color);

  final String key;
  final String label;
  final String imageAsset;
  final Color color;
}

Future<bool?> showMobileWalletNumberModal(
  BuildContext context, {
  required MobileWalletMethod method,
  String? initialNumber,
  required Future<void> Function(String number) onSave,
}) {
  final inheritedTheme = Theme.of(context);
  final colors = inheritedTheme.colorScheme.copyWith(
    primary: const Color(0xFFE5A400),
    onPrimary: const Color(0xFF24262B),
    surface: Colors.white,
    onSurface: const Color(0xFF24262B),
    onSurfaceVariant: const Color(0xFF62666D),
    outline: const Color(0xFFB9BDC4),
    outlineVariant: const Color(0xFFE6E8EC),
    error: const Color(0xFFB3261E),
  );

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // An explicit cancel action prevents accidental dismissal while saving.
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => Theme(
      data: inheritedTheme.copyWith(
        colorScheme: colors,
        textTheme: GoogleFonts.poppinsTextTheme(inheritedTheme.textTheme),
      ),
      child: _MobileWalletNumberSheet(
        method: method,
        initialNumber: initialNumber,
        onSave: onSave,
      ),
    ),
  );
}

class _MobileWalletNumberSheet extends StatefulWidget {
  const _MobileWalletNumberSheet({
    required this.method,
    required this.initialNumber,
    required this.onSave,
  });

  final MobileWalletMethod method;
  final String? initialNumber;
  final Future<void> Function(String number) onSave;

  @override
  State<_MobileWalletNumberSheet> createState() =>
      _MobileWalletNumberSheetState();
}

class _MobileWalletNumberSheetState extends State<_MobileWalletNumberSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  bool _saving = false;
  bool _attemptedSave = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: _formatLocalNumber(_localDigits(widget.initialNumber ?? '')),
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _attemptedSave = true;
      _saveError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final number = '+258${_localDigits(_numberController.text)}';
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.onSave(number).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            'Não foi possível guardar. Verifica a ligação e tenta novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final editing = widget.initialNumber?.trim().isNotEmpty == true;

    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Form(
                key: _formKey,
                autovalidateMode: _attemptedSave
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.method.color.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Image.asset(
                            widget.method.imageAsset,
                            excludeFromSemantics: true,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${editing ? 'Editar' : 'Adicionar'} ${widget.method.label}',
                            style: text.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Fechar',
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: colors.onSurfaceVariant,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Indica o número associado à tua conta ${widget.method.label}.',
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Número de telemóvel',
                      style: text.labelLarge?.copyWith(
                        color: colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Número de telemóvel ${widget.method.label}',
                      child: TextFormField(
                        controller: _numberController,
                        enabled: !_saving,
                        autofocus: true,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [
                          AutofillHints.telephoneNumberNational,
                        ],
                        inputFormatters: [_MobileNumberFormatter()],
                        onFieldSubmitted: (_) => _save(),
                        onChanged: (_) {
                          if (_saveError != null) {
                            setState(() => _saveError = null);
                          }
                        },
                        style: text.bodyLarge?.copyWith(
                          color: colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.method == MobileWalletMethod.mpesa
                              ? '84 123 4567'
                              : '86 123 4567',
                          hintStyle: text.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 16,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '+258',
                                  style: text.bodyLarge?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: colors.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: colors.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: colors.primary,
                              width: 1.5,
                            ),
                          ),
                          errorMaxLines: 3,
                        ),
                        validator: (value) =>
                            _localDigits(value ?? '').length == 9
                            ? null
                            : 'Introduz os 9 dígitos do número de telemóvel.',
                      ),
                    ),
                    if (_saveError != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _saveError!,
                          style: text.bodySmall?.copyWith(
                            color: colors.error,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        disabledBackgroundColor: colors.primary.withValues(
                          alpha: 0.55,
                        ),
                        disabledForegroundColor: colors.onPrimary,
                        minimumSize: const Size.fromHeight(52),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: text.labelLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _saving
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text('A guardar…'),
                              ],
                            )
                          : const Text('Guardar número'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.onSurfaceVariant,
                        minimumSize: const Size.fromHeight(48),
                        textStyle: text.labelLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _localDigits(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00258')) return digits.substring(5);
  if (digits.startsWith('258') && digits.length > 9) return digits.substring(3);
  return digits;
}

String _formatLocalNumber(String digits) {
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index == 2 || index == 5) buffer.write(' ');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

class _MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final allDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final localDigits = _localDigits(newValue.text);
    final removedPrefixLength = allDigits.length - localDigits.length;
    final selectionEnd = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final digitsBeforeCursor = newValue.text
        .substring(0, selectionEnd)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    final cursor = (digitsBeforeCursor - removedPrefixLength).clamp(
      0,
      localDigits.length,
    );
    final formatted = _formatLocalNumber(localDigits);
    final offset = cursor + (cursor > 2 ? 1 : 0) + (cursor > 5 ? 1 : 0);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, formatted.length),
      ),
    );
  }
}
