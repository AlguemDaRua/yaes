import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/shared/models/trip_history_entry.dart';
import 'package:limousineexecutive/shared/pages/trip_details_page.dart';
import 'package:limousineexecutive/shared/widgets/skeletons.dart';
import 'package:limousineexecutive/shared/widgets/trip_status_badge.dart';
import 'package:provider/provider.dart';

import '../../../utils/asset_paths.dart';

Future<void> showTripHistoryModal(BuildContext context) {
  final authRepo = Provider.of<IAuthRepository>(context, listen: false);
  final tripRepo = Provider.of<ITripRepository>(context, listen: false);
  final user = authRepo.currentUser;
  if (user == null) return Future.value();

  return showModalBottomSheet<void>(
    isDismissible: true,
    backgroundColor: Colors.white,
    enableDrag: true,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 12.sp),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 18.sp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.sp),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.history, color: Colors.blue, size: 20.sp),
                  ),
                  SizedBox(width: 12.sp),
                  Text(
                    'Histórico de viagens',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 18.sp,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.sp),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: tripRepo.readTripsByPassenger(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _HistoryMessage(
                      icon: Icons.cloud_off_rounded,
                      message:
                          'Não foi possível carregar o histórico.\nVerifica a ligação e tenta novamente.',
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const RideHistorySkeleton();
                  }

                  final trips = (snapshot.data ?? const <Map<String, dynamic>>[])
                      .map(TripHistoryEntry.fromMap)
                      .toList()
                    ..sort(_compareNewestFirst);

                  if (trips.isEmpty) {
                    return const _HistoryMessage(
                      icon: Icons.history_rounded,
                      message: 'Não existem viagens no histórico.',
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.sp,
                      vertical: 8.sp,
                    ),
                    itemCount: trips.length,
                    itemBuilder: (context, index) => _buildTripCard(
                      context,
                      user.uid,
                      trips[index],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

int _compareNewestFirst(TripHistoryEntry left, TripHistoryEntry right) {
  final leftDate = left.createdAt;
  final rightDate = right.createdAt;
  if (leftDate == null) return rightDate == null ? 0 : 1;
  if (rightDate == null) return -1;
  return rightDate.compareTo(leftDate);
}

Widget _buildTripCard(
  BuildContext context,
  String passengerUid,
  TripHistoryEntry trip,
) {
  return Container(
    margin: EdgeInsets.only(bottom: 12.sp),
    padding: EdgeInsets.all(16.sp),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.withAlpha(40)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(5),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50.sp,
              height: 50.sp,
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(AssetPaths.caricon),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Viagem ${trip.tripTypeLabel.toLowerCase()}',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.sp),
                      Text(
                        trip.amountLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.sp),
                  Text(
                    trip.createdAtLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 7.sp),
                  TripStatusBadge(trip: trip, compact: true),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        Divider(color: Colors.grey.withAlpha(40), height: 1),
        SizedBox(height: 12.sp),
        _buildRoutePoint(
          Icons.my_location,
          trip.origin,
          Colors.amber.shade700,
        ),
        if (trip.stops.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(left: 6.sp, top: 4.sp, bottom: 4.sp),
            child: Container(
              width: 2,
              height: 10.sp,
              color: Colors.grey.withAlpha(80),
            ),
          ),
          ...trip.stops.map(
            (stop) => Padding(
              padding: EdgeInsets.only(bottom: 4.sp),
              child: _buildRoutePoint(
                Icons.stop_circle_outlined,
                stop,
                Colors.blue,
              ),
            ),
          ),
        ],
        Padding(
          padding: EdgeInsets.only(left: 6.sp, top: 4.sp, bottom: 4.sp),
          child: Container(
            width: 2,
            height: 10.sp,
            color: Colors.grey.withAlpha(80),
          ),
        ),
        _buildRoutePoint(Icons.location_on, trip.destination, Colors.red),
        SizedBox(height: 8.sp),
        _PassengerRatingStatus(
          passengerUid: passengerUid,
          tripId: trip.id,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 2.sp,
            children: [
              TextButton.icon(
                onPressed: () => openTripDetailsPage(
                  context,
                  trip: trip,
                  audience: TripDetailsAudience.passenger,
                ),
                icon: Icon(Icons.info_outline_rounded, size: 16.sp),
                label: Text(
                  'Ver detalhes',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showTripReceipt(context, trip),
                icon: Icon(Icons.receipt_long_rounded, size: 16.sp),
                label: Text(
                  'Recibo',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8A6500),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildRoutePoint(IconData icon, String label, Color color) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(top: 2.sp),
        child: Icon(icon, size: 14.sp, color: color),
      ),
      SizedBox(width: 8.sp),
      Expanded(
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: Colors.black87,
          ),
        ),
      ),
    ],
  );
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40.sp, color: Colors.grey.shade400),
            SizedBox(height: 10.sp),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerRatingStatus extends StatelessWidget {
  const _PassengerRatingStatus({
    required this.passengerUid,
    required this.tripId,
  });

  final String passengerUid;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    if (tripId.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref('userRatings/$passengerUid/$tripId')
          .onValue,
      builder: (context, snapshot) {
        final value = snapshot.data?.snapshot.child('value').value;
        if (value is! num) return const SizedBox.shrink();
        final rating = value.toDouble();
        return Padding(
          padding: EdgeInsets.only(top: 4.sp),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                color: const Color(0xFFE5A400),
                size: 16.sp,
              ),
              SizedBox(width: 4.sp),
              Text(
                'Avaliação dada: ${rating.toStringAsFixed(1)}',
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  color: const Color(0xFF5D5B53),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showTripReceipt(BuildContext context, TripHistoryEntry trip) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: EdgeInsets.fromLTRB(22.sp, 14.sp, 22.sp, 26.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42.sp,
              height: 4.sp,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          SizedBox(height: 18.sp),
          Text(
            'Recibo da viagem',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            trip.createdAtLabel,
            style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.black54),
          ),
          SizedBox(height: 16.sp),
          _receiptLine('Partida', trip.origin),
          _receiptLine('Destino', trip.destination),
          _receiptLine('Pagamento', trip.paymentMethod),
          _receiptLine('Estado', trip.paymentStatus),
          Divider(height: 24.sp),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor da viagem',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              Text(
                trip.amountLabel,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF8A6500),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _receiptLine(String title, String value) => Padding(
  padding: EdgeInsets.symmetric(vertical: 5.sp),
  child: Row(
    children: [
      SizedBox(
        width: 82.sp,
        child: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.black54),
        ),
      ),
      Expanded(
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  ),
);
