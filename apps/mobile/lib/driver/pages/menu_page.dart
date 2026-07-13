import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/utils/secure_storage.dart';
import 'package:provider/provider.dart';

class DriverMenuPage extends StatefulWidget {
  const DriverMenuPage({super.key});

  @override
  State<DriverMenuPage> createState() => _DriverMenuPageState();
}

class _DriverMenuPageState extends State<DriverMenuPage> {


  StreamSubscription? _profileSub;
  String name = '';
  String phone = '';
  String photoUrl = '';

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
          setState(() {
            name = profile['name'] ?? '';
            phone = profile['phone'] ?? '';
            photoUrl = profile['photoUrl'] ?? '';
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
                    icon: Icon(Icons.edit, color: mainColor, size: 24.sp),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/driver_profile'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.sp),

            // Menu Items List
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
                    icon: Icons.car_crash,
                    title: 'Minhas Corridas',
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/my_rides'),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.star_border,
                    title: 'Avaliações',
                    color: Colors.amber.shade600,
                    onTap: () => Navigator.pushNamed(context, '/ratings'),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.wallet_rounded,
                    title: 'Carteira',
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/my_gain'),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.notifications,
                    title: 'Notificações',
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.support_agent_outlined,
                    title: 'Suporte',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/support'),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.phone_in_talk_sharp,
                    title: 'Contacte-nos',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/contact_us'),
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
                          'Sair da Conta',
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
            SizedBox(height: 30.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
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
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
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
