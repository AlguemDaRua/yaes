import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/services/support_service.dart';

/// Cada tópico abre um ticket real via createTicket (self-service, ver
/// functions/src/support.ts). Sem chat ao vivo real — o botão abre um ticket
/// geral em vez de prometer uma funcionalidade que não existe.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  bool _sending = false;

  Future<void> _openTicket(String subject) async {
    final controller = TextEditingController();
    final details = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(subject, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Descreva o que se passou (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Enviar')),
        ],
      ),
    );
    if (details == null || _sending) return;
    setState(() => _sending = true);
    try {
      await SupportService.createTicket(subject: subject, text: details);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado. A nossa equipa vai responder em breve.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar o pedido. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static const _faq = [
    ('Como cancelo uma viagem?', 'Toque em "Cancelar viagem" no ecrã de acompanhamento antes de o motorista chegar. Cancelamentos tardios podem ter uma taxa.'),
    ('Como pago a viagem?', 'Pode pagar em dinheiro ao motorista ou via M-Pesa/E-Mola, escolhendo o método antes de confirmar o pedido.'),
    ('O motorista não apareceu, e agora?', 'Contacte o motorista pelo botão de chamada no ecrã da viagem, ou abra "Ajuda com uma Viagem Recente" acima.'),
    ('Como altero o meu número de telefone?', 'Por segurança, a alteração de número é feita através do suporte — abra um pedido em "A Minha Conta".'),
  ];

  void _showFaq() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perguntas Frequentes', style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 12.sp),
            for (final (q, a) in _faq)
              Padding(
                padding: EdgeInsets.only(bottom: 14.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14.sp)),
                    SizedBox(height: 2.sp),
                    Text(a, style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey.shade600, height: 1.4)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Suporte', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18.sp)),
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
            Text('Como podemos ajudar?', style: GoogleFonts.poppins(fontSize: 22.sp, fontWeight: FontWeight.w700, color: Colors.black87)),
            SizedBox(height: 8.sp),
            Text(
              'Escolha um tópico abaixo para abrir um pedido — a nossa equipa responde por aqui.',
              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 24.sp),
            _buildSupportTopic(context, 'Ajuda com uma Viagem Recente', 'Problemas com pagamentos, percursos ou itens perdidos.', Icons.directions_car_filled, Colors.blue),
            SizedBox(height: 16.sp),
            _buildSupportTopic(context, 'A Minha Conta', 'Problemas de acesso, atualização de dados.', Icons.person, Colors.green),
            SizedBox(height: 16.sp),
            _buildSupportTopic(context, 'Segurança e Emergências', 'Reportar um incidente ou atividade suspeita.', Icons.shield, Colors.redAccent),
            SizedBox(height: 16.sp),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _showFaq,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                padding: EdgeInsets.all(20.sp),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.sp),
                      decoration: BoxDecoration(color: const Color(0xffe5a400).withAlpha(20), shape: BoxShape.circle),
                      child: Icon(Icons.help, color: const Color(0xffe5a400), size: 24.sp),
                    ),
                    SizedBox(width: 16.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Questões Frequentes (FAQ)', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                          SizedBox(height: 4.sp),
                          Text('Explore respostas rápidas.', style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16.sp),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sending ? null : () => _openTicket('Pedido de apoio'),
        backgroundColor: Colors.black87,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: Text('Contactar Suporte', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSupportTopic(BuildContext context, String title, String description, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _sending ? null : () => _openTicket(title),
          child: Padding(
            padding: EdgeInsets.all(20.sp),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(width: 16.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                      SizedBox(height: 4.sp),
                      Text(description, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
