import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/authentication/phone_number_page.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:limousineexecutive/driver/pages/initial_page_driver.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/pages/passenger_home_page.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/utils/secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../utils/asset_paths.dart';

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
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
        side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
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
    if (!serviceEnabled) return;

    var status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      return;
    }

    // Tenta a última posição conhecida primeiro (instantânea); só pede uma
    // posição fresca (com timeout curto) se não houver cache.
    var position = await Geolocator.getLastKnownPosition();
    position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 3));

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

/// Splash único: mostra a marca, resolve sessão+tipo+viagem activa em
/// paralelo com a localização (que nunca bloqueia), e navega assim que a
/// resolução terminar — sujeito a um tempo mínimo de marca (evita "flash").
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _minVisible = Duration(milliseconds: 500);
  static const _transitionDuration = Duration(milliseconds: 350);

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    // Só remove o splash nativo depois deste frame estar desenhado — evita
    // o "salto" de ver os dois splashes (nativo + Flutter) sobrepostos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    // Localização em paralelo — nunca atrasa a navegação.
    unawaited(_getCurrentLocation(context));

    _resolveAndNavigate();
  }

  Future<void> _resolveAndNavigate() async {
    final started = DateTime.now();

    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final currentUser = authRepo.currentUser;

    Widget destino;
    if (currentUser == null) {
      destino = const PhoneNumberPage();
    } else {
      final userType = await authRepo.getUserType(currentUser.uid);
      await Preferences.saveType(userType);
      if (!mounted) return;

      if (userType == 'driver') {
        final activeTrip =
            await tripRepo.findActiveTripForDriver(currentUser.uid);
        if (activeTrip != null && mounted) {
          final tripStatus = activeTrip['status']?.toString() ?? '';
          await _showDriverRecoveryDialog(context, tripStatus);
          if (!mounted) return;
          final driverState = Provider.of<DriverState>(context, listen: false);
          driverState.restoreActiveTrip(activeTrip['id'], activeTrip);
        }
        destino = const DriverHomePage();
      } else {
        final activeTrip =
            await tripRepo.findActiveTripForPassenger(currentUser.uid);
        if (activeTrip != null && mounted) {
          final tripStatus = activeTrip['status']?.toString() ?? '';
          await _showPassengerRecoveryDialog(context, tripStatus);
          if (!mounted) return;
          final passengerState =
              Provider.of<PassengerState>(context, listen: false);
          passengerState.restoreActiveTrip(activeTrip['id'], activeTrip);
        }
        destino = const PassengerHomePage();
      }
    }

    // Tempo mínimo de marca (para não "piscar" em ligações rápidas), nunca
    // mais do que o necessário.
    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minVisible) {
      await Future.delayed(_minVisible - elapsed);
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: _transitionDuration,
        pageBuilder: (_, __, ___) => destino,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3B2222),
              Color(0xFF654328),
              Color(0xFFB59840),
              Color(0xFFFFEAAA),
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: "logo",
                  child: Image.asset(
                    AssetPaths.logo_gold,
                    width: 140.sp,
                    height: 140.sp,
                  ),
                ),
                SizedBox(height: 16.sp),
                Text(
                  'YA!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50.sp,
                    fontFamily: 'Gagalin',
                  ),
                ),
                SizedBox(height: 12.sp),
                SizedBox(
                  width: 20.sp,
                  height: 20.sp,
                  child: const CircularProgressIndicator(
                    color: Colors.amber,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
