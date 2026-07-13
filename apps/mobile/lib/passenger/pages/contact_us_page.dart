import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/services/support_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  static const _email = 'suporte@ya-app.co.mz';
  static const _phone = '+258 84 000 0000';

  Future<void> _send() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indique o assunto.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await SupportService.createTicket(subject: subject, text: message);
      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensagem enviada. A nossa equipa vai responder em breve.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Contacte-nos', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18.sp)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(24.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Icon(Icons.headset_mic_rounded, size: 60.sp, color: const Color(0xffe5a400)),
                  SizedBox(height: 16.sp),
                  Text(
                    'A nossa equipa responde rápido!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 8.sp),
                  Text(
                    'Se tiver dúvidas ou quiser sugerir alguma melhoria, escreva para nós.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.sp),
            Text('Formulário Directo', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
            SizedBox(height: 12.sp),
            Container(
              padding: EdgeInsets.all(20.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _buildTextField(_subjectController, 'Como podemos ajudar? (Assunto)', Icons.label_outline),
                  SizedBox(height: 16.sp),
                  _buildTextField(_messageController, 'Mensagem', Icons.message_outlined, maxLines: 4),
                  SizedBox(height: 20.sp),
                  SizedBox(
                    width: double.infinity,
                    height: 50.sp,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffe5a400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: _sending
                          ? SizedBox(width: 20.sp, height: 20.sp, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Enviar Mensagem', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.sp),
            Text('Outros Meios', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
            SizedBox(height: 12.sp),
            _buildContactMethod(Icons.email_outlined, 'Email', _email, Colors.blue, onTap: () => launchUrl(Uri(scheme: 'mailto', path: _email))),
            _buildContactMethod(Icons.phone_in_talk_outlined, 'Telefone', _phone, Colors.green, onTap: () => launchUrl(Uri(scheme: 'tel', path: _phone.replaceAll(' ', '')))),
            SizedBox(height: 40.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 70.sp : 0),
          child: Icon(icon, color: Colors.grey.shade400, size: 20.sp),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xffe5a400), width: 1.5)),
      ),
    );
  }

  Widget _buildContactMethod(IconData icon, String title, String detail, Color color, {required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.sp),
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.sp),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 16.sp),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey.shade600)),
                Text(detail, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
