import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';

class DiscountPage extends StatefulWidget {
  const DiscountPage({super.key});

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  final TextEditingController _promoController = TextEditingController();
  bool _checking = false;
  String? _promoMessage;
  bool _promoOk = false;

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _checking = true;
      _promoMessage = null;
    });
    final snap = await FirebaseDatabase.instance.ref('promoCodes/$code').get();
    final data = snap.value as Map?;
    final active = data != null && data['active'] == true;
    setState(() {
      _checking = false;
      _promoOk = active;
      _promoMessage = active
          ? 'Código aplicado: ${data['percent'] ?? 0}% de desconto.'
          : 'Código inválido ou expirado.';
    });
  }

  void _copyReferral(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado. Partilhe com os seus amigos!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final uid = authRepo.currentUser?.uid ?? '';
    final referralCode = uid.length >= 6 ? uid.substring(0, 6).toUpperCase() : uid.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Descontos e Ofertas',
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18.sp),
        ),
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
            // Promo Code Input Card
            Container(
              padding: EdgeInsets.all(24.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tem um código promocional?',
                    style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                  SizedBox(height: 12.sp),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Ex: YA2024',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14.sp),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.sp),
                      ElevatedButton(
                        onPressed: _checking ? null : _applyPromo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 14.sp),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        child: _checking
                            ? SizedBox(
                                width: 16.sp,
                                height: 16.sp,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Aplicar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (_promoMessage != null) ...[
                    SizedBox(height: 10.sp),
                    Text(
                      _promoMessage!,
                      style: GoogleFonts.poppins(fontSize: 12.sp, color: _promoOk ? Colors.green.shade700 : Colors.red.shade400),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 24.sp),

            // Refer a Friend Section
            Container(
              padding: EdgeInsets.all(24.sp),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xffe5a400), Color(0xffffc107)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [BoxShadow(color: const Color(0xffe5a400).withAlpha(60), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.sp),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle),
                    child: Icon(Icons.card_giftcard, color: Colors.white, size: 40.sp),
                  ),
                  SizedBox(height: 16.sp),
                  Text('Viagens Grátis?', style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                  SizedBox(height: 8.sp),
                  Text(
                    'Partilhe o seu código com amigos e receba descontos quando eles fizerem a primeira viagem.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.white.withAlpha(220)),
                  ),
                  SizedBox(height: 24.sp),
                  InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () => _copyReferral(referralCode),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.sp),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
                      child: Center(
                        child: Text(
                          referralCode.isEmpty ? 'Convidar Amigos' : 'Copiar código $referralCode',
                          style: GoogleFonts.poppins(color: const Color(0xffe5a400), fontWeight: FontWeight.w700, fontSize: 15.sp),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.sp),

            // Active Rewards List — real data, honesto quando vazio
            Text('As tuas ofertas', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
            SizedBox(height: 12.sp),
            StreamBuilder<Map<String, dynamic>?>(
              stream: tripRepo.watchProfile(uid),
              builder: (context, snapshot) {
                final List rewards = (snapshot.data?['rewards'] as List?) ?? const [];
                if (rewards.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(20.sp),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                    child: Center(
                      child: Text('Sem ofertas activas de momento.', style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey.shade500)),
                    ),
                  );
                }
                return Column(
                  children: rewards
                      .whereType<Map>()
                      .map((r) => _buildRewardItem(r['title']?.toString() ?? '', r['expiry']?.toString() ?? '', Colors.green))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem(String title, String expiry, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: color.withAlpha(30))),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.sp),
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
            child: Icon(Icons.stars, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.sp),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87)),
              Text(expiry, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}
