import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/components/buttons/cancel_ride_slider.dart';
import 'package:limousineexecutive/passenger/components/selected_car_card.dart';
import 'package:limousineexecutive/passenger/components/searching_driver.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/shared/pages/chat_page.dart';
import 'package:provider/provider.dart';

class RideInProgressSheet extends StatelessWidget {
  static const Color _accentColor = Color(0xffe5a400);
  static const Color _ink = Color(0xff202124);
  static const Color _muted = Color(0xff70757a);
  static const Color _line = Color(0xffe8e8e8);

  final bool isSearchingDriver;
  final VoidCallback onRouteChanged;

  const RideInProgressSheet({
    super.key,
    required this.isSearchingDriver,
    required this.onRouteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    final screenSize = MediaQuery.sizeOf(context);
    final compactHeight = screenSize.height < 700;
    final hasDriver =
        appState.tripStatus == 'accepted' || appState.tripStatus == 'started';
    final maxChildSize = compactHeight ? 0.94 : 0.86;
    final estimatedContentHeight = hasDriver ? 540.h : 455.h;
    final initialChildSize = (estimatedContentHeight / screenSize.height)
        .clamp(0.5, maxChildSize)
        .toDouble();

    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: maxChildSize,
      initialChildSize: initialChildSize,
      builder: (context, scrollController) {
        return Container(
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 15.h),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    children: [
                      const _HandleBar(),
                      SizedBox(height: 10.h),
                      _SheetHeader(isSearchingDriver: isSearchingDriver),
                      SizedBox(height: 16.h),
                      const _NextStepCard(),
                      SizedBox(height: 12.h),
                      _RouteSummaryCard(
                        fromAddress: appState.fromAddress,
                        toAddress: appState.toAddress,
                        stops: appState.stops,
                      ),
                      SizedBox(height: 12.h),
                      hasDriver
                          ? const SelectedCarCard()
                          : const SearchingDriver(),
                      SizedBox(height: 8.h),
                      _CancelTripCard(
                        onCancel: (reason) async {
                          final tripId = appState.currentTripId;
                          if (tripId == null) {
                            throw StateError('Não existe uma viagem ativa.');
                          }
                          await Provider.of<ITripRepository>(
                            context,
                            listen: false,
                          ).updateTripStatus(
                            tripId,
                            'cancelled',
                            cancelledBy: 'passenger',
                            cancellationReason: reason,
                          );
                          appState.paymentMethod = '';
                          appState.isPaymentSelected = false;
                          appState.currentTripId = null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard();

  @override
  Widget build(BuildContext context) {
    final status = context.select<PassengerState, String>(
      (state) => state.tripStatus,
    );
    final (step, detail, progress) = switch (status) {
      'accepted' => (
        'Próximo passo',
        'O motorista está a caminho do ponto de recolha.',
        0.5,
      ),
      'started' || 'in_progress' => (
        'Viagem em curso',
        'Acompanhe o percurso até ao destino no mapa.',
        1.0,
      ),
      'awaiting_payment' => (
        'Pagamento pendente',
        'Confirme o pagamento para enviar o pedido aos motoristas.',
        0.15,
      ),
      _ => (
        'A procurar motorista',
        'Assim que alguém aceitar, mostramos aqui quem vem buscá-lo.',
        0.25,
      ),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 11.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: const Color(0xFFF2E3B7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.route_rounded,
                size: 17.sp,
                color: const Color(0xFF9A7000),
              ),
              SizedBox(width: 7.w),
              Text(
                step,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: RideInProgressSheet._ink,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            detail,
            style: GoogleFonts.poppins(
              fontSize: 10.5.sp,
              height: 1.35,
              color: RideInProgressSheet._muted,
            ),
          ),
          SizedBox(height: 9.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(99.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4.h,
              backgroundColor: const Color(0xFFEAE6DB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE5A400)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandleBar extends StatelessWidget {
  const _HandleBar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: const Color(0xFFD6D6D6),
          borderRadius: BorderRadius.circular(99.r),
        ),
      ),
    );
  }
}

class _CancelTripCard extends StatelessWidget {
  const _CancelTripCard({required this.onCancel});
  final Future<void> Function(String reason) onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: RideInProgressSheet._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cancelar viagem',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: RideInProgressSheet._ink,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          CancelRideSlider(onCancel: onCancel),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  static const Color _accentColor = RideInProgressSheet._accentColor;
  final bool isSearchingDriver;

  const _SheetHeader({required this.isSearchingDriver});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);
    final status = appState.tripStatus;

    String title = 'A procurar motorista';
    String subtitle = 'Estamos a notificar motoristas próximos';
    IconData icon = Icons.radar_rounded;
    String statusLabel = isSearchingDriver ? 'A PROCURAR' : 'PEDIDO ENVIADO';
    Color statusColor = _accentColor;

    if (status == 'accepted') {
      title = 'Motorista a caminho';
      subtitle = 'O motorista aceitou o seu pedido';
      icon = Icons.directions_car_rounded;
      statusLabel = 'CONFIRMADO';
      statusColor = const Color(0xFF238636);
    } else if (status == 'in_progress' || status == 'started') {
      title = 'Viagem em curso';
      subtitle = 'Acompanhe os detalhes da sua viagem';
      icon = Icons.location_on_rounded;
      statusLabel = 'EM VIAGEM';
      statusColor = const Color(0xFF238636);
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.55,
                    color: statusColor,
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: RideInProgressSheet._ink,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: RideInProgressSheet._muted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          width: 42.w,
          height: 42.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E0),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, color: _accentColor, size: 21.sp),
        ),
        if (status == 'accepted' || status == 'started')
          IconButton.filledTonal(
            tooltip: 'Abrir conversa com o motorista',
            constraints: BoxConstraints(minWidth: 48.w, minHeight: 48.w),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFF2C6),
              foregroundColor: const Color(0xFF202520),
            ),
            onPressed: () {
              if (appState.currentTripId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      tripId: appState.currentTripId!,
                      currentUserUid:
                          Provider.of<IAuthRepository>(
                            context,
                            listen: false,
                          ).currentUser?.uid ??
                          '',
                      currentUserType: 'passenger',
                      otherUserName: appState.driverName,
                      otherUserPhotoUrl: appState.driverPhotoUrl,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
      ],
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  static const Color _accentColor = RideInProgressSheet._accentColor;

  final String fromAddress;
  final String toAddress;
  final List<Map<String, dynamic>> stops;

  const _RouteSummaryCard({
    required this.fromAddress,
    required this.toAddress,
    required this.stops,
  });

  String _stopsLabel() {
    if (stops.isEmpty) return '';
    final names = stops
        .map((e) => (e['name'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (names.isEmpty) return '${stops.length} paragens';
    final preview = names.take(2).join(', ');
    final remaining = names.length - 2;
    if (remaining > 0) return '$preview +$remaining';
    return preview;
  }

  @override
  Widget build(BuildContext context) {
    final stopsText = _stopsLabel();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: RideInProgressSheet._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: _accentColor, size: 18.sp),
              SizedBox(width: 7.w),
              Text(
                'PERCURSO',
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: RideInProgressSheet._muted,
                ),
              ),
              const Spacer(),
              if (stops.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: Text(
                    '${stops.length} ${stops.length == 1 ? 'paragem' : 'paragens'}',
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: RideInProgressSheet._muted,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),
          _RouteRow(
            icon: Icons.my_location_rounded,
            label: 'EMBARQUE',
            value: fromAddress.trim().isEmpty
                ? 'Local de recolha'
                : fromAddress,
          ),
          SizedBox(height: 10.sp),
          Divider(color: RideInProgressSheet._line, height: 22.h, indent: 49.w),
          _RouteRow(
            icon: Icons.flag_rounded,
            label: 'DESTINO',
            value: toAddress.trim().isEmpty ? 'Destino' : toAddress,
          ),
          if (stopsText.isNotEmpty) ...[
            SizedBox(height: 10.sp),
            Divider(
              color: RideInProgressSheet._line,
              height: 22.h,
              indent: 49.w,
            ),
            _RouteRow(
              icon: Icons.pin_drop_rounded,
              label: 'PARAGENS',
              value: stopsText,
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  static const Color _accentColor = RideInProgressSheet._accentColor;
  final IconData icon;
  final String label;
  final String value;

  const _RouteRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E0),
            borderRadius: BorderRadius.circular(13.r),
          ),
          child: Icon(icon, color: _accentColor, size: 18.sp),
        ),
        SizedBox(width: 11.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.45,
                  color: RideInProgressSheet._muted,
                ),
              ),
              SizedBox(height: 2.sp),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: RideInProgressSheet._ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
