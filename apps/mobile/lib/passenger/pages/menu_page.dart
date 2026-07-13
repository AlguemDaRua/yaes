import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/utils/secure_storage.dart';
import 'package:provider/provider.dart';
import '../components/bottomsheet/modal_trip_history.dart';

class PassengerMenuPage extends StatefulWidget {
  const PassengerMenuPage({super.key});

  @override
  State<PassengerMenuPage> createState() => _MenuState();
}

// Removidas antigas definições manuais de Divider e estilos textuais

class _MenuState extends State<PassengerMenuPage> {


  StreamSubscription? _profileSub;
  String name = '';
  String phone = '';
  String photoUrl = '';
  String? _paymentSubtitle;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final user = authRepo.currentUser;
    if (user != null) {
      _profileSub = tripRepo.watchProfile(user.uid).listen((profile) {
        if (profile != null && mounted) {
          final methods = profile['paymentMethods'] as Map?;
          final firstConfigured = methods?.entries.firstWhere(
            (e) => (e.value?.toString() ?? '').isNotEmpty,
            orElse: () => const MapEntry('', ''),
          );
          setState(() {
            name = profile['name'] ?? '';
            phone = profile['phone'] ?? '';
            photoUrl = profile['photoUrl'] ?? '';
            _paymentSubtitle = (firstConfigured?.key.isNotEmpty ?? false)
                ? (firstConfigured!.key == 'mpesa' ? 'M-Pesa' : 'E-Mola')
                : null;
          });
        }
      });
    }
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Terminar Sessão?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.sp),
              Text(
                "Tem a certeza de que deseja sair da sua conta?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.sp),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.sp),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(25),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Center(
                          child: Text(
                            "Manter",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.sp),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5252).withAlpha(60),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Terminar",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    await authRepo.signOut();
    Preferences.removeNumber();
    Preferences.removeType();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor = const Color(0xffe5a400);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        surfaceTintColor: const Color(0xFFF7F8FA),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Menu',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10.sp),
            // Profile Header
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.sp),
              padding: EdgeInsets.all(20.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Hero(
                    tag: "user",
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mainColor.withAlpha(100),
                          width: 3.sp,
                        ),
                      ),
                      child: ClipOval(
                        child: photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                width: 70.sp,
                                height: 70.sp,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 70.sp,
                                      height: 70.sp,
                                      color: Colors.grey.withAlpha(40),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                        size: 30.sp,
                                      ),
                                    ),
                              )
                            : Container(
                                width: 70.sp,
                                height: 70.sp,
                                color: Colors.grey.withAlpha(40),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 30.sp,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Carregando...',
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.sp),
                        Text(
                          phone.isNotEmpty ? phone : 'Carregando...',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade400,
                      size: 20.sp,
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/user_profile'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.sp),

            // Menu Items List 1
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.credit_card,
                    title: 'Métodos de Pagamento',
                    subtitle: _paymentSubtitle ?? 'Adicionar método',
                    color: Colors.blue,
                    onTap: () =>
                        Navigator.pushNamed(context, '/payment_methods'),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.discount_outlined,
                    title: 'Descontos e ofertas',
                    subtitle: 'Introduzir código promocional',
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/discount'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.sp),

            // Menu Items List 2
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Histórico',
                    subtitle: 'Histórico de viagens',
                    color: Colors.orange,
                    onTap: () => showTripHistoryModal(context),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'As minhas moradas',
                    color: Colors.indigo,
                    onTap: () => Navigator.pushNamed(context, '/my_locations'),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.headset_mic_outlined,
                    title: 'Suporte',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/support'),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Segurança',
                    color: Colors.redAccent,
                    onTap: () => Navigator.pushNamed(context, '/security'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.sp),

            // Menu Items List 3
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Definições',
                    color: Colors.grey.shade700,
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'Informações',
                    color: Colors.blueGrey,
                    onTap: () => Navigator.pushNamed(context, '/information'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.sp),

            // Logout
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _logout,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 16.sp,
                      horizontal: 20.sp,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.withAlpha(50)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.exit_to_app_rounded,
                          color: Colors.red,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.sp),
                        Text(
                          'Terminar Sessão',
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 16.sp),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.sp),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(width: 16.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.sp),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 68.sp, right: 20.sp),
      child: Divider(color: Colors.grey.shade200, height: 1),
    );
  }
}
