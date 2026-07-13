import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:provider/provider.dart';
import '../utils/secure_storage.dart';

class PhoneNumberPage extends StatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  State<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {
  bool _isPhoneValid = false;
  bool _isLoading = false;
  late TextEditingController _phoneController;
  String _fullPhoneNumber = ''; // inclui código do país ex: +25884xxxxxxx

  final List<String> _validPrefixes = ['82', '83', '84', '85', '86', '87'];
  String? _errorText;



  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_isPhoneValid || _isLoading) return;

    setState(() => _isLoading = true);

    // Save number locally to show on OTP page
    await Preferences.saveNumber(_fullPhoneNumber);
    if (!mounted) return;

    final authRepository = Provider.of<IAuthRepository>(context, listen: false);

    await authRepository.sendSmsCode(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pushNamed(
          context,
          '/otp_verification',
          arguments: {
            'verificationId': verificationId,
            'telefone': _fullPhoneNumber,
          },
        );
      },
      onFailed: (erro) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $erro'), backgroundColor: Colors.red),
        );
      },
    );
  }

  Widget _button() {
    return GestureDetector(
      onTap: _continue,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isLoading ? Colors.amber.withValues(alpha: 0.5) : Colors.amber,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Continuar',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _phoneNumberField() {
    return IntlPhoneField(
      controller: _phoneController,
      decoration: InputDecoration(
        hintText: '00 000 000',
        errorText: _errorText,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.grey, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: _phoneController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _phoneController.clear();
                    _errorText = null;
                    _isPhoneValid = false;
                  });
                },
              )
            : null,
      ),
      initialCountryCode: 'MZ',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onChanged: (phone) {
        _fullPhoneNumber = phone.completeNumber; // ex: +25884xxxxxxx

        final digitsOnly = phone.number.replaceAll(RegExp(r'[^0-9]'), '');

        bool hasValidPrefix =
            digitsOnly.length >= 2 &&
            _validPrefixes.contains(digitsOnly.substring(0, 2));
        bool isNineDigits = digitsOnly.length == 9;
        bool isValid = hasValidPrefix && isNineDigits;

        setState(() {
          _isPhoneValid = isValid;
          if (digitsOnly.isEmpty) {
            _errorText = null;
          } else if (!hasValidPrefix) {
            _errorText = 'O número deve começar com 82-87';
          } else if (!isNineDigits) {
            _errorText = 'O número deve ter 9 dígitos';
          } else {
            _errorText = null;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 246, 246),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 249, 246, 246),
        automaticallyImplyLeading: false,
        title: Hero(
          tag: "logo",
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                'YA!',
                style: TextStyle(
                  color: const Color(0xffdcb311),
                  fontSize: 50.sp,
                  fontFamily: 'Gagalin',
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.sp),
            Text(
              'INTRODUZA O TEU NÚMERO DE TELEFONE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
                fontFamily: 'Gagalin',
              ),
            ),
            SizedBox(height: 10.sp),
            const Center(
              child: Text(
                'Vamos enviar um código de confirmação para este número.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            SizedBox(height: 30.sp),
            _phoneNumberField(),
            const Spacer(),
            Visibility(visible: _isPhoneValid, child: _button()),
            SizedBox(height: 10.sp),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Ao continuar, concordas com os nossos Termos de Serviço e Política de Privacidade.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
