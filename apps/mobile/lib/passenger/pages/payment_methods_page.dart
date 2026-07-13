import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';

/// Métodos de pagamento reais, guardados em /users/{uid}/paymentMethods no
/// perfil (mesmo padrão usado para as restantes preferências do passageiro).
class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  static const _providers = [
    {'key': 'mpesa', 'label': 'M-Pesa', 'color': Color(0xFFDF2027), 'icon': Icons.phone_android},
    {'key': 'emola', 'label': 'E-Mola', 'color': Color(0xFFF28200), 'icon': Icons.phone_android_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final uid = authRepo.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Métodos de Pagamento',
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18.sp),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: tripRepo.watchProfile(uid),
        builder: (context, snapshot) {
          final Map methods = (snapshot.data?['paymentMethods'] as Map?) ?? {};
          return ListView(
            padding: EdgeInsets.all(20.sp),
            children: [
              for (final p in _providers) ...[
                _buildCard(
                  context,
                  tripRepo,
                  uid,
                  p['key'] as String,
                  p['label'] as String,
                  methods[p['key']]?.toString(),
                  p['color'] as Color,
                  p['icon'] as IconData,
                ),
                SizedBox(height: 16.sp),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ITripRepository tripRepo,
    String uid,
    String key,
    String bank,
    String? number,
    Color color,
    IconData icon,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _editNumber(context, tripRepo, uid, key, bank, number),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withAlpha(200)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withAlpha(60), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        padding: EdgeInsets.all(24.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bank, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                Icon(icon, color: Colors.white70, size: 28.sp),
              ],
            ),
            SizedBox(height: 30.sp),
            Text(
              number != null && number.isNotEmpty ? number : 'Toque para adicionar número',
              style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: number != null && number.isNotEmpty ? 22.sp : 15.sp, fontWeight: FontWeight.w600, letterSpacing: 2),
            ),
            SizedBox(height: 8.sp),
            Text(
              number != null && number.isNotEmpty ? 'TOQUE PARA EDITAR' : 'NÃO CONFIGURADO',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNumber(
    BuildContext context,
    ITripRepository tripRepo,
    String uid,
    String key,
    String bank,
    String? current,
  ) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Número $bank', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'Ex: 84 123 4567'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );
    if (result == null || uid.isEmpty) return;
    await tripRepo.updateProfile(uid, {'paymentMethods/$key': result});
  }
}
