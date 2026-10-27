import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:limousineexecutive/driver/components/agenda_box.dart';
import 'package:limousineexecutive/driver/components/top_bar.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';

/// Panels shown while the driver is outside a trip.
/// Own the queries here: Android Firebase streams cannot be listened to again
/// after cancellation. Each return from a trip creates fresh queries, while
/// location updates keep the current subscriptions intact.
class DriverIdlePanels extends StatefulWidget {
  const DriverIdlePanels({
    super.key,
    required this.watchConnection,
    required this.onRouteRequested,
  });

  final Stream<bool> Function() watchConnection;
  final VoidCallback onRouteRequested;

  @override
  State<DriverIdlePanels> createState() => _DriverIdlePanelsState();
}

class _DriverIdlePanelsState extends State<DriverIdlePanels> {
  late final Stream<List<Map<String, dynamic>>> _driverTripsStream;
  late final Stream<bool> _connectionStream;

  @override
  void initState() {
    super.initState();
    final repository = context.read<ITripRepository>();
    final uid = context.read<IAuthRepository>().currentUser?.uid ?? '';
    _driverTripsStream = repository.readTripsByDriver(uid);
    _connectionStream = widget.watchConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Top buttons and driver status (Online/offline)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10.sp,
          left: 15.sp,
          right: 15.sp,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: TopBar(onTap: widget.onRouteRequested)),
              ],
            ),
          ),
        ),

        // Daily earnings and schedule
        Positioned(
          left: 15.sp,
          right: 15.sp,
          top: MediaQuery.of(context).padding.top + 136.sp,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _driverTripsStream,
            builder: (context, snapshot) {
              final scheduledTrips = (snapshot.data ?? const []).where((trip) {
                final type = (trip['tripType'] ?? trip['tipo'])?.toString();
                final status = trip['status']?.toString();
                return type == 'scheduled' &&
                    status != 'completed' &&
                    status != 'cancelled';
              }).toList();
              if (scheduledTrips.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Row(children: [AgendaBox(count: scheduledTrips.length)]),
              );
            },
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 78.sp,
          left: 16.sp,
          right: 16.sp,
          child: _DriverReadinessBanner(connectionStream: _connectionStream),
        ),
      ],
    );
  }
}

class _DriverReadinessBanner extends StatelessWidget {
  const _DriverReadinessBanner({required this.connectionStream});

  final Stream<bool> connectionStream;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DriverState>();
    return StreamBuilder<bool>(
      stream: connectionStream,
      builder: (context, snapshot) {
        final connected = snapshot.data == true;
        final hasLocation = state.currentLocation != null;
        final walletBlocked = state.isWalletBlocked;
        final ready =
            connected && hasLocation && state.isOnline && !walletBlocked;
        final title = !connected
            ? 'A reconectar ao servidor…'
            : walletBlocked
            ? 'Carteira bloqueada — não recebes pedidos'
            : !hasLocation
            ? 'A obter localização para receber pedidos'
            : state.isOnline
            ? 'Online • elegível para receber pedidos'
            : 'Offline • ativa o botão para receber pedidos';
        final color = !connected || walletBlocked
            ? const Color(0xFFC2413A)
            : ready
            ? const Color(0xFF267347)
            : const Color(0xFF625A43);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14.sp),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                !connected
                    ? Icons.sync_rounded
                    : walletBlocked
                    ? Icons.account_balance_wallet_rounded
                    : !hasLocation
                    ? Icons.location_searching_rounded
                    : ready
                    ? Icons.wifi_tethering_rounded
                    : Icons.pause_circle_outline_rounded,
                size: 16.sp,
                color: color,
              ),
              SizedBox(width: 8.sp),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!connected)
                SizedBox(
                  width: 13.sp,
                  height: 13.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
