import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/mobile_wallet_number_modal.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  static const _gold = Color(0xFFE5A400);
  static const _ink = Color(0xFF24262B);
  static const _muted = Color(0xFF62666D);
  bool _savingCard = false;

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final uid = authRepo.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Métodos de pagamento',
          style: GoogleFonts.poppins(
            color: _ink,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _ink),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: uid.isEmpty ? null : tripRepo.watchProfile(uid),
        builder: (context, snapshot) {
          if (uid.isEmpty) {
            return const _PaymentStateMessage(
              icon: Icons.person_outline_rounded,
              title: 'Inicia sessão',
              message: 'Entra na tua conta para gerir os métodos de pagamento.',
            );
          }
          if (snapshot.hasError) {
            return const _PaymentStateMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Não foi possível carregar',
              message: 'Verifica a ligação e tenta novamente.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _gold));
          }

          final methods = Map<dynamic, dynamic>.from(
            snapshot.data?['paymentMethods'] as Map? ?? const {},
          );
          final cards = _readCards(methods['cards']);

          return ListView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 28.h),
            children: [
              _sectionTitle(
                'Carteiras móveis',
                'Números associados aos pagamentos.',
              ),
              SizedBox(height: 12.h),
              for (final method in MobileWalletMethod.values) ...[
                _walletCard(
                  context,
                  tripRepo,
                  uid,
                  method,
                  methods[method.key]?.toString(),
                ),
                SizedBox(height: 12.h),
              ],
              SizedBox(height: 12.h),
              _sectionTitle(
                'Cartões bancários',
                'Pagamento por cartão ainda indisponível.',
              ),
              SizedBox(height: 12.h),
              if (cards.isEmpty) ...[
                _emptyCardsCard(),
                SizedBox(height: 12.h),
              ] else
                for (final entry in cards.entries) ...[
                  _savedCard(context, tripRepo, uid, entry.key, entry.value),
                  SizedBox(height: 12.h),
                ],
              _addCardButton(context, tripRepo, uid),
              SizedBox(height: 12.h),
              _securityNote(),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            color: _ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12.sp, color: _muted),
        ),
      ],
    );
  }

  Widget _walletCard(
    BuildContext context,
    ITripRepository tripRepo,
    String uid,
    MobileWalletMethod method,
    String? number,
  ) {
    final isConfigured = number?.isNotEmpty == true;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => _editNumber(context, tripRepo, uid, method, number),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE6E8EC)),
          ),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: method.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Image.asset(method.imageAsset, fit: BoxFit.contain),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: GoogleFonts.poppins(
                        color: _ink,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      isConfigured ? number! : 'Adicionar número',
                      style: GoogleFonts.poppins(
                        color: _muted,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                isConfigured ? Icons.edit_outlined : Icons.add_rounded,
                size: 20.sp,
                color: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCardsCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(Icons.credit_card_outlined, color: _muted),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Nenhum cartão adicionado',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedCard(
    BuildContext context,
    ITripRepository tripRepo,
    String uid,
    String cardId,
    Map<String, dynamic> card,
  ) {
    final digits = (card['last4']?.toString() ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    final last4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : '••••';
    final brand = card['brand']?.toString() ?? 'Cartão';
    final expiryMonth = card['expiryMonth']?.toString().padLeft(2, '0') ?? '';
    final expiryYear = card['expiryYear']?.toString() ?? '';
    final expiry = expiryMonth.isNotEmpty && expiryYear.isNotEmpty
        ? '$expiryMonth/${expiryYear.length > 2 ? expiryYear.substring(expiryYear.length - 2) : expiryYear}'
        : '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 42.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(Icons.credit_card_rounded, color: _ink),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand,
                  style: GoogleFonts.poppins(
                    color: _ink,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '•••• $last4',
                  semanticsLabel: 'Cartão terminado em $last4',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 14.sp,
                    color: _ink,
                  ),
                ),
                if (expiry.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    'Validade $expiry',
                    style: GoogleFonts.poppins(color: _muted, fontSize: 12.sp),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remover cartão terminado em $last4',
            onPressed: () => _removeCard(context, tripRepo, uid, cardId),
            icon: const Icon(Icons.delete_outline_rounded),
            color: _muted,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }

  Widget _addCardButton(
    BuildContext context,
    ITripRepository tripRepo,
    String uid,
  ) {
    return FilledButton.icon(
      onPressed: _savingCard ? null : () => _addCard(context, tripRepo, uid),
      icon: _savingCard
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
            )
          : const Icon(Icons.add_rounded),
      label: Text(
        _savingCard ? 'A guardar…' : 'Adicionar cartão',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
      style: FilledButton.styleFrom(
        foregroundColor: _ink,
        backgroundColor: _gold,
        minimumSize: Size.fromHeight(52.h.clamp(48.0, 60.0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }

  Widget _securityNote() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: _muted, size: 16.sp),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              'Apenas a marca, a validade e os últimos 4 dígitos ficam guardados.',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                height: 1.45,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, dynamic>> _readCards(dynamic value) {
    if (value is! Map) return {};
    return value.map((key, item) {
      final data = item is Map
          ? Map<String, dynamic>.from(item)
          : <String, dynamic>{};
      return MapEntry(key.toString(), data);
    });
  }

  Future<void> _addCard(
    BuildContext context,
    ITripRepository tripRepo,
    String uid,
  ) async {
    final details = await showModalBottomSheet<_CardMetadata>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCardSheet(),
    );
    if (details == null || !context.mounted) return;

    setState(() => _savingCard = true);
    final cardId = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      await tripRepo.updateProfile(uid, {
        'paymentMethods/cards/$cardId': {
          ...details.toJson(),
          'createdAt': DateTime.now().toIso8601String(),
        },
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cartão adicionado.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível guardar o cartão.')),
      );
    } finally {
      if (mounted) setState(() => _savingCard = false);
    }
  }

  Future<void> _removeCard(
    BuildContext context,
    ITripRepository tripRepo,
    String uid,
    String cardId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Remover cartão?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Este cartão será removido dos teus métodos de pagamento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await tripRepo.updateProfile(uid, {'paymentMethods/cards/$cardId': null});
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível remover o cartão.')),
      );
    }
  }

  Future<void> _editNumber(
    BuildContext context,
    ITripRepository tripRepo,
    String uid,
    MobileWalletMethod method,
    String? current,
  ) async {
    if (uid.isEmpty) return;
    final saved = await showMobileWalletNumberModal(
      context,
      method: method,
      initialNumber: current,
      onSave: (number) =>
          tripRepo.updateProfile(uid, {'paymentMethods/${method.key}': number}),
    );
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Número ${method.label} guardado.')));
  }
}

class _PaymentStateMessage extends StatelessWidget {
  const _PaymentStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(28.sp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42.sp, color: Colors.black38),
          SizedBox(height: 12.h),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          SizedBox(height: 6.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12.sp),
          ),
        ],
      ),
    ),
  );
}

class _CardMetadata {
  const _CardMetadata({
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
  });

  final String last4;
  final String brand;
  final int expiryMonth;
  final int expiryYear;

  Map<String, dynamic> toJson() => {
    'last4': last4,
    'brand': brand,
    'expiryMonth': expiryMonth,
    'expiryYear': expiryYear,
  };
}

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  static const _gold = Color(0xFFE5A400);
  static const _ink = Color(0xFF24262B);
  static const _muted = Color(0xFF62666D);

  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();

  String get _digits => _numberController.text.replaceAll(RegExp(r'\D'), '');

  String get _brand {
    final digits = _digits;
    if (digits.startsWith('4')) return 'Visa';
    if (digits.startsWith('34') || digits.startsWith('37')) {
      return 'American Express';
    }
    if (digits.startsWith('5') || digits.startsWith('2')) return 'Mastercard';
    return digits.isEmpty ? 'Cartão bancário' : 'Outro cartão';
  }

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20.w,
            12.h,
            20.w,
            20.h + MediaQuery.paddingOf(context).bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Adicionar cartão',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: _muted),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'O cartão ficará identificado pelos últimos 4 dígitos. O pagamento por cartão ainda está indisponível.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    height: 1.45,
                    color: _muted,
                  ),
                ),
                SizedBox(height: 24.h),
                _fieldLabel('Número do cartão'),
                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.creditCardNumber],
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  style: GoogleFonts.poppins(fontSize: 14.sp, color: _ink),
                  inputFormatters: [_CardNumberFormatter()],
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDecoration('0000 0000 0000 0000').copyWith(
                    suffixIcon: const Icon(
                      Icons.credit_card_outlined,
                      color: _muted,
                    ),
                    helperText: _digits.isEmpty ? null : _brand,
                    helperStyle: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: _muted,
                    ),
                  ),
                  validator: (_) => _isValidCardNumber(_digits)
                      ? null
                      : 'Verifica o número do cartão.',
                ),
                SizedBox(height: 14.h),
                _fieldLabel('Validade'),
                TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.creditCardExpirationDate],
                  style: GoogleFonts.poppins(fontSize: 14.sp, color: _ink),
                  inputFormatters: [_ExpiryFormatter()],
                  decoration: _inputDecoration('MM/AA'),
                  validator: (value) => _isValidExpiry(value ?? '')
                      ? null
                      : 'Introduz uma validade futura no formato MM/AA.',
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16.sp,
                      color: _muted,
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        'O número completo não fica guardado.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          height: 1.4,
                          color: _muted,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Adicionar cartão',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _ink,
                    minimumSize: Size.fromHeight(52.h.clamp(48.0, 60.0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Text(
      label,
      style: GoogleFonts.poppins(
        color: _ink,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(fontSize: 14.sp, color: _muted),
    filled: true,
    fillColor: const Color(0xFFF7F8FA),
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: Color(0xFFE4E4DE)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: Color(0xFFE4E4DE)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: _gold, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final expiryParts = _expiryController.text.split('/');
    final expiryMonth = int.parse(expiryParts[0]);
    final expiryYear = 2000 + int.parse(expiryParts[1]);
    final details = _CardMetadata(
      last4: _digits.substring(_digits.length - 4),
      brand: _brand,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
    );

    // Keep full card data only for the lifetime of this form; never persist it.
    _numberController.clear();
    _expiryController.clear();
    Navigator.of(context).pop(details);
  }

  bool _isValidExpiry(String value) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value);
    if (match == null) return false;
    final month = int.tryParse(match.group(1)!);
    final year = int.tryParse(match.group(2)!);
    if (month == null || year == null || month < 1 || month > 12) return false;
    final expiry = DateTime(2000 + year, month + 1, 0, 23, 59, 59);
    return !expiry.isBefore(DateTime.now());
  }

  bool _isValidCardNumber(String digits) {
    if (digits.length < 12 || digits.length > 19) return false;
    var sum = 0;
    var doubleDigit = false;
    for (var index = digits.length - 1; index >= 0; index--) {
      var digit = int.parse(digits[index]);
      if (doubleDigit) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubleDigit = !doubleDigit;
    }
    return sum % 10 == 0;
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 19 ? digits.substring(0, 19) : digits;
    final buffer = StringBuffer();
    for (var index = 0; index < limited.length; index++) {
      if (index > 0 && index % 4 == 0) buffer.write(' ');
      buffer.write(limited[index]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final text = limited.length > 2
        ? '${limited.substring(0, 2)}/${limited.substring(2)}'
        : limited;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
