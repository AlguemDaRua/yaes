import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_date_time.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';

import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';
import 'package:provider/provider.dart';
import 'package:limousineexecutive/shared/widgets/skeletons.dart';

class MyAgendas extends StatefulWidget {
  const MyAgendas({super.key});

  @override
  State<MyAgendas> createState() => _MyAgendasState();
}

class _MyAgendasState extends State<MyAgendas> {


  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    PassengerState appState = Provider.of<PassengerState>(
      context,
      listen: false,
    );
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: tripRepo.readSchedules(authRepo.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xfff8f8f8),
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              scrolledUnderElevation: 0,
              elevation: 0,
              centerTitle: true,
              title: Text(
                'Minhas Agendas',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                  color: Colors.black,
                ),
              ),
            ),
            body: const RideHistorySkeleton(),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48.sp, color: Colors.grey),
                  SizedBox(height: 12.sp),
                  Text(
                    'Erro ao carregar agendas',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final agendas = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: const Color(0xfff8f8f8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            scrolledUnderElevation: 0,
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Minhas Agendas',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20.sp,
                color: Colors.black,
              ),
            ),
          ),
          body: agendas.isNotEmpty
              ? ListView.builder(
                  padding: EdgeInsets.fromLTRB(18.sp, 14.sp, 18.sp, 30.sp),
                  itemCount: agendas.length,
                  itemBuilder: (context, i) {
                    final agenda = agendas[i];
                    final car = agenda['car'];

                    final DateTime time = DateTime.parse(
                      agenda['time'] ?? DateTime.now().toIso8601String(),
                    );

                    final String formattedDate = DateFormat(
                      'dd MMM yyyy',
                      'pt_BR',
                    ).format(time);

                    final String formattedTime = DateFormat(
                      'HH:mm',
                    ).format(time);

                    // Check if it's a past agenda
                    final bool isPast = time.isBefore(DateTime.now());

                    return _buildAgendaCard(
                      context: context,
                      appState: appState,
                      agenda: agenda,
                      car: car,
                      formattedDate: formattedDate,
                      formattedTime: formattedTime,
                      isPast: isPast,
                      index: i,
                    );
                  },
                )
              : _buildEmptyState(),
        );
      },
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AssetPaths.agenda,
              width: 80.sp,
              color: Colors.grey.withAlpha(80),
            ),
            SizedBox(height: 20.sp),
            Text(
              'Sem agendas',
              style: GoogleFonts.poppins(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Quando agendar uma viagem,\nela aparecerá aqui.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Agenda Card ──
  Widget _buildAgendaCard({
    required BuildContext context,
    required PassengerState appState,
    required Map<String, dynamic> agenda,
    required Map car,
    required String formattedDate,
    required String formattedTime,
    required bool isPast,
    required int index,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top section: car + date/time ──
          Container(
            padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 16.sp, 12.sp),
            decoration: BoxDecoration(
              color: const Color(0xffe5a400).withAlpha(18),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                // Vehicle image (real photo from panel) or category icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 70.sp,
                    height: 50.sp,
                    color: Colors.white,
                    padding: EdgeInsets.all(6.sp),
                    child: (car['photoUrl'] != null &&
                            car['photoUrl'].toString().isNotEmpty)
                        ? Image.network(
                            car['photoUrl'],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.directions_car,
                              size: 28.sp,
                              color: Colors.grey,
                            ),
                          )
                        : Icon(
                            CarData.categoryIcon(
                              car['category']?.toString() ?? 'economico',
                            ),
                            size: 28.sp,
                            color: Colors.grey,
                          ),
                  ),
                ),
                SizedBox(width: 14.sp),
                // Car name + seats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car['name']!,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.sp),
                      Row(
                        children: [
                          Icon(
                            Icons.airline_seat_recline_normal,
                            size: 14.sp,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4.sp),
                          Text(
                            '${car['seats']} Lugares',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Date/time badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.sp,
                    vertical: 8.sp,
                  ),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.red.withAlpha(20)
                        : const Color(0xffe5a400).withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        formattedTime,
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: isPast ? Colors.red : const Color(0xffe5a400),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: isPast ? Colors.red.shade300 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Middle section: route info ──
          Padding(
            padding: EdgeInsets.fromLTRB(16.sp, 14.sp, 16.sp, 10.sp),
            child: Column(
              children: [
                // Origin
                _buildRouteRow(
                  icon: Icons.trip_origin,
                  iconColor: const Color(0xffe5a400),
                  label: 'Origem',
                  value: agenda['fromAddress'] ?? '',
                ),
                // Connector line
                Padding(
                  padding: EdgeInsets.only(left: 11.sp),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 2,
                      height: 20.sp,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xffe5a400).withAlpha(60),
                            Colors.red.withAlpha(60),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Destination
                _buildRouteRow(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.red,
                  label: 'Destino',
                  value: agenda['toAddress'] ?? '',
                ),
              ],
            ),
          ),

          // ── Divider ──
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.sp),
            height: 1,
            color: Colors.grey.withAlpha(25),
          ),

          // ── Bottom section: action buttons ──
          Padding(
            padding: EdgeInsets.all(12.sp),
            child: Row(
              children: [
                // Reschedule button
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        _handleReschedule(context, appState, agenda, index),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.sp),
                      decoration: BoxDecoration(
                        color: const Color(0xffe5a400),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffe5a400).withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_calendar_rounded,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6.sp),
                          Text(
                            'Remarcar',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.sp),
                // Cancel button
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        _handleCancel(context, appState, agenda, index),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.sp),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withAlpha(80),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 16.sp,
                            color: Colors.red,
                          ),
                          SizedBox(width: 6.sp),
                          Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Route Row ──
  Widget _buildRouteRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22.sp, color: iconColor),
        SizedBox(width: 12.sp),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Handle Reschedule ──
  Future<void> _handleReschedule(
    BuildContext context,
    PassengerState appState,
    Map<String, dynamic> agenda,
    int index,
  ) async {
    final timeSchedule = await showDateTimeModal(context);
    if (!context.mounted) return;
    if (timeSchedule != null) {
      final minAllowedTime = DateTime.now().add(const Duration(minutes: 30));

      if (timeSchedule.isAfter(minAllowedTime)) {
        await appState.rescheduleAgenda(agenda['id'] ?? '', timeSchedule);
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        // Start trip now
        appState.fromAddress = agenda['fromAddress'];
        appState.originLocation = agenda['originLocation'];
        appState.toAddress = agenda['toAddress'];
        appState.destinationLocation = agenda['destinationLocation'];
        appState.selectedCar = agenda['selectedCar'];
        appState.selectedCarIndex = agenda['selectedCarIndex'];
        appState.selectedCarType = agenda['selectedCarType'];
        appState.selectedCarTypeindex = agenda['selectedCarTypeIndex'];
        appState.paymentMethod = agenda['paymentMethod'];
        appState.isPaymentSelected = agenda['isPaymentSelected'];
        appState.stops = agenda['stops'];
        appState.showRoute = true;

        appState.removeAgendaAt(index);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  // ── Handle Cancel ──
  Future<void> _handleCancel(
    BuildContext context,
    PassengerState appState,
    Map<String, dynamic> agenda,
    int index,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
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
                  'Cancelar agenda?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12.sp),
                Text(
                  'Tem certeza que deseja cancelar esta agenda? Esta acção não pode ser desfeita.',
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
                    // Keep button
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
                              'Manter',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    // Confirm cancel button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.sp),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withAlpha(60),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Sim, cancelar',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
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
        );
      },
    );

    if (confirm == true) {
      await appState.cancelAgenda(agenda['id'] ?? '');
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}
