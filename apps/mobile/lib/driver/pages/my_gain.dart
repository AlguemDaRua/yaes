import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:limousineexecutive/services/wallet_service.dart';

/// Ganhos e carteira do motorista — dados reais.
///
/// - Ganhos: totalEarningsMtn / tripsCount / rating de /users/{uid}.
/// - Carteira (só para motoristas de parceiros com liquidação por carteira,
///   ex. YA Direct): saldo, estado de bloqueio, extracto e recarga. Para
///   motoristas de frota normal a secção da carteira simplesmente não aparece.
class MyGainPage extends StatefulWidget {
  const MyGainPage({super.key});

  @override
  State<MyGainPage> createState() => _MyGainPageState();
}

class _MyGainPageState extends State<MyGainPage> {
  final Color _mainColor = const Color(0xffe5a400);
  final NumberFormat _money = NumberFormat('#,##0', 'pt');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _formatMtn(num value) => '${_money.format(value)} MT';

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Ganhos',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: uid == null
          ? const Center(child: Text('Sessão expirada.'))
          : StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('users/$uid').onValue,
              builder: (context, snapshot) {
                final raw = snapshot.data?.snapshot.value;
                final profile =
                    raw is Map ? Map<dynamic, dynamic>.from(raw) : null;
                if (profile == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final partnerId = profile['partnerId']?.toString();
                return _buildBody(context, uid, profile, partnerId);
              },
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    String uid,
    Map<dynamic, dynamic> profile,
    String? partnerId,
  ) {
    final earnings = (profile['totalEarningsMtn'] as num?) ?? 0;
    final trips = (profile['tripsCount'] as num?) ?? 0;
    final rating = (profile['rating'] as num?);

    List<Widget> children(DriverWallet? wallet) => [
          _buildEarningsCard(earnings),
          SizedBox(height: 16.sp),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Viagens',
                  '${trips.round()}',
                  Icons.directions_car_filled_rounded,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16.sp),
              Expanded(
                child: _buildStatItem(
                  'Avaliação',
                  rating == null ? '—' : rating.toStringAsFixed(1),
                  Icons.star_rounded,
                  Colors.amber,
                ),
              ),
            ],
          ),
          // Secção da carteira só quando o parceiro liquida por carteira
          // (o nó existe); motoristas de frota normal não a veem.
          if (wallet != null) ...[
            SizedBox(height: 24.sp),
            _buildWalletCard(context, wallet),
            SizedBox(height: 16.sp),
            _buildEntriesCard(wallet),
          ],
          SizedBox(height: 30.sp),
        ];

    ListView list(DriverWallet? wallet) => ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
          children: children(wallet),
        );

    if (partnerId == null || partnerId.isEmpty) return list(null);

    return StreamBuilder<DriverWallet?>(
      stream: WalletService.watch(partnerId, uid),
      builder: (context, snapshot) => list(snapshot.data),
    );
  }

  Widget _buildEarningsCard(num earnings) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.sp),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff1a1a1a), Color(0xff333333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ganhos totais',
            style:
                GoogleFonts.poppins(color: Colors.white70, fontSize: 13.sp),
          ),
          SizedBox(height: 8.sp),
          Text(
            _formatMtn(earnings),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, DriverWallet wallet) {
    final negative = wallet.balance < 0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: wallet.isBlocked
            ? Border.all(color: Colors.red.shade300)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carteira de comissão',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
                decoration: BoxDecoration(
                  color: wallet.isBlocked
                      ? Colors.red.withAlpha(20)
                      : Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  wallet.isBlocked ? 'Bloqueado' : 'Activo',
                  style: GoogleFonts.poppins(
                    color: wallet.isBlocked ? Colors.red : Colors.green,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          Text(
            _formatMtn(wallet.balance),
            style: GoogleFonts.poppins(
              color: negative ? Colors.red.shade700 : Colors.black87,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (wallet.isBlocked) ...[
            SizedBox(height: 4.sp),
            Text(
              'Saldo de comissão excedido — recarrega para voltar a ficar '
              'online.',
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: Colors.red.shade700,
              ),
            ),
          ],
          SizedBox(height: 16.sp),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _mainColor,
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(vertical: 12.sp),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: () => _showTopupSheet(context),
              icon: const Icon(Icons.add_card_rounded),
              label: Text(
                'Recarregar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesCard(DriverWallet wallet) {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extracto',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.sp),
          if (wallet.entries.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.sp),
              child: Text(
                'Sem movimentos ainda.',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            )
          else
            for (final entry in wallet.entries.take(30))
              _buildEntryRow(entry),
        ],
      ),
    );
  }

  Widget _buildEntryRow(WalletEntry entry) {
    final (label, icon, color) = switch (entry.type) {
      'commission' => ('Comissão', Icons.percent_rounded, Colors.orange),
      'topup' => ('Recarga', Icons.add_card_rounded, Colors.green),
      'earning' => ('Ganho (viagem digital)', Icons.payments_rounded, Colors.teal),
      _ => ('Ajuste', Icons.tune_rounded, Colors.blue),
    };
    final negative = entry.amountMtn < 0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.sp),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(width: 12.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${negative ? '' : '+'}${_formatMtn(entry.amountMtn)}',
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: negative ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(3), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 12.sp),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showTopupSheet(BuildContext context) async {
    final amountController = TextEditingController();
    String method = 'mpesa';
    bool busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20.sp,
            right: 20.sp,
            top: 20.sp,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + 20.sp,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Recarregar carteira',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.sp),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor (MT)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.sp),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'mpesa', label: Text('M-Pesa')),
                  ButtonSegment(value: 'emola', label: Text('e-Mola')),
                ],
                selected: {method},
                onSelectionChanged: (selection) =>
                    setSheetState(() => method = selection.first),
              ),
              SizedBox(height: 16.sp),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mainColor,
                  foregroundColor: Colors.black87,
                  padding: EdgeInsets.symmetric(vertical: 14.sp),
                ),
                onPressed: busy
                    ? null
                    : () async {
                        final amount =
                            int.tryParse(amountController.text.trim());
                        if (amount == null || amount <= 0) return;
                        setSheetState(() => busy = true);
                        try {
                          await WalletService.topup(
                            amountMtn: amount,
                            method: method,
                          );
                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Recarga iniciada — confirma no teu '
                                'telemóvel.',
                              ),
                            ),
                          );
                        } catch (e) {
                          setSheetState(() => busy = false);
                          if (!sheetContext.mounted) return;
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(
                              content: Text('Erro na recarga: $e'),
                            ),
                          );
                        }
                      },
                child: Text(
                  busy ? 'A iniciar...' : 'Confirmar recarga',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    amountController.dispose();
  }
}
