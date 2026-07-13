import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationController {
  final PassengerState appState;
  final AnimatedMapController animatedMapController;
  final BuildContext Function() contextGetter;
  final VoidCallback onLocationUpdated;

  StreamSubscription<Position>? _positionStream;

  LocationController({
    required this.appState,
    required this.animatedMapController,
    required this.contextGetter,
    required this.onLocationUpdated,
  });

  void startTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      appState.currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );
      onLocationUpdated();
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
  }

  Future<void> getCurrentLocation() async {
    final context = contextGetter();

    // 1. Check and request location permission
    var status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => Dialog(
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
                  "Permissão para localização negada",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12.sp),
                Text(
                  "Para continuar, conceda a permissão nas configurações do seu dispositivo.",
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.sp),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(25),
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Center(
                            child: Text(
                              "Cancelar",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          await openAppSettings();
                        },
                        child: Container(
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
                              "Configurações",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
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
        ),
      );
    }

    // 2. If granted, get position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    appState.currentLocation = LatLng(position.latitude, position.longitude);
    appState.originLocation = appState.currentLocation;
    appState.fromAddress = 'Minha localização';
    appState.controllerPickup.text = 'Minha localização';

    animatedMapController.animateTo(
      dest: appState.currentLocation!,
      zoom: 14,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }
}
