import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Contactos de confiança reais em /users/{uid}/trustedContacts. O botão de
/// emergência liga para o mesmo número de suporte usado em contact_us_page.
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  static const _emergencyPhone = '+258840000000';

  Future<void> _callEmergency() async {
    final uri = Uri(scheme: 'tel', path: _emergencyPhone);
    await launchUrl(uri);
  }

  Future<void> _addContact(BuildContext context, ITripRepository tripRepo, String uid) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contacto de Confiança', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Nome')),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Telefone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (result != true) return;
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty || uid.isEmpty) return;
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await tripRepo.updateProfile(uid, {'trustedContacts/$key': {'name': name, 'phone': phone}});
  }

  Future<void> _removeContact(ITripRepository tripRepo, String uid, String key) async {
    await tripRepo.updateProfile(uid, {'trustedContacts/$key': null});
  }

  void _showInfoDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(body, style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey.shade700)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final uid = authRepo.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Segurança', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18.sp)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: tripRepo.watchProfile(uid),
        builder: (context, snapshot) {
          final Map contacts = (snapshot.data?['trustedContacts'] as Map?) ?? {};

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 30.sp),
                Center(
                  child: Container(
                    padding: EdgeInsets.all(30.sp),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffe5a400).withAlpha(15)),
                    child: Container(
                      padding: EdgeInsets.all(30.sp),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffe5a400).withAlpha(30)),
                      child: Icon(Icons.security, size: 80.sp, color: const Color(0xffe5a400)),
                    ),
                  ),
                ),
                SizedBox(height: 24.sp),
                Text(
                  'O seu bem-estar é prioridade',
                  style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.sp, vertical: 8.sp),
                  child: Text(
                    'Explore os recursos de segurança que temos à sua disposição para o proteger em todas as viagens.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey.shade600),
                  ),
                ),
                SizedBox(height: 30.sp),

                // Contactos de confiança reais
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 8.sp),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.all(16.sp),
                        leading: Container(
                          padding: EdgeInsets.all(12.sp),
                          decoration: BoxDecoration(color: Colors.blue.withAlpha(20), shape: BoxShape.circle),
                          child: Icon(Icons.people, color: Colors.blue, size: 24.sp),
                        ),
                        title: Text('Contactos de Confiança', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4.sp),
                          child: Text(
                            'Adicione amigos e familiares para a nossa equipa contactar em caso de emergência.',
                            style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500),
                          ),
                        ),
                        trailing: Icon(Icons.add_circle_outline, color: const Color(0xffe5a400), size: 22.sp),
                        onTap: () => _addContact(context, tripRepo, uid),
                      ),
                      if (contacts.isNotEmpty)
                        ...contacts.entries.map(
                          (e) => Padding(
                            padding: EdgeInsets.only(left: 20.sp, right: 12.sp, bottom: 8.sp),
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 16.sp, color: Colors.grey),
                                SizedBox(width: 8.sp),
                                Expanded(
                                  child: Text(
                                    '${(e.value as Map)['name']} — ${(e.value as Map)['phone']}',
                                    style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.black87),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, size: 16.sp, color: Colors.grey.shade400),
                                  onPressed: () => _removeContact(tripRepo, uid, e.key.toString()),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                _buildSecurityFeature(
                  'Assistência em Viagem',
                  'Em caso de problemas com o veículo ou na estrada, chame apoio.',
                  Icons.car_crash_rounded,
                  Colors.orange,
                  onTap: () => _showInfoDialog(
                    context,
                    'Assistência em Viagem',
                    'Ligue para a nossa linha de apoio ($_emergencyPhone) em caso de avaria, acidente ou qualquer imprevisto na estrada. A nossa equipa está disponível para o ajudar.',
                  ),
                ),
                _buildSecurityFeature(
                  'Centro de Segurança',
                  'Saiba como a app protege os seus dados pessoais e de pagamentos.',
                  Icons.privacy_tip_outlined,
                  Colors.green,
                  onTap: () => _showInfoDialog(
                    context,
                    'Centro de Segurança',
                    'Os seus dados de localização, pagamento e viagens são encriptados e partilhados apenas com o motorista atribuído à sua viagem. Nunca partilhamos os seus dados com terceiros sem consentimento.',
                  ),
                ),
                SizedBox(height: 24.sp),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.sp),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _callEmergency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.sp),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: Text(
                      'BOTÃO DE EMERGÊNCIA',
                      style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ),
                SizedBox(height: 40.sp),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityFeature(String title, String desc, IconData icon, Color color, {required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 8.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.sp),
        leading: Container(
          padding: EdgeInsets.all(12.sp),
          decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24.sp),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.sp),
          child: Text(desc, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500)),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}
