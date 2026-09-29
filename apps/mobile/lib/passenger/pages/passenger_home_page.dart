import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/components/rate_driver.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/widgets/car_type_selector.dart';
import 'package:limousineexecutive/passenger/widgets/choose_car_sheet.dart';
import 'package:limousineexecutive/passenger/widgets/ride_in_progress_sheet.dart';
import 'package:limousineexecutive/passenger/pages/agendas_page.dart';
import 'package:limousineexecutive/passenger/pages/menu_page.dart';
import 'package:limousineexecutive/services/payment_service.dart';
import 'package:limousineexecutive/services/pricing_service.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/utils/app_config.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/modal_stops.dart';
import 'package:limousineexecutive/utils/asset_paths.dart';
import 'package:limousineexecutive/passenger/components/map_util/pointer_destination.dart';
import 'package:limousineexecutive/utils/blink_widget.dart';
import 'package:limousineexecutive/passenger/controllers/location_controller.dart';
import 'package:limousineexecutive/passenger/controllers/route_controller.dart';
import 'package:limousineexecutive/driver/components/vehicle_marker.dart'; // Import the new widget
import 'package:provider/provider.dart';

class PassengerHomePage extends StatefulWidget {
  const PassengerHomePage({super.key});

  @override
  State<PassengerHomePage> createState() => _PassengerHomePageState();
}

class _PassengerHomePageState extends State<PassengerHomePage>
    with TickerProviderStateMixin {
  // Animated map controller
  late final AnimatedMapController _animatedMapController;

  // Location controller (tracking + GPS)
  late final LocationController _locationController;

  // Route controller (route calculation + selection)
  late final RouteController _routeController;

  // Draggable sheet controller
  late DraggableScrollableController _sheetController;

  // Selected driver for tooltip
  String? _selectedDriverUid;

  // Evita reabrir o diálogo de avaliação em cada rebuild depois de a viagem
  // completar (o Provider notifica em cada mudança de estado da viagem).
  String? _ratingPromptedForTripId;

  String token = AppConfig.mapboxToken;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<PassengerState>(context, listen: false);

    // Initialise the draggable controller
    _sheetController = DraggableScrollableController();

    // Initialise the AnimatedMapController with vsync
    _animatedMapController = AnimatedMapController(vsync: this);

    // Initialise the RouteController
    _routeController = RouteController(
      appState: appState,
      animatedMapController: _animatedMapController,
      token: token,
      contextGetter: () => context,
      vsync: this,
    );
    _routeController.addListener(() => setState(() {}));

    // Initialise the LocationController
    _locationController = LocationController(
      appState: appState,
      animatedMapController: _animatedMapController,
      contextGetter: () => context,
      onLocationUpdated: () => setState(() {}),
    );

    _locationController.getCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if user has a name set
      _checkUserName();

      // Listen to nearby online drivers
      appState.listenToOnlineDrivers();
    });
  }

  @override
  void dispose() {
    final appState = Provider.of<PassengerState>(context, listen: false);
    appState.stopListeningToOnlineDrivers(); // Save data by stopping listener
    _locationController.stopTracking();
    _routeController.dispose();
    super.dispose();
  }

  // Build method
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PassengerState>(context);

    // Viagem concluída: pede avaliação uma única vez por tripId. currentTripId
    // só é limpo depois do diálogo (ver _promptRating), nunca pelo
    // listenToTrip da viagem — por isso ainda está disponível aqui.
    final completedTripId = appState.currentTripId;
    if (appState.tripStatus == 'completed' &&
        completedTripId != null &&
        completedTripId != _ratingPromptedForTripId) {
      _ratingPromptedForTripId = completedTripId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptRating(completedTripId);
      });
    }

    // Desktop panel width

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        final currentFocus = FocusScope.of(context);

        // If a field has focus → unfocus and don't close app
        if (currentFocus.hasFocus) {
          currentFocus.unfocus();
          return;
        }

        if ((appState.showDestinationOptions || appState.showPickupOptions)) {
          appState.showDestinationOptions = false;
          appState.showPickupOptions = false;
          return;
        }

        // if car type already chosen but trip request not yet started, go back before selection
        if (appState.selectedCarType.isNotEmpty &&
            appState.selectedCarTypeindex != null &&
            appState.paymentMethod!.isEmpty) {
          appState.selectedCarType = "";
          appState.selectedCarIndex = null;
          return;
        }

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // go back one route
          return;
        }

        // At root → close the app
        _showExitAppDialog(context);
        return;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            /// MAP
            FlutterMap(
              mapController: _animatedMapController.mapController,
              options: MapOptions(
                onTap: (_, __) {
                  FocusScope.of(context).unfocus();
                  appState.showDestinationOptions = false;
                  appState.showPickupOptions = false;
                  setState(() {
                    _selectedDriverUid = null;
                  });
                },
                initialCenter:
                    appState.currentLocation ?? const LatLng(-25.9692, 32.5732),
                initialZoom: 14,
                initialRotation: 0,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom | // simple zoom
                      InteractiveFlag.drag | // map pan
                      InteractiveFlag.doubleTapZoom, // double tap zoom
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token",
                  subdomains: ['a', 'b', 'c'],
                ),

                // All routes in grey
                if (appState.showRoute &&
                    _routeController.routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: List.generate(
                      _routeController.allRoutes.length,
                      (i) {
                        return Polyline(
                          points: List<LatLng>.from(
                            _routeController.allRoutes[i]['points'],
                          ),
                          strokeWidth: 5.0,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                // Selected route in blue (Animated)
                if (appState.showRoute &&
                    _routeController.animatedRoutePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routeController.animatedRoutePoints,
                        strokeWidth: 5.0,
                        color: const Color(0xffe5a400),
                      ),
                    ],
                  ),

                // Online drivers (nearby cars) - Hide them when an active driver is being tracked
                if (appState.onlineDrivers.isNotEmpty && appState.driverLocation == null)
                  AnimatedMarkerLayer(
                    markers: appState.onlineDrivers.map((driver) {
                      final loc = driver['location'] as Map<dynamic, dynamic>?;
                      final lat = (loc?['lat'] as num?)?.toDouble() ?? 0.0;
                      final lng = (loc?['lng'] as num?)?.toDouble() ?? 0.0;
                      final angle = (loc?['angle'] as num?)?.toDouble() ?? 0.0;

                      return AnimatedMarker(
                        key: ValueKey('driver_${driver['uid']}'),
                        point: LatLng(lat, lng),
                        width: 120.w,
                        height: 150.h,
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.linear,
                        builder: (context, animation) {
                          final isSelected =
                              _selectedDriverUid == driver['uid'];

                          final carName =
                              driver['vehicle_name']?.toString() ??
                              driver['car_model']?.toString() ??
                              "Executivo";
                          final rating =
                              (driver['rating'] as num?)?.toDouble() ?? 5.0;

                          return VehicleMarker(
                            angle: angle,
                            size: 35,
                            showTooltip: isSelected,
                            carName: carName,
                            rating: rating,
                            carImage: AssetPaths.rangerover,
                            onTap: () {
                              setState(() {
                                _selectedDriverUid = driver['uid'];
                              });
                            },
                          );
                        },
                      );
                    }).toList(),
                  ),

                // Assigned driver vehicle tracking (during active trip)
                if (appState.driverLocation != null)
                  AnimatedMarkerLayer(
                    markers: [
                      AnimatedMarker(
                        point: appState.driverLocation!,
                        width: 50.sp,
                        height: 50.sp,
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.linear,
                        builder: (context, animation) {
                          return VehicleMarker(
                            angle: appState.driverAngle,
                            size: 38,
                          );
                        },
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    // Stop markers
                    if (appState.showRoute == true && appState.stops.isNotEmpty)
                      ...List.generate(appState.stops.length, (i) {
                        return Marker(
                          alignment: Alignment.center,
                          width: 32.sp,
                          height: 32.sp,
                          point: appState.stops[i]['latlong'],
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(8.sp),
                            child: Image.asset(
                              AssetPaths.stopSign,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }),

                    // Pickup location marker
                    if (appState.originLocation != null)
                      Marker(
                        alignment: Alignment.center,
                        width: 80.sp,
                        height: 80.sp,
                        point: appState.originLocation!,
                        child: Center(
                          child: PulsingCircle(
                            size: 32.sp,
                            child: Center(
                              child: Container(
                                width: 14.sp,
                                height: 14.sp,
                                decoration: const BoxDecoration(
                                  color: Color(0xffe5a400),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Destination marker
                    if (appState.destinationLocation != null &&
                        appState.originLocation != null)
                      Marker(
                        alignment: Alignment.topCenter,
                        width: 120.sp,
                        height: 26.sp,
                        point: appState.destinationLocation!,
                        child: buildDestinationMarker(
                          minutes:
                              (appState.toAddress.isEmpty ||
                                  appState.fromAddress.isEmpty)
                              ? 0
                              : appState.durationMin,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            /// SCHEDULED RIDES BUTTON
            Positioned(
              top: MediaQuery.of(context).padding.top + 10.sp,
              left: 18.sp,
              child: BlinkWidget(
                active: appState.newScheduleCreated,
                child: GestureDetector(
                  onTap: () async {
                    appState.newScheduleCreated =
                        false; // disable blink after opening
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyAgendas(),
                      ),
                    );

                    _routeController.calculateRoute();
                  },
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.sp),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Minhas\nAgendas',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Schedule count indicator
                      Positioned(
                        top: 0,
                        right: 2.sp,
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: Provider.of<ITripRepository>(context, listen: false).readSchedules(
                            Provider.of<IAuthRepository>(context, listen: false).currentUser?.uid ?? '',
                          ),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return Container(
                              padding: EdgeInsets.all(3.sp),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// MENU BUTTON
            Positioned(
              top: MediaQuery.of(context).padding.top + 10.sp,
              right: 18.sp,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PassengerMenuPage(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.menu, color: Colors.black, size: 18.sp),
                ),
              ),
            ),

            /// SWAP ROUTES BUTTON (when car type is selected)
            if ((!appState.focusNodePickup.hasFocus &&
                    !appState.focusNodeDestination.hasFocus) &&
                appState.showRoute == true &&
                appState.selectedCarType.isEmpty)
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.4,
                right: 18.sp,
                child: GestureDetector(
                  onTap: () {
                    _routeController.selectRoute();
                  },
                  child: Container(
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AssetPaths.route,
                      height: MediaQuery.of(context).size.height * 0.03,
                    ),
                  ),
                ),
              ),

            // TEXTFIELDS AND CAR TYPES
            if (
            // !appState.showRoute &&
            appState.selectedCarType.isEmpty && !appState.isPaymentSelected)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: true,
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.only(top: 12.sp),
                      child: CarTypeSelector(
                        onRouteChanged: _routeController.calculateRoute,
                        onStopRequested: () => _searchStop(context),
                        onAnimateSheet: (size) {
                          if (_sheetController.isAttached) {
                            _sheetController.animateTo(
                              size,
                              duration: const Duration(seconds: 1),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

            // CAR SELECTION
            if (!appState.isPaymentSelected
                // && appState.showRoute
                &&
                appState.selectedCarType.isNotEmpty)
              ChooseCarSheet(
                sheetController: _sheetController,
                onRouteChanged: _routeController.calculateRoute,
                onTripRequested: _requestTrip,
                onStopRequested: () => _searchStop(context),
              ),

            // RIDE IN PROGRESS
            if (appState.isPaymentSelected)
              RideInProgressSheet(
                isSearchingDriver: appState.isSearching,
                onRouteChanged: _routeController.calculateRoute,
              ),

            /// Loading overlay (only while _currentLocation is null)
            if (appState.currentLocation == null)
              Container(
                color: Colors.white.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 25.sp),
                      Text(
                        "A localizar-te...",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 20.sp),
                      CircularProgressIndicator(
                        color: Colors.amber.withValues(alpha: 0.59),
                        strokeWidth: 3.sp,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }



  Future<void> _promptRating(String tripId) async {
    await showRateDriverDialog(context, tripId: tripId);
    if (!mounted) return;
    final appState = Provider.of<PassengerState>(context, listen: false);
    // Só limpa se ainda for a mesma viagem (evita apagar um tripId novo caso
    // o passageiro já tenha pedido outra corrida entretanto).
    if (appState.currentTripId == tripId) {
      appState.currentTripId = null;
    }
  }

  void _showExitAppDialog(BuildContext context) {
    showDialog(
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
                "Sair da aplicação",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.sp),
              Text(
                "Tem a certeza de que deseja fechar o Ya?",
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
                      onTap: () {
                        SystemNavigator.pop(animated: true);
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
                            "Sair",
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

  /// Checks if the logged-in user has a name. If not, shows a bottom sheet
  /// prompting them to enter their name.
  Future<void> _checkUserName() async {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final uid = authRepo.currentUser?.uid;
    if (uid == null) return;
 
    final profile = await tripRepo.watchProfile(uid).first;
    final name = profile?['name'] ?? '';

    if (name.toString().trim().isEmpty && mounted) {
      _showNameBottomSheet();
    }
  }

  void _showNameBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.sp, 12.sp, 20.sp, 28.sp),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 18.sp),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Title
                  Text(
                    'Bem-vindo! 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.sp),
                  // Subtitle
                  Text(
                    'Como queres ser chamado?',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 18.sp),
                  // Input field
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor introduz o teu nome';
                      }
                      if (value.trim().length < 2) {
                        return 'O nome deve ter pelo menos 2 letras';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Ex: João Silva',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 14.sp,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withAlpha(18),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14.sp,
                        horizontal: 22.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(600),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(600),
                        borderSide: BorderSide(
                          color: Colors.grey.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(600),
                        borderSide: const BorderSide(
                          color: Color(0xffe5a400),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(600),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(600),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.sp),
                  // Save button
                  GestureDetector(
                    onTap: () async {
                      if (formKey.currentState!.validate()) {
                        final authRepo = Provider.of<IAuthRepository>(context, listen: false);
                        final tripRepo = Provider.of<ITripRepository>(context, listen: false);
                        final uid = authRepo.currentUser?.uid;
                        if (uid != null) {
                          await tripRepo.updateProfile(uid, {
                            'name': nameController.text.trim(),
                          });
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      }
                    },
                    child: Container(
                      height: 54.sp,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xffe5a400),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffe5a400).withAlpha(80),
                            spreadRadius: 0,
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Confirmar',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.sp),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestTrip() async {
    final authRepo = Provider.of<IAuthRepository>(context, listen: false);
    final tripRepo = Provider.of<ITripRepository>(context, listen: false);
    final appState = Provider.of<PassengerState>(context, listen: false);
    final uid = authRepo.currentUser?.uid;

    if (uid == null ||
        appState.originLocation == null ||
        appState.destinationLocation == null) {
      return;
    }
    appState.isSearching = true;

    try {
      // 1. Calculate price server-side (re-validate before creating trip);
      // the local formula is only the offline fallback.
      final category = appState.carCategory;
      PricingResult pricing;
      try {
        pricing = await PricingService.calculate(
          tripType: TripType.regular,
          distanceKm: appState.distanceKm,
          durationMinutes: appState.durationMin.toDouble(),
          category: category,
        );
      } catch (_) {
        pricing = PricingService.computeLocal(
          tripType: TripType.regular,
          distanceKm: appState.distanceKm,
          durationMinutes: appState.durationMin.toDouble(),
          category: category,
        );
      }

      appState.estimatedPrice = pricing.totalAmount;

      // 2. Create trip in Firebase. Digital payments are pre-paid: the trip is
      // held in 'awaiting_payment' (drivers only see 'pending') until the PSP
      // confirms the collection.
      final method = appState.paymentMethod ?? 'cash';
      final isDigital = method == 'mpesa' || method == 'emola';

      final tripId = await tripRepo.createTrip(
        passengerUid: uid,
        origin: {
          'lat': appState.originLocation!.latitude,
          'lng': appState.originLocation!.longitude,
          'name': appState.fromAddress,
        },
        destination: {
          'lat': appState.destinationLocation!.latitude,
          'lng': appState.destinationLocation!.longitude,
          'name': appState.toAddress,
        },
        estimatedPrice: pricing.totalAmount,
        paymentMethod: method,
        stops: appState.stops,
        tripType: 'regular',
        distanceKm: appState.distanceKm,
        durationMinutes: appState.durationMin.toDouble(),
        status: isDigital ? 'awaiting_payment' : 'pending',
        carCategory: category,
      );

      appState.currentTripId = tripId;
      appState.listenToTrip(tripId);

      // 2b. Pre-paid digital flow: charge and wait for confirmation before the
      // trip becomes available to drivers.
      if (isDigital) {
        appState.tripStatus = 'awaiting_payment';
        await PaymentService.initiate(tripId: tripId, method: method);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Confirma o pagamento no teu telemóvel.'),
            ),
          );
        }
        final paid = await _awaitPayment(tripRepo, tripId);
        if (!paid) {
          await tripRepo.updateTripStatus(tripId, 'cancelled');
          if (mounted) {
            appState.isSearching = false;
            appState.tripStatus = 'cancelled';
            appState.currentTripId = null;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pagamento não confirmado. Viagem cancelada.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        // Payment confirmed → release the trip to drivers.
        await tripRepo.updateTripStatus(tripId, 'pending');
      }

      appState.tripStatus = 'pending';
    } catch (e) {
      if (mounted) {
        appState.isSearching = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao solicitar viagem. Tenta novamente.\n$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 3. Wait for acceptance (max 60s)
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted && appState.isSearching) {
        appState.isSearching = false;
        appState.tripStatus = 'cancelled';
        final tripId = appState.currentTripId;
        if (tripId != null) {
          Provider.of<ITripRepository>(context, listen: false)
              .updateTripStatus(tripId, 'cancelled');
          appState.currentTripId = null;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum motorista disponível. Tenta novamente.'),
          ),
        );
      }
    });
  }

  /// Waits for the trip's paymentStatus to settle to 'paid' or 'failed'.
  /// Returns true only when paid; times out (treated as not paid) after 2 min.
  Future<bool> _awaitPayment(ITripRepository tripRepo, String tripId) async {
    try {
      final trip = await tripRepo.watchTrip(tripId).firstWhere((t) {
        final status = t?['paymentStatus'];
        return status == 'paid' || status == 'failed';
      }).timeout(const Duration(seconds: 120));
      return trip?['paymentStatus'] == 'paid';
    } catch (_) {
      return false;
    }
  }

  void _searchStop(BuildContext context) async {
    final appState = Provider.of<PassengerState>(context, listen: false);

    Map<String, dynamic>? stop;

    stop = await showSearchStopModal(context);

    if (stop != null) {
      appState.addStop(stop);
    }
    _routeController.calculateRoute();
  }
}

class PulsingCircle extends StatefulWidget {
  final double size;
  final Widget child;
  const PulsingCircle({super.key, required this.size, required this.child});

  @override
  State<PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<PulsingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3 + (_controller.value * 0.4)),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.05 + (_controller.value * 0.1),
                ),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
