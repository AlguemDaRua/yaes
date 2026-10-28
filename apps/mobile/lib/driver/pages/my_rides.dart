import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/shared/models/trip_date_filter.dart';
import 'package:limousineexecutive/shared/models/trip_history_entry.dart';
import 'package:limousineexecutive/shared/pages/trip_details_page.dart';
import 'package:limousineexecutive/shared/widgets/skeletons.dart';
import 'package:limousineexecutive/shared/widgets/trip_date_filter_sheet.dart';
import 'package:limousineexecutive/shared/widgets/trip_status_badge.dart';
import 'package:provider/provider.dart';

const Color _driverAccent = Color(0xFFE5A400);
const Color _pageBackground = Color(0xFFF7F8FA);

class MyRidesPage extends StatefulWidget {
  const MyRidesPage({super.key});

  @override
  State<MyRidesPage> createState() => _MyRidesPageState();
}

class _MyRidesPageState extends State<MyRidesPage> {
  static const List<String> _statusLabels = [
    'Em andamento',
    'Completas',
    'Canceladas',
  ];
  static const List<Set<String>> _statusValues = [
    {'started', 'accepted'},
    {'completed'},
    {'cancelled'},
  ];

  int _selectedRideStatusIndex = 0;
  TripDateFilter? _dateFilter;
  String? _streamUid;
  Stream<List<Map<String, dynamic>>>? _tripsStream;

  @override
  Widget build(BuildContext context) {
    final uid =
        Provider.of<IAuthRepository>(context, listen: false).currentUser?.uid;
    final tripRepository = Provider.of<ITripRepository>(context, listen: false);
    if (uid != _streamUid) {
      _streamUid = uid;
      _tripsStream = uid == null ? null : tripRepository.readTripsByDriver(uid);
    }

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: Text(
          'Minhas Corridas',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: _pageBackground,
        surfaceTintColor: _pageBackground,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            tooltip: _dateFilter == null
                ? 'Filtrar por período'
                : 'Período: ${_dateFilter!.label}',
            icon: Icon(
              _dateFilter == null
                  ? Icons.filter_list_rounded
                  : Icons.filter_alt_rounded,
              color: _driverAccent,
            ),
            onPressed: _openDateFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10.sp),
          SizedBox(
            height: 45.sp,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              itemCount: _statusLabels.length,
              itemBuilder: (context, index) => _buildStatusChip(index),
            ),
          ),
          if (_dateFilter != null) _buildActivePeriodChip(),
          SizedBox(height: 14.sp),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _tripsStream,
              builder: (context, snapshot) {
                if (uid == null) {
                  return const _HistoryFeedback(
                    icon: Icons.person_outline_rounded,
                    title: 'Sessão não disponível',
                    message: 'Inicia sessão para consultar as tuas viagens.',
                  );
                }
                if (snapshot.hasError) {
                  return _HistoryFeedback(
                    icon: Icons.cloud_off_rounded,
                    title: 'Não foi possível carregar as viagens',
                    message: 'Verifica a ligação e tenta novamente.',
                    actionLabel: 'Tentar novamente',
                    onAction: _reloadTrips,
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const RideHistorySkeleton();
                }

                final trips = (snapshot.data ?? const <Map<String, dynamic>>[])
                    .map(TripHistoryEntry.fromMap)
                    .where(_matchesSelectedStatus)
                    .where((trip) => _dateFilter?.includes(trip.createdAt) ?? true)
                    .toList()
                  ..sort(_compareNewestFirst);

                if (trips.isEmpty) {
                  return _HistoryFeedback(
                    icon: Icons.history_rounded,
                    title: 'Nenhuma corrida encontrada',
                    message: _dateFilter == null
                        ? 'Ainda não existem viagens nesta categoria.'
                        : 'Não há viagens no período selecionado nesta categoria.',
                    actionLabel: _dateFilter == null ? null : 'Limpar filtros',
                    onAction: _dateFilter == null ? null : _clearDateFilter,
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 22.sp),
                  itemCount: trips.length,
                  itemBuilder: (context, index) => _buildRideCard(trips[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(int index) {
    final isSelected = _selectedRideStatusIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRideStatusIndex = index),
      child: Container(
        margin: EdgeInsets.only(right: 12.sp),
        padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 8.sp),
        decoration: BoxDecoration(
          color: isSelected ? _driverAccent : Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _driverAccent.withValues(alpha: 0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            _statusLabels[index],
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivePeriodChip() {
    final filter = _dateFilter!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.sp, 10.sp, 20.sp, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.only(left: 11.sp, right: 4.sp),
          decoration: BoxDecoration(
            color: _driverAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13.sp,
                color: _driverAccent,
              ),
              SizedBox(width: 7.sp),
              Text(
                filter.label,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF5A4A21),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 2.sp),
              IconButton(
                tooltip: 'Limpar filtros',
                visualDensity: VisualDensity.compact,
                constraints: BoxConstraints.tightFor(
                  width: 30.sp,
                  height: 30.sp,
                ),
                padding: EdgeInsets.zero,
                onPressed: _clearDateFilter,
                icon: Icon(
                  Icons.close_rounded,
                  size: 15.sp,
                  color: const Color(0xFF5A4A21),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(TripHistoryEntry trip) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openDetails(trip),
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _driverAccent.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Icon(
                          Icons.person,
                          size: 45.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.passengerName ?? 'Passageiro',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 4.sp),
                          Text(
                            trip.createdAtLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      trip.amountLabel,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: _driverAccent,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.sp),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TripStatusBadge(trip: trip, compact: true),
                ),
                SizedBox(height: 14.sp),
                _buildRoutePoint(
                  Icons.trip_origin_rounded,
                  trip.origin,
                  const Color(0xFF2E9D5B),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10.sp),
                  child: Container(
                    width: 1.5,
                    height: 15.sp,
                    color: Colors.grey.shade200,
                  ),
                ),
                _buildRoutePoint(
                  Icons.flag_rounded,
                  trip.destination,
                  const Color(0xFFE24A4A),
                ),
                SizedBox(height: 12.sp),
                const Divider(height: 1),
                SizedBox(height: 8.sp),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniBadge(
                        Icons.directions_car_outlined,
                        trip.vehicleCategory,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openDetails(trip),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        padding: EdgeInsets.symmetric(horizontal: 4.sp),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(Icons.info_outline_rounded, size: 16.sp),
                      label: Text(
                        'Ver detalhes',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoutePoint(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(width: 12.sp),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 16.sp),
        SizedBox(width: 4.sp),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  bool _matchesSelectedStatus(TripHistoryEntry trip) =>
      _statusValues[_selectedRideStatusIndex].contains(trip.status);

  int _compareNewestFirst(TripHistoryEntry left, TripHistoryEntry right) {
    final leftDate = left.createdAt;
    final rightDate = right.createdAt;
    if (leftDate == null) return rightDate == null ? 0 : 1;
    if (rightDate == null) return -1;
    return rightDate.compareTo(leftDate);
  }

  Future<void> _openDateFilter() async {
    final result = await showTripDateFilterSheet(
      context,
      currentFilter: _dateFilter,
    );
    if (!mounted || result == null) return;
    setState(() => _dateFilter = result.filter);
  }

  void _clearDateFilter() {
    setState(() => _dateFilter = null);
  }

  void _reloadTrips() {
    final uid = _streamUid;
    if (uid == null) return;
    _tripsStream = context.read<ITripRepository>().readTripsByDriver(uid);
    setState(() {});
  }

  Future<void> _openDetails(TripHistoryEntry trip) {
    return openTripDetailsPage(
      context,
      trip: trip,
      audience: TripDetailsAudience.driver,
    );
  }
}

class _HistoryFeedback extends StatelessWidget {
  const _HistoryFeedback({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF28251F),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.poppins(
                    color: _driverAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
