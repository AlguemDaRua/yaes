import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/services/location_service.dart';
import 'package:limousineexecutive/utils/app_config.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';
import 'package:provider/provider.dart';

class PickLocationOnMap extends StatefulWidget {
  final String text;
  /// Quando definido (modo "morada guardada"), o resultado é devolvido via
  /// Navigator.pop(result) em vez de escrever em PassengerState.
  final bool returnResult;
  const PickLocationOnMap({super.key, required this.text, this.returnResult = false});

  @override
  State<PickLocationOnMap> createState() => _PickLocationOnMapState();
}

class _PickLocationOnMapState extends State<PickLocationOnMap>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  String token = AppConfig.mapboxToken;

  Map<String, dynamic> _currentChoice = {};
  LatLng? _center;
  bool _isLoading = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<PassengerState>(context, listen: false);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    if (widget.text == 'De') {
      if (appState.fromAddress.isNotEmpty && appState.originLocation != null) {
        _center = appState.originLocation;
        return;
      }
    }
    if (widget.text == 'Para' || widget.text == 'Stop') {
      if (appState.toAddress.isNotEmpty &&
          appState.destinationLocation != null) {
        _center = appState.destinationLocation;
        return;
      }
    }
    _center = appState.currentLocation;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _getPlaceInfo(LatLng latLng) {
    setState(() {
      _isLoading = true;
    });

    EasyDebounce.debounce(
      'map-move-debounce',
      const Duration(milliseconds: 500),
      () async {
        setState(() {
          _center = latLng;
        });
        final temp = await LocationService.getPlaceInfoFromNominatim(
          _center!.latitude,
          _center!.longitude,
        );
        setState(() {
          _currentChoice = temp;
          _isLoading = false;
        });
      },
    );
  }

  void _confirmLocation() {
    if (_currentChoice.isEmpty) return;

    if (widget.returnResult) {
      Navigator.pop(context, {
        'name': _currentChoice['name'] ?? _currentChoice['fullName'],
        'fullName': _currentChoice['fullName'],
        'lat': _center!.latitude,
        'lng': _center!.longitude,
      });
      return;
    }

    final appState = Provider.of<PassengerState>(context, listen: false);

    if (_currentChoice.isNotEmpty) {
      if (widget.text == 'De') {
        appState.fromAddress =
            _currentChoice['name'] ?? _currentChoice['fullName'];
        appState.originLocation = _center;
      }

      if (widget.text == 'Para') {
        appState.toAddress =
            _currentChoice['name'] ?? _currentChoice['fullName'];
        appState.destinationLocation = _center;
      }

      if (widget.text == 'Stop') {
        Map<String, dynamic> stop = {
          'name': _currentChoice['name'] ?? _currentChoice['fullName'],
          'fullName': _currentChoice['fullName'],
          'type': _currentChoice['type'],
          'latlong': _center,
        };
        appState.addStop(stop);
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      FocusScope.of(context).unfocus();
      appState.showDestinationOptions = false;
      appState.showPickupOptions = false;
      Navigator.pop(context);
    }
  }

  String get _headerTitle {
    if (widget.returnResult) return widget.text;
    switch (widget.text) {
      case 'De':
        return 'Local de Recolha';
      case 'Para':
        return 'Local de Destino';
      default:
        return 'Paragem';
    }
  }

  IconData get _headerIcon {
    switch (widget.text) {
      case 'De':
        return Icons.trip_origin;
      case 'Para':
        return Icons.flag_rounded;
      default:
        return Icons.add_location_alt_rounded;
    }
  }

  // ── Map Widget ──
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center!,
        initialZoom: 15,
        onPositionChanged: (position, _) {
          _getPlaceInfo(position.center);
        },
        onTap: (a, latLng) async {
          _mapController.move(latLng, _mapController.camera.zoom);
          _getPlaceInfo(latLng);
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token",
        ),
      ],
    );
  }

  // ── Location Info ──
  Widget _buildLocationInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with icon
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: const Color(0xffe5a400).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _headerIcon,
                color: const Color(0xffe5a400),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.sp),
            Text(
              _headerTitle,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        // Divider
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.withAlpha(60),
                Colors.grey.withAlpha(20),
                Colors.transparent,
              ],
            ),
          ),
        ),
        SizedBox(height: 10.sp),
        // Location details
        if (_currentChoice.isNotEmpty)
          Container(
            padding: EdgeInsets.all(12.sp),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.sp),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    LocationService.iconForPlace(_currentChoice["type"]),
                    size: 20.sp,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentChoice["name"],
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.sp),
                      Text(
                        _currentChoice["fullName"],
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (_currentChoice.isEmpty && !_isLoading)
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.sp, horizontal: 12.sp),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 20.sp,
                  color: Colors.grey,
                ),
                SizedBox(width: 10.sp),
                Text(
                  'Arrasta o mapa para escolher',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        if (_isLoading && _currentChoice.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.sp, horizontal: 12.sp),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 18.sp,
                  width: 18.sp,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xffe5a400),
                    ),
                  ),
                ),
                SizedBox(width: 10.sp),
                Text(
                  'A localizar...',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Confirm Button ──
  Widget _buildConfirmButton() {
    final bool canConfirm = _currentChoice.isNotEmpty && !_isLoading;

    return GestureDetector(
      onTap: canConfirm ? _confirmLocation : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: canConfirm
              ? const Color(0xffe5a400)
              : Colors.grey.withAlpha(80),
          borderRadius: BorderRadius.circular(30),
          boxShadow: canConfirm
              ? [
                  BoxShadow(
                    color: const Color(0xffe5a400).withAlpha(80),
                    spreadRadius: 0,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.sp),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  height: 20.sp,
                  width: 20.sp,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Confirmar localização',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    color: canConfirm ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),

          // Pointer fixo no centro
          Center(
            child: Transform.translate(
              offset: Offset(0, -30.sp),
              child: _buildPointer(),
            ),
          ),

          // Top bar with back button and instruction
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.sp,
            left: 14.sp,
            right: 14.sp,
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(10.sp),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      size: 22.sp,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Spacer(),
                // Instruction chip
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.sp,
                    vertical: 10.sp,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        size: 16.sp,
                        color: const Color(0xffe5a400),
                      ),
                      SizedBox(width: 6.sp),
                      Text(
                        'Arrasta o mapa',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Invisible spacer to balance layout
                SizedBox(width: 42.sp),
              ],
            ),
          ),

          // Bottom panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.sp, 16.sp, 20.sp, 24.sp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 14.sp),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  _buildLocationInfo(),
                  SizedBox(height: 18.sp),
                  _buildConfirmButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pointer card
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.05);
            return Transform.scale(
              scale: _isLoading ? scale : 1.0,
              child: child,
            );
          },
          child: Container(
            padding: _isLoading
                ? EdgeInsets.all(10.sp)
                : EdgeInsets.all(6.sp),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20.sp,
                    width: 20.sp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xffe5a400),
                      ),
                    ),
                  )
                : Image.asset(AssetPaths.chooseMap, height: 24.sp),
          ),
        ),
        // Pin line
        Container(
          width: 2,
          height: 26.sp,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black87,
                Colors.black.withAlpha(40),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        // Pin dot
        Container(
          width: 8.sp,
          height: 8.sp,
          decoration: BoxDecoration(
            color: const Color(0xffe5a400),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xffe5a400).withAlpha(80),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
