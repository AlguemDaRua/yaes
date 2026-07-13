import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';
import 'package:limousineexecutive/shared/widgets/skeletons.dart';
import '../../../utils/asset_paths.dart';

Future<void> showTripHistoryModal(BuildContext context) {
  final authRepo = Provider.of<IAuthRepository>(context, listen: false);
  final tripRepo = Provider.of<ITripRepository>(context, listen: false);
  final user = authRepo.currentUser;
  if (user == null) return Future.value();

  return showModalBottomSheet(
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
                    'Histórico de Viagens',
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const RideHistorySkeleton();
                  }
                  if (snapshot.hasError) {
                    debugPrint(snapshot.error.toString());

                    return Center(
                      child: Text(
                        'Ocorreu um erro ao carregar o histórico.',
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }

                  final trips = snapshot.data ?? [];
                  if (trips.isEmpty) {
                    return Center(
                      child: Text(
                        'Não possui viagens no histórico.',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    );
                  }

                  // Order trips by date descending
                  trips.sort((a, b) {
                    final dateA = _parseDate(a);
                    final dateB = _parseDate(b);
                    return dateB.compareTo(dateA);
                  });

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.sp,
                      vertical: 8.sp,
                    ),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      return _buildTripCard(trips[index]);
                    },
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

DateTime _parseDate(Map<String, dynamic> trip) {
  final t = trip['timestamps'];
  if (t != null && t['created'] != null) {
    return DateTime.tryParse(t['created']) ?? DateTime.now();
  }
  return DateTime.now();
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
    case 'concluído':
      return Colors.green;
    case 'cancelled':
    case 'cancelado':
      return Colors.red;
    case 'started':
    case 'accepted':
      return Colors.blue;
    case 'pending':
    default:
      return Colors.amber;
  }
}

String _translateStatus(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return 'Concluído';
    case 'cancelled':
      return 'Cancelado';
    case 'started':
      return 'Em Curso';
    case 'accepted':
      return 'Aceite';
    case 'pending':
      return 'Pendente';
    default:
      return status;
  }
}

Widget _buildTripCard(Map<String, dynamic> trip) {
  final created = _parseDate(trip);
  final timeStr = _formatDateTime(created);
  final status = trip['status'] ?? 'pending';
  final translatedStatus = _translateStatus(status);
  final statusColor = _getStatusColor(status);

  final price = trip['estimatedPrice'] != null
      ? '${trip['estimatedPrice']} MZN'
      : '--- MZN';

  final originName = trip['origin']?['name'] ?? 'Origem';
  final destName = trip['destination']?['name'] ?? 'Destino';
  final tripType = trip['tipo'] ?? 'Executiva';
  final List<dynamic> stopsList = trip['stops'] as List<dynamic>? ?? [];

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
            // Placeholder photo
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Viagem $tripType',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      Text(
                        price,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.sp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeStr,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.sp,
                          vertical: 2.sp,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          translatedStatus,
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        Divider(color: Colors.grey.withAlpha(40), height: 1),
        SizedBox(height: 12.sp),
        // Origin
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2.sp),
              child: Icon(Icons.my_location, size: 14.sp, color: Colors.amber),
            ),
            SizedBox(width: 8.sp),
            Expanded(
              child: Text(
                originName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 6.sp, top: 4.sp, bottom: 4.sp),
          child: Container(
            width: 2,
            height: 10.sp,
            color: Colors.grey.withAlpha(80),
          ),
        ),
        // Stops
        ...stopsList.map((stop) {
          final stopName = stop is Map ? (stop['name'] ?? 'Paragem') : 'Paragem';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.sp),
                    child: Icon(
                      Icons.stop_circle_outlined,
                      size: 14.sp,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  Expanded(
                    child: Text(
                      stopName.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 6.sp, top: 4.sp, bottom: 4.sp),
                child: Container(
                  width: 2,
                  height: 10.sp,
                  color: Colors.grey.withAlpha(80),
                ),
              ),
            ],
          );
        }),
        // Destination
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2.sp),
              child: Icon(Icons.location_on, size: 14.sp, color: Colors.red),
            ),
            SizedBox(width: 8.sp),
            Expanded(
              child: Text(
                destName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
