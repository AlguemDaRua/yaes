import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/languages.dart';

/// Preferências reais: notificações/chamadas/localização em
/// /users/{uid}/notificationPrefs (mesmo padrão do opt-out do parceiro, A3.3);
/// idioma persistido localmente via SharedPreferences (não há i18n real na
/// app — apenas a escolha é lembrada, ver ponytail note abaixo).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String language = 'Português';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language');
    if (saved != null && mounted) setState(() => language = saved);
  }

  Future<void> _setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    if (mounted) setState(() => language = lang);
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final uid = authRepo.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Definições', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18.sp)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: tripRepo.watchProfile(uid),
        builder: (context, snapshot) {
          final Map prefs = (snapshot.data?['notificationPrefs'] as Map?) ?? {};
          final bool notify = prefs['push'] != false;
          final bool noCalls = prefs['noCalls'] == true;
          final bool showLocation = prefs['showLocation'] != false;

          void update(String key, bool value) {
            if (uid.isEmpty) return;
            tripRepo.updateProfile(uid, {'notificationPrefs/$key': value});
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Preferências de App'),
                SizedBox(height: 12.sp),
                Container(
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notificações',
                        color: Colors.orange,
                        trailing: CupertinoSwitch(
                          value: notify,
                          activeTrackColor: const Color(0xffe5a400),
                          onChanged: (v) => update('push', v),
                        ),
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        icon: Icons.language_rounded,
                        title: 'Idioma da app',
                        subtitle: language,
                        color: Colors.blue,
                        onTap: _showLanguagePicker,
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.sp),
                _buildSectionHeader('Privacidade e Viagens'),
                SizedBox(height: 12.sp),
                Container(
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.phone_disabled_outlined,
                        title: 'Não me liguem',
                        subtitle: 'Ligar apenas em caso de emergência.',
                        color: Colors.redAccent,
                        trailing: CupertinoSwitch(
                          value: noCalls,
                          activeTrackColor: const Color(0xffe5a400),
                          onChanged: (v) => update('noCalls', v),
                        ),
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        icon: Icons.location_on_outlined,
                        title: 'Mostrar onde estou',
                        subtitle: 'Localização visível até à entrada no carro.',
                        color: Colors.green,
                        trailing: CupertinoSwitch(
                          value: showLocation,
                          activeTrackColor: const Color(0xffe5a400),
                          onChanged: (v) => update('showLocation', v),
                        ),
                      ),
                    ],
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.sp),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 8.sp),
      leading: Container(
        padding: EdgeInsets.all(10.sp),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22.sp),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black87)),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500)) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 68.sp, right: 20.sp),
      child: Divider(color: Colors.grey.shade100, height: 1),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30.r))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40.sp, height: 4.sp, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              SizedBox(height: 24.sp),
              Text('Seleccione o Idioma', style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.black87)),
              SizedBox(height: 20.sp),
              ...languages.map((lang) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      lang,
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: language == lang ? FontWeight.bold : FontWeight.w500,
                        color: language == lang ? const Color(0xffe5a400) : Colors.black87,
                      ),
                    ),
                    trailing: language == lang ? Icon(Icons.check_circle, color: const Color(0xffe5a400), size: 24.sp) : null,
                    onTap: () {
                      _setLanguage(lang);
                      Navigator.pop(context);
                    },
                  )),
              SizedBox(height: 20.sp),
            ],
          ),
        );
      },
    );
  }
}
