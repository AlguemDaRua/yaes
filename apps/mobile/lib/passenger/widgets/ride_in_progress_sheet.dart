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
    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: 0.7,
      initialChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            16.sp,
            12.sp,
            16.sp,
            MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                _HandleBar(),
                SizedBox(height: 14.sp),
                _SheetHeader(isSearchingDriver: isSearchingDriver),
                SizedBox(height: 14.sp),
                _RouteSummaryCard(
                  fromAddress: appState.fromAddress,
                  toAddress: appState.toAddress,
                  stops: appState.stops,
                ),
                SizedBox(height: 12.sp),

                // Carro escolhido
                (appState.tripStatus == 'accepted' ||
                        appState.tripStatus == 'started')
                    ? const SelectedCarCard()
                    : const SearchingDriver(),

                SizedBox(height: 12.sp),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.sp),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(10),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: _accentColor.withAlpha(30),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Cancelar viagem',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.sp),
                      Text(
                        'Deslize para cancelar com segurança.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 12.sp),
                      CancelRideSlider(
                        onCancel: () {
                          appState.paymentMethod = '';
                          appState.isPaymentSelected = false;
                          // appState.toAddress = '';
                          // appState.destinationLocation = null;
                          // appState.controllerDestination.clear();
                          // appState.showRoute = false;
                          // showCancelTripNotification();

                          final tripId = appState.currentTripId;
                          if (tripId != null) {
                            Provider.of<ITripRepository>(
                              context,
                              listen: false,
                            ).updateTripStatus(tripId, 'cancelled');
                            appState.currentTripId = null;
                          }
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.sp),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HandleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(40),
          borderRadius: BorderRadius.circular(10),
        ),
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

    if (status == 'accepted') {
      title = 'Motorista a caminho';
      subtitle = 'O motorista aceitou o seu pedido';
      icon = Icons.directions_car_rounded;
    } else if (status == 'in_progress' || status == 'started') {
      title = 'Viagem em curso';
      subtitle = 'Acompanhe os detalhes da sua viagem';
      icon = Icons.location_on_rounded;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.sp),
          decoration: BoxDecoration(
            color: _accentColor.withAlpha(25),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, color: _accentColor, size: 20.sp),
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 2.sp),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (status == 'accepted' || status == 'started')
          GestureDetector(
            onTap: () {
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
            child: Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: _accentColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                color: _accentColor,
                size: 20.sp,
              ),
            ),
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
      padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(12),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _accentColor.withAlpha(35), width: 1.2),
      ),
      child: Column(
        children: [
          _RouteRow(
            icon: Icons.my_location_rounded,
            label: 'De',
            value: fromAddress.trim().isEmpty
                ? 'Local de recolha'
                : fromAddress,
          ),
          SizedBox(height: 10.sp),
          Divider(color: Colors.black.withAlpha(18), height: 1),
          SizedBox(height: 10.sp),
          _RouteRow(
            icon: Icons.flag_rounded,
            label: 'Para',
            value: toAddress.trim().isEmpty ? 'Destino' : toAddress,
          ),
          if (stopsText.isNotEmpty) ...[
            SizedBox(height: 10.sp),
            Divider(color: Colors.black.withAlpha(18), height: 1),
            SizedBox(height: 10.sp),
            _RouteRow(
              icon: Icons.pin_drop_rounded,
              label: 'Paragens',
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
          width: 38.sp,
          height: 38.sp,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: _accentColor, size: 18.sp),
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
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
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
