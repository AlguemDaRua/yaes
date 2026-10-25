import 'dart:math' as math;

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
    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: compactHeight ? 0.94 : 0.86,
      initialChildSize: compactHeight ? 0.76 : 0.68,
      builder: (context, scrollController) {
        return Container(
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F6F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 28,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                16.w,
                10.h,
                16.w,
                math.max(16.h, MediaQuery.of(context).padding.bottom),
              ),
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
                      _RouteSummaryCard(
                        fromAddress: appState.fromAddress,
                        toAddress: appState.toAddress,
                        stops: appState.stops,
                      ),
                      SizedBox(height: 12.h),
                      (appState.tripStatus == 'accepted' ||
                              appState.tripStatus == 'started')
                          ? const SelectedCarCard()
                          : SearchingDriver(category: appState.carCategory),
                      SizedBox(height: 8.h),
                      _CancelTripCard(
                        onCancel: () async {
                          final tripId = appState.currentTripId;
                          if (tripId == null) return;
                          try {
                            await Provider.of<ITripRepository>(
                              context,
                              listen: false,
                            ).updateTripStatus(tripId, 'cancelled');
                            appState.paymentMethod = '';
                            appState.isPaymentSelected = false;
                            appState.currentTripId = null;
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Não foi possível cancelar. Tenta novamente.',
                                ),
                              ),
                            );
                          }
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

class _HandleBar extends StatelessWidget {
  const _HandleBar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: const Color(0xFFC7C9C0),
          borderRadius: BorderRadius.circular(99.r),
        ),
      ),
    );
  }
}

class _CancelTripCard extends StatelessWidget {
  const _CancelTripCard({required this.onCancel});
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE9EAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 19.sp,
                color: RideInProgressSheet._accentColor,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Precisa cancelar?',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF202520),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Deslize para iniciar o cancelamento. Vamos confirmar consigo antes.',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              height: 1.45,
              color: const Color(0xFF74786E),
            ),
          ),
          SizedBox(height: 12.h),
          CancelRideSlider(onCancel: onCancel),
          Center(
            child: TextButton.icon(
              onPressed: () async {
                final confirmed = await showCancelDialog(context);
                if (confirmed == true && context.mounted) await onCancel();
              },
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancelar sem deslizar'),
              style: TextButton.styleFrom(
                minimumSize: Size(48.w, 48.h),
                foregroundColor: const Color(0xFF7E3029),
                textStyle: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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
      statusColor = const Color(0xFF26734D);
    } else if (status == 'in_progress' || status == 'started') {
      title = 'Viagem em curso';
      subtitle = 'Acompanhe os detalhes da sua viagem';
      icon = Icons.location_on_rounded;
      statusLabel = 'EM VIAGEM';
      statusColor = const Color(0xFF26734D);
    }

    return Row(
      children: [
        Container(
          width: 46.w,
          height: 46.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF202520),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(icon, color: const Color(0xFFF2C94C), size: 22.sp),
        ),
        SizedBox(width: 12.w),
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
                  color: const Color(0xFF202520),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: const Color(0xFF74786E),
                ),
              ),
            ],
          ),
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
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE9EAE3)),
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
                  color: const Color(0xFF74786E),
                ),
              ),
              const Spacer(),
              if (stops.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F1),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: Text(
                    '${stops.length} ${stops.length == 1 ? 'paragem' : 'paragens'}',
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5D6258),
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
          Divider(color: const Color(0xFFE9EAE3), height: 22.h, indent: 49.w),
          _RouteRow(
            icon: Icons.flag_rounded,
            label: 'DESTINO',
            value: toAddress.trim().isEmpty ? 'Destino' : toAddress,
          ),
          if (stopsText.isNotEmpty) ...[
            SizedBox(height: 10.sp),
            Divider(color: const Color(0xFFE9EAE3), height: 22.h, indent: 49.w),
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
            color: const Color(0xFFFFF8DF),
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
                  color: const Color(0xFF74786E),
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
                  color: const Color(0xFF202520),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
