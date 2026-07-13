import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = 'Versão ${info.version}+${info.buildNumber}');
  }

  void _showTextPage(String title, String body) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            title: Text(title, style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16.sp)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20.sp),
            child: Text(body, style: GoogleFonts.poppins(fontSize: 13.5.sp, color: Colors.black87, height: 1.6)),
          ),
        ),
      ),
    );
  }

  static const _tariffsText =
      'O preço de cada viagem é calculado a partir de uma tarifa base fixa mais um valor por quilómetro percorrido, ajustado pela categoria de veículo escolhida (ex: moto, económico, executivo). '
      'Em horários de maior procura pode aplicar-se um multiplicador de tarifa dinâmica (surge). '
      'O valor estimado é sempre mostrado antes de confirmar o pedido, e o valor final reflete a distância e o tempo reais da viagem.';

  static const _termsText =
      'Ao usar a aplicação Ya, concorda em fornecer informação verdadeira no seu perfil, respeitar os motoristas e outros utilizadores, e usar a app apenas para fins pessoais de transporte. '
      'A Ya atua como intermediária entre passageiros e motoristas parceiros — os motoristas são responsáveis pela condução e pelo veículo. '
      'Reservamo-nos o direito de suspender contas em caso de fraude, abuso ou incumprimento destes termos. '
      'Para questões sobre uma viagem específica, contacte o suporte através da app.';

  static const _privacyText =
      'Recolhemos o seu nome, telefone e localização durante uma viagem para poder ligá-lo a um motorista e calcular o percurso. '
      'A sua localização em tempo real é partilhada apenas com o motorista atribuído à viagem em curso. '
      'Os dados de pagamento (M-Pesa/E-Mola) são usados apenas para processar a viagem, nunca partilhados com terceiros para fins de marketing. '
      'Pode pedir a eliminação da sua conta e dados a qualquer momento através do suporte.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Informações', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18.sp)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          children: [
            SizedBox(height: 20.sp),
            Container(
              padding: EdgeInsets.all(24.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Text('Ya', style: GoogleFonts.poppins(fontSize: 40.sp, fontWeight: FontWeight.w900, color: const Color(0xffe5a400))),
            ),
            SizedBox(height: 16.sp),
            Text(
              _version.isEmpty ? 'A carregar versão...' : _version,
              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 40.sp),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _buildInfoItem(title: 'Como funcionam as tarifas', onTap: () => _showTextPage('Como funcionam as tarifas', _tariffsText)),
                  _buildDivider(),
                  _buildInfoItem(title: 'Termos e Condições', onTap: () => _showTextPage('Termos e Condições', _termsText)),
                  _buildDivider(),
                  _buildInfoItem(title: 'Política de Privacidade', onTap: () => _showTextPage('Política de Privacidade', _privacyText)),
                  _buildDivider(),
                  _buildInfoItem(
                    title: 'Licenças de Software',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Ya',
                      applicationVersion: _version,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.sp),
            Text('© ${DateTime.now().year} Ya App Moçambique', style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 4.sp),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black87)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: Colors.grey.shade300),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.sp),
      child: Divider(color: Colors.grey.shade100, height: 1),
    );
  }
}
