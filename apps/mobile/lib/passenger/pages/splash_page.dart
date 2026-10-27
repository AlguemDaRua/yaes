import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:limousineexecutive/driver/pages/initial_page_driver.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/pages/passenger_home_page.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/services/session_role_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════
// TRIP RECOVERY DIALOGS
// ═══════════════════════════════════════════

/// Passenger-themed recovery dialog (white background, gold accent)
Future<void> _showPassengerRecoveryDialog(BuildContext context, String status) {
  final statusMsg = status == 'pending'
      ? 'Ainda estamos à procura de um motorista para si.'
      : 'O seu motorista está a caminho.';

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_rounded,
              size: 48.sp,
              color: const Color(0xffe5a400),
            ),
            SizedBox(height: 16.sp),
            Text(
              'Viagem em curso',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.sp),
            Text(
              'Detectámos que ainda tem uma viagem activa. $statusMsg\n\nVamos levá-lo de volta à sua viagem.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.sp),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.sp),
                decoration: BoxDecoration(
                  color: const Color(0xffe5a400),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffe5a400).withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Continuar viagem',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Driver-themed recovery dialog (dark background, amber accent)
Future<void> _showDriverRecoveryDialog(BuildContext context, String status) {
  final statusMsg = status == 'accepted'
      ? 'Estava a caminho do passageiro.'
      : 'A viagem já estava em andamento.';

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      icon: Icon(
        Icons.local_taxi_rounded,
        size: 44.sp,
        color: Colors.amberAccent,
      ),
      title: Text(
        'Viagem em curso',
        style: TextStyle(
          color: Colors.amberAccent,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 6,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      content: Text(
        'Detectámos que tem uma viagem activa. $statusMsg\n\nVamos recuperar a sua viagem.',
        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
              shadowColor: Colors.amber.withValues(alpha: 0.4),
              elevation: 6,
              padding: EdgeInsets.symmetric(vertical: 14.sp),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Continuar viagem',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Best-effort: nunca bloqueia o arranque. Corre em paralelo com a resolução
/// de auth — as home pages tratam a ausência de localização por si mesmas.
Future<void> _getCurrentLocation(BuildContext context) async {
  final passageiroState = Provider.of<PassengerState>(context, listen: false);
  final motoristaState = Provider.of<DriverState>(context, listen: false);

  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled || !context.mounted) return;

    var status = await Permission.location.request();
    if (!context.mounted || status.isDenied || status.isPermanentlyDenied) {
      return;
    }

    // Tenta a última posição conhecida primeiro (instantânea); só pede uma
    // posição fresca (com timeout curto) se não houver cache.
    var position = await Geolocator.getLastKnownPosition();
    position ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    ).timeout(const Duration(seconds: 3));

    if (!context.mounted) return;
    passageiroState.currentLocation = LatLng(
      position.latitude,
      position.longitude,
    );
    passageiroState.originLocation = passageiroState.currentLocation;
    motoristaState.setCurrentLocation(
      LatLng(position.latitude, position.longitude),
    );
    passageiroState.fromAddress = 'Minha localização';
    passageiroState.controllerPickup.text = 'Minha localização';
  } catch (_) {
    // Sem localização ou timeout — a home page trata isto.
  }
}

/// Resolves the authenticated account and recovers an active trip. This is
/// a bootstrap step, with no second branded splash after OTP sign-in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _startupError;

  @override
  void initState() {
    super.initState();

    // Localização em paralelo — nunca atrasa a navegação.
    unawaited(_getCurrentLocation(context));

    _resolveAndNavigate();
  }

  Future<void> _resolveAndNavigate() async {
    setState(() => _startupError = null);

    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    // AuthSessionGate owns authentication. Profile/cache failures keep the
    // authenticated session here with a retry action instead of opening login.
    final currentUser = authRepo.currentUser;
    if (currentUser == null) return;

    Widget destino;
    try {
      final userType = await SessionRoleService(
        auth: authRepo,
      ).resolveType(currentUser);
      if (!mounted) return;

      if (userType == 'driver') {
        Map<String, dynamic>? activeTrip;
        try {
          activeTrip = await tripRepo
              .findActiveTripForDriver(currentUser.uid)
              .timeout(const Duration(seconds: 6));
        } catch (error) {
          debugPrint('Falha ao recuperar viagem do motorista: $error');
        }
        if (activeTrip != null && mounted) {
          final tripStatus = activeTrip['status']?.toString() ?? '';
          await _showDriverRecoveryDialog(context, tripStatus);
          if (!mounted) return;
          final driverState = Provider.of<DriverState>(context, listen: false);
          driverState.restoreActiveTrip(activeTrip['id'], activeTrip);
        }
        destino = const DriverHomePage();
      } else {
        Map<String, dynamic>? activeTrip;
        try {
          activeTrip = await tripRepo
              .findActiveTripForPassenger(currentUser.uid)
              .timeout(const Duration(seconds: 6));
        } catch (error) {
          debugPrint('Falha ao recuperar viagem do passageiro: $error');
        }
        if (activeTrip != null && mounted) {
          final tripStatus = activeTrip['status']?.toString() ?? '';
          await _showPassengerRecoveryDialog(context, tripStatus);
          if (!mounted) return;
          final passengerState = Provider.of<PassengerState>(
            context,
            listen: false,
          );
          passengerState.restoreActiveTrip(activeTrip['id'], activeTrip);
        }
        destino = const PassengerHomePage();
      }
    } catch (error) {
      debugPrint('[SESSION] Não foi possível recuperar a conta: $error');
      if (!mounted) return;
      setState(
        () => _startupError =
            'Não foi possível recuperar a tua conta. Verifica a ligação e tenta novamente.',
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => destino,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _startupError == null
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFFE5A400),
                      strokeWidth: 2,
                      semanticsLabel: 'A abrir a tua conta',
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _startupError!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _resolveAndNavigate,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A400),
                          foregroundColor: const Color(0xFF24262B),
                          minimumSize: const Size(160, 48),
                        ),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
