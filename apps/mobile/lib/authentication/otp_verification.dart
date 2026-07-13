import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:provider/provider.dart';
import '../services/messaging_service.dart';
import '../utils/secure_storage.dart';

class OtpVerification extends StatefulWidget {
  const OtpVerification({super.key});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  bool _isLoading = false;
  String? _erro;



  // Received via Navigator arguments
  late String _verificationId;
  late String _telefone;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _verificationId = args?['verificationId'] ?? '';
    _telefone = args?['telefone'] ?? '';
  }

  Future<void> _verificar(String codigo) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    final authRepository = Provider.of<IAuthRepository>(context, listen: false);
    try {
      final uid = await authRepository.signInWithSmsCode(
        verificationId: _verificationId,
        smsCode: codigo,
      );

      if (uid == null || !mounted) return;

      // Save FCM token for push notifications
      await MessagingService.onLogin();

      // Check user type
      final userType = await authRepository.getUserType(uid);
      await Preferences.saveType(userType);

      if (!mounted) return;

      final rota = userType == 'driver'
          ? '/driver_home'
          : '/passenger_home';
      Navigator.pushNamedAndRemoveUntil(context, rota, (route) => false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _erro = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _reenviarCodigo() async {
    setState(() => _isLoading = true);
    final authRepository = Provider.of<IAuthRepository>(context, listen: false);
    await authRepository.sendSmsCode(
      phoneNumber: _telefone,
      onCodeSent: (newVerificationId, _) {
        if (!mounted) return;
        setState(() {
          _verificationId = newVerificationId;
          _isLoading = false;
          _erro = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Novo código enviado!')));
      },
      onFailed: (erro) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _erro = erro;
        });
      },

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 246, 246),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.sp),
            Text(
              'Digite o código de 6 dígitos',
              style: TextStyle(
                fontSize: 23.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gagalin',
                color: Colors.black,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Enviámos um código de 6 dígitos para',
              style: TextStyle(fontSize: 15.sp, color: Colors.grey[600]),
            ),
            Text(
              _telefone,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30.sp),

            // Validation error
            if (_erro != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_erro!, style: const TextStyle(color: Colors.red)),
              ),

            // Campo PIN
            PinCodeTextField(
              appContext: context,
              length: 6,
              enabled: !_isLoading,
              onChanged: (value) {},
              onCompleted: (value) => _verificar(value),
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.underline,
                fieldHeight: 55.sp,
                fieldWidth: 50.sp,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.grey.shade200,
                selectedFillColor: Colors.white,
                activeColor: Colors.blue,
                inactiveColor: Colors.grey,
                selectedColor: Colors.blue,
              ),
              enableActiveFill: true,
            ),

            SizedBox(height: 20.sp),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Não recebeste o código? ',
                    style: TextStyle(fontSize: 15.sp, color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: _reenviarCodigo,
                    child: Text(
                      'Reenviar código',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
