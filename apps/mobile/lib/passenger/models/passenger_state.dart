import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/firebase_auth_repository.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';
import 'package:limousineexecutive/services/pricing_service.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/repositories/firebase_trip_repository.dart';

class PassengerState extends ChangeNotifier {
  late final ITripRepository _tripRepository;
  late final IAuthRepository _authRepository;

  PassengerState({
    ITripRepository? repository,
    IAuthRepository? auth,
    bool simulateLoading = true,
  }) : _tripRepository = repository ?? FirebaseTripRepository(),
       _authRepository = auth ?? FirebaseAuthRepository(),
       _isLoadingVehicles = simulateLoading {
    if (simulateLoading) {
      // Simulate initial loading for vehicle types and other data to show skeletons
      Future.delayed(const Duration(milliseconds: 1500), () {
        _isLoadingVehicles = false;
        notifyListeners();
      });
    }
  }

  // State variables
  bool _isLoadingVehicles;
  bool get isLoadingVehicles => _isLoadingVehicles;

  // {
  // 'name':
  // 'fullName':
  // 'type':
  // 'latlong'
  // }
  List<Map<String, dynamic>> _stops = []; // List of stop points
  LatLng? _currentLocation; // Current location
  LatLng? _destinationLocation; // Destination location
  LatLng? _originLocation; // Origin location
  String _fromAddress = ''; // Origin address
  String _toAddress = ''; // Destination address
  String _selectedCar = ""; // Selected car
  int? _selectedCarIndex; // Selected car index
  String? _selectedCategoryId; // Pricing category id (config-driven selector)
  String _selectedCarType = ""; // Selected car type
  int? _selectedCarTypeindex; // Selected car type index
  double _estimatedPrice = 0; // Estimated price
  PricingResult? _cachedPricing; // Last server-calculated price
  bool _priceFromFallback = false; // True when local fallback was used
  bool _showRoute = false; // controls whether to show the route
  String? _paymentMethod = '';
  bool _isPaymentSelected = false;
  String? currentTripId; // Active trip ID in Firebase
  String _tripStatus =
      ''; // pending, accepted, in_progress, completed, cancelled
  bool _isSearching = false; // replaces showTemporary
  StreamSubscription<Map<String, dynamic>?>? _tripSubscription;
  double _distanceKm = 0; // distance km
  int _durationMin = 0; // Duration in min
  LatLng? _driverLocation; // For tracking the driver
  double _driverAngle = 0; // For driver vehicle orientation
  StreamSubscription<Map<String, dynamic>?>? _driverSubscription;
  bool _hasTriggeredArrival =
      false; // Prevents multiple haptics for the same arrival
  List<Map<String, dynamic>> _onlineDrivers = []; // All available drivers
  StreamSubscription<List<Map<String, dynamic>>>? _onlineDriversSubscription;
  FocusNode focusNodePickup = FocusNode();
  FocusNode focusNodeDestination = FocusNode();
  TextEditingController controllerPickup = TextEditingController();
  TextEditingController controllerDestination = TextEditingController();
  List<Map<String, dynamic>> favoriteCars = []; // List of favorite cars
  String _driverName = '';
  String _driverPhotoUrl = '';
  Map<String, dynamic>? _driverVehicle; // To store vehicle details

  bool _newScheduleCreated =
      false; // to blink the button to see the created schedule

  bool _showPickupOptions = false;
  bool _showDestinationOptions = false;
  bool _blinkDestinationField = false;

  // Default list of addresses
  List<Map<String, dynamic>> _address = [
    {
      "name": "Aeroporto de Maputo",
      "fullName": "Maputo, Kamubukwana, Aeroporto",
      "latlong": const LatLng(-25.9218, 32.5734),
      'type': "airport",
    },
    {
      "name": "Estádio Nacional do Zimpeto",
      "fullName": "Maputo, Kamubukwana, Zimpeto",
      "latlong": const LatLng(-25.82761, 32.57498),
      'type': "stadium",
    },
    {
      "name": "Praça da Independência",
      "fullName": "Maputo, Kanfumo, Bairro Central C",
      "latlong": const LatLng(-25.9692, 32.5732),
      'type': "park",
    },
    {
      "name": "Shopping Maputo",
      "fullName": "Maputo, Kalhamanhulo, Bairro Central A",
      "latlong": const LatLng(-25.9685, 32.5796),
      'type': "supermarket",
    },
    {
      "name": "Universidade Eduardo Mondlane",
      "fullName": "Maputo, Kamubukwana, Sommershield",
      "latlong": const LatLng(-25.9605, 32.5833),
      'type': "university",
    },
  ];

  // List of created schedules
  // {
  //  'fromAddress': appState.toAddress,
  //  'originLocation': appState.originLocation,
  //  'toAddress': appState.toAddress,
  //  'destinationLocation': appState.destinationLocation,
  //  'selectedCar': car["name"]!,
  //  'selectedCarIndex': i,
  //  'selectedCarType': appState.selectedCarType,
  //  'selectedCarTypeIndex': appState.selectedCarTypeindex,
  //  'paymentMethod': metodo,
  //  'isPaymentSelected': true,
  //  'stops': appState.stops,
  //  'time': timeSchedule,
  //  'car': car, //Map<String, String>{{
  //     "name": "Mazda 4x4",
  //     "img": AssetPaths.mazda,
  //     "status": "free",
  //     "plate": "MZ4 701 MC",
  //     "seats": "5",
  // },}
  // }
  final List<Map<String, dynamic>> _agendas = [];

  // Getters
  List<Map<String, dynamic>> get stops => _stops;
  LatLng? get currentLocation => _currentLocation;
  LatLng? get destinationLocation => _destinationLocation;
  LatLng? get originLocation => _originLocation;
  String get fromAddress => _fromAddress;
  String get toAddress => _toAddress;
  String get selectedCar => _selectedCar;
  int? get selectedCarIndex => _selectedCarIndex;
  String get selectedCarType => _selectedCarType;
  int? get selectedCarTypeindex => _selectedCarTypeindex;
  double get estimatedPrice => _estimatedPrice;
  PricingResult? get cachedPricing => _cachedPricing;
  bool get priceFromFallback => _priceFromFallback;
  bool get showRoute => _showRoute;
  String? get paymentMethod => _paymentMethod;
  bool get isPaymentSelected => _isPaymentSelected;
  double get distanceKm => _distanceKm;
  int get durationMin => _durationMin;
  bool get showPickupOptions => _showPickupOptions;
  bool get showDestinationOptions => _showDestinationOptions;
  List<Map<String, dynamic>> get address => _address;
  List<Map<String, dynamic>> get agendas => _agendas;
  bool get newScheduleCreated => _newScheduleCreated;
  bool get blinkDestinationField => _blinkDestinationField;
  String get tripStatus => _tripStatus;
  bool get isSearching => _isSearching;
  LatLng? get driverLocation => _driverLocation;
  double get driverAngle => _driverAngle;
  List<Map<String, dynamic>> get onlineDrivers => _onlineDrivers;
  String get driverName => _driverName;
  String get driverPhotoUrl => _driverPhotoUrl;

  @override
  void dispose() {
    focusNodePickup.dispose();
    focusNodeDestination.dispose();
    _tripSubscription?.cancel();
    _driverSubscription?.cancel();
    _onlineDriversSubscription?.cancel();
    super.dispose();
  }

  set stops(List<Map<String, dynamic>> tempStops) {
    _stops = tempStops;
    notifyListeners();
  }

  // Setter
  set currentLocation(LatLng? location) {
    _currentLocation = location;
    notifyListeners();
  }

  set destinationLocation(LatLng? location) {
    _destinationLocation = location;
    notifyListeners();
  }

  set originLocation(LatLng? location) {
    _originLocation = location;
    notifyListeners();
  }

  set fromAddress(String address) {
    _fromAddress = address;
    notifyListeners();
  }

  set toAddress(String address) {
    _toAddress = address;
    notifyListeners();
  }

  set selectedCar(String car) {
    _selectedCar = car;
    notifyListeners();
  }

  set selectedCarIndex(int? index) {
    _selectedCarIndex = index;
    notifyListeners();
  }

  /// Selecção vinda do seletor config-driven: guarda o id de pricing
  /// directamente (não depende do label, que vem de /config e pode variar).
  void selectCategory(String id, String label, int index) {
    _selectedCategoryId = id;
    _selectedCarType = label;
    _selectedCarTypeindex = index;
    _selectedCarIndex = null;
    notifyListeners();
  }

  set selectedCarType(String carType) {
    if (carType.isEmpty) _selectedCategoryId = null;
    _selectedCarType = carType;
    notifyListeners();
    // The category multiplier changes the fare, so refresh the estimate.
    if (_distanceKm > 0) fetchServerPrice();
  }

  set selectedCarTypeindex(int? index) {
    _selectedCarTypeindex = index;
    notifyListeners();
  }

  set estimatedPrice(double price) {
    _estimatedPrice = price;
    notifyListeners();
  }

  /// Fetches the server-side price and caches it. Call after route distance/duration are set.
  /// Falls back to a client-side computation (same formula) when the server is unreachable —
  /// [priceFromFallback] then becomes true so the UI can warn that the price is an estimate.
  /// Pricing category derived from the selected showcase car type.
  String get carCategory =>
      _selectedCategoryId ?? CarData.categoryFor(_selectedCarType);

  Future<void> fetchServerPrice({TripType tripType = TripType.regular}) async {
    if (_distanceKm <= 0) return;
    final String category = carCategory;
    try {
      final result = await PricingService.calculate(
        tripType: tripType,
        distanceKm: _distanceKm,
        durationMinutes: _durationMin.toDouble(),
        category: category,
      );
      _cachedPricing = result;
      _estimatedPrice = result.totalAmount;
      _priceFromFallback = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Server price fetch failed, using local fallback: $e');
      await PricingService.fetchCategories().catchError((_) => kDefaultCategories);
      final fallback = PricingService.computeLocal(
        tripType: tripType,
        distanceKm: _distanceKm,
        durationMinutes: _durationMin.toDouble(),
        category: category,
      );
      _cachedPricing = fallback;
      _estimatedPrice = fallback.totalAmount;
      _priceFromFallback = true;
      notifyListeners();
    }
  }

  set showRoute(bool show) {
    _showRoute = show;
    notifyListeners();
  }

  set paymentMethod(String? method) {
    _paymentMethod = method;
    notifyListeners();
  }

  set isPaymentSelected(bool selected) {
    _isPaymentSelected = selected;
    notifyListeners();
  }

  set distanceKm(double distance) {
    _distanceKm = distance;
    notifyListeners();
  }

  set durationMin(int duration) {
    _durationMin = duration;
    notifyListeners();
  }

  set showPickupOptions(bool value) {
    _showPickupOptions = value;
    notifyListeners();
  }

  set showDestinationOptions(bool value) {
    _showDestinationOptions = value;
    notifyListeners();
  }

  set address(List<Map<String, dynamic>> newAddress) {
    _address = newAddress;
    notifyListeners();
  }

  set newScheduleCreated(bool status) {
    _newScheduleCreated = status;
    notifyListeners();
  }

  set blinkDestinationField(bool blink) {
    _blinkDestinationField = blink;
    notifyListeners();
  }

  set tripStatus(String status) {
    _tripStatus = status;
    notifyListeners();
  }

  set isSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }

  void listenToTrip(String tripId) {
    _tripSubscription?.cancel();
    _tripSubscription = _tripRepository.watchTrip(tripId).listen((trip) {
      if (trip != null) {
        final newStatus = trip['status'] ?? '';

        // HAPTIC FEEDBACK: TRIP ACCEPTED
        if (newStatus == 'accepted' && _tripStatus != 'accepted') {
          HapticFeedback.mediumImpact();
        }

        _tripStatus = newStatus;
        _isSearching = (_tripStatus == 'pending');

        if (_tripStatus == 'cancelled' || _tripStatus == 'completed') {
          _isPaymentSelected = false; // Fecha o bottom sheet
          _paymentMethod = '';
          _isSearching = false;
          _stopListeningToDriver();
        } else if (_tripStatus == 'accepted' || _tripStatus == 'started') {
          final driverUid = trip['driver']?.toString();
          if (driverUid != null) {
            _startListeningToDriver(driverUid);
            _fetchDriverProfile(driverUid);
          }
        } else {
          // Reset arrival trigger when trip ends or is pending
          _hasTriggeredArrival = false;
        }
        notifyListeners();
      }
    });
  }

  void _startListeningToDriver(String driverUid) {
    _driverSubscription?.cancel();
    _driverSubscription = _tripRepository.watchDriverLocation(driverUid).listen(
      (loc) {
        if (loc != null) {
          final newLocation = LatLng(
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble(),
          );

          // Calculate rotation fallback if driver is moving
          if (_driverLocation != null && _driverLocation != newLocation) {
            _driverAngle = _calculateBearing(_driverLocation!, newLocation);
          } else {
            _driverAngle = (loc['angle'] as num?)?.toDouble() ?? _driverAngle;
          }

          _driverLocation = newLocation;

          // HAPTIC FEEDBACK: DRIVER ARRIVING (Distance < 200 meters)
          if (!_hasTriggeredArrival &&
              _tripStatus == 'accepted' &&
              _originLocation != null) {
            final distance = const Distance().as(
              LengthUnit.Meter,
              _originLocation!,
              newLocation,
            );
            if (distance < 200) {
              _hasTriggeredArrival = true;
              HapticFeedback.heavyImpact(); // Strong tactile notification
              // Optional: Short vibration pattern for extra attention
              SystemChannels.platform.invokeMethod('HapticFeedback.vibrate');
            }
          }

          notifyListeners();
        }
      },
    );
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lon1 = start.longitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final lon2 = end.longitude * pi / 180;

    final dLon = lon2 - lon1;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    return atan2(y, x);
  }

  Map<String, dynamic>? get driverVehicle => _driverVehicle;

  /// Calculates the estimated trip price based on distance and price per KM.
  /// Centralised here so UI widgets don't contain business logic.
  double calculatePrice({required double pricePerKM}) {
    return _distanceKm * pricePerKM;
  }

  void _stopListeningToDriver() {
    _driverSubscription?.cancel();
    _driverSubscription = null;
    _driverLocation = null;
    _driverAngle = 0;
    _driverName = '';
    _driverPhotoUrl = '';
    _driverVehicle = null;
  }

  void _fetchDriverProfile(String driverUid) {
    _tripRepository.watchProfile(driverUid).first.then((profile) {
      if (profile != null) {
        _driverName = profile['name']?.toString() ?? 'Motorista';
        _driverPhotoUrl = profile['photoUrl']?.toString() ?? '';
        _driverVehicle = profile['vehicle'] as Map<String, dynamic>?;
        notifyListeners();
      }
    });
  }

  /// Veículos REAIS disponíveis na categoria: motoristas online e livres
  /// cujo veículo (registado pelo parceiro no painel e espelhado em
  /// users/{uid}/vehicle) pertence à categoria seleccionada.
  Future<List<Map<String, dynamic>>> availableVehicles(String category) async {
    final drivers =
        _onlineDrivers.where((d) => d['busy'] != true).toList();
    final results = await Future.wait(
      drivers.map((d) async {
        final uid = d['uid']?.toString();
        if (uid == null) return null;
        final profile = await _tripRepository.watchProfile(uid).first;
        final vehicle = profile?['vehicle'];
        if (profile == null || vehicle is! Map) return null;
        if ((vehicle['category'] ?? 'economico').toString() != category) {
          return null;
        }
        return <String, dynamic>{
          'driverUid': uid,
          'driverName': profile['name']?.toString() ?? 'Motorista',
          'driverPhotoUrl': profile['photoUrl']?.toString() ?? '',
          'name': vehicle['model']?.toString() ?? 'Veículo',
          'plate': vehicle['plate']?.toString() ?? '',
          'seats': vehicle['seats']?.toString() ?? '4',
          'category': category,
          'photoUrl': vehicle['photoUrl']?.toString(),
        };
      }),
    );
    return results.whereType<Map<String, dynamic>>().toList();
  }

  /// Contagem de veículos disponíveis por categoria — usado para mostrar a
  /// oferta real logo na grelha de categorias (à semelhança do Uber/Bolt),
  /// em vez de deixar o passageiro escolher uma categoria vazia e só depois
  /// descobrir que não há oferta.
  Future<Map<String, int>> availableVehicleCountsByCategory() async {
    final drivers = _onlineDrivers.where((d) => d['busy'] != true).toList();
    final categories = await Future.wait(
      drivers.map((d) async {
        final uid = d['uid']?.toString();
        if (uid == null) return null;
        final profile = await _tripRepository.watchProfile(uid).first;
        final vehicle = profile?['vehicle'];
        if (profile == null || vehicle is! Map) return null;
        return (vehicle['category'] ?? 'economico').toString();
      }),
    );
    final counts = <String, int>{};
    for (final category in categories.whereType<String>()) {
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  }

  void listenToOnlineDrivers() {
    _onlineDriversSubscription?.cancel();
    _onlineDriversSubscription = _tripRepository.watchOnlineDrivers().listen((
      drivers,
    ) {
      _onlineDrivers = drivers;
      notifyListeners();
    });
  }

  void stopListeningToOnlineDrivers() {
    _onlineDriversSubscription?.cancel();
    _onlineDriversSubscription = null;
    _onlineDrivers = [];
    notifyListeners();
  }

  // ///////////// others

  // Adds a new schedule to the list
  void addAgenda(Map<String, dynamic> agenda) {
    _newScheduleCreated = true;
    _agendas.add(agenda);
    _tripRepository.createSchedule(
      _authRepository.currentUser?.uid ?? '',
      agenda,
    );

    notifyListeners();
  }

  // Remove a specific stop (by index)
  Map<String, dynamic>? removeAgendaAt(int index) {
    Map<String, dynamic>? r;
    if (index >= 0 && index < _agendas.length) {
      r = _agendas[index];
      _agendas.removeAt(index);
      notifyListeners();
    }
    return r;
  }

  void rescheduleAgendaAt({required int index, required DateTime time}) {
    if (index >= 0 && index < _agendas.length) {
      _agendas[index]['time'] = time;
      notifyListeners();
    }
  }

  Future<void> cancelAgenda(String scheduleId) async {
    final uid = _authRepository.currentUser?.uid ?? '';
    if (uid.isEmpty || scheduleId.isEmpty) return;
    await _tripRepository.deleteSchedule(uid, scheduleId);
  }

  Future<void> rescheduleAgenda(String scheduleId, DateTime time) async {
    final uid = _authRepository.currentUser?.uid ?? '';
    if (uid.isEmpty || scheduleId.isEmpty) return;
    await _tripRepository.updateSchedule(uid, scheduleId, {'time': time});
  }

  // Add a new stop to the list
  void addStop(Map<String, dynamic> stop) {
    _stops.add(stop);
    notifyListeners();
  }

  // Insert a new stop at a specific index
  void insertStop(int index, Map<String, dynamic> stop) {
    if (index >= 0) {
      _stops.insert(index, stop);
      notifyListeners();
    }
  }

  // Remove a specific stop (by index)
  Map<String, dynamic>? removeStopAt(int index) {
    Map<String, dynamic>? r;
    if (index >= 0 && index < _stops.length) {
      r = _stops[index];
      _stops.removeAt(index);
      notifyListeners();
    }
    return r;
  }

  // Remove a specific stop (by content)
  void removeStop(Map<String, dynamic> stop) {
    _stops.remove(stop);
    notifyListeners();
  }

  // Replaces the entire list with a new one
  void setStops(List<Map<String, dynamic>> newStops) {
    _stops = List.from(newStops);
    notifyListeners();
  }

  // Clears the list
  void clearStops() {
    _stops.clear();
    notifyListeners();
  }

  // Add a car to the favorites list
  void addFavorite(Map<String, dynamic> car) {
    if (!isFavorite(car['name'])) {
      favoriteCars.add(car);
      notifyListeners();
    }
  }

  // Remove a car
  void removeFavorite(String carName) {
    favoriteCars.removeWhere((c) => c['name'] == carName);
    notifyListeners();
  }

  // Check if car is a favourite
  bool isFavorite(String carName) {
    return favoriteCars.any((c) => c['name'] == carName);
  }

  /// Restores the passenger's trip state from Firebase data after an app restart.
  /// Called from the splash screen when an active trip is found.
  void restoreActiveTrip(String tripId, Map<String, dynamic> tripData) {
    final status = tripData['status']?.toString() ?? '';

    // Parse origin coordinates and address
    final origin = tripData['origin'] as Map?;
    if (origin != null) {
      _originLocation = LatLng(
        (origin['lat'] as num).toDouble(),
        (origin['lng'] as num).toDouble(),
      );
      _fromAddress = origin['name']?.toString() ?? 'Origem';
      controllerPickup.text = _fromAddress;
    }

    // Parse destination coordinates and address
    final destination = tripData['destination'] as Map?;
    if (destination != null) {
      _destinationLocation = LatLng(
        (destination['lat'] as num).toDouble(),
        (destination['lng'] as num).toDouble(),
      );
      _toAddress = destination['name']?.toString() ?? 'Destino';
      controllerDestination.text = _toAddress;
    }

    // Parse stops
    final stops = tripData['stops'];
    if (stops is List) {
      _stops = stops.map((s) => Map<String, dynamic>.from(s as Map)).toList();
    }

    // Restore trip metadata
    currentTripId = tripId;
    _tripStatus = status;
    _estimatedPrice = (tripData['estimatedPrice'] as num?)?.toDouble() ?? 0;
    _paymentMethod = tripData['paymentMethod']?.toString() ?? '';
    _isPaymentSelected = _paymentMethod?.isNotEmpty == true;
    _isSearching = (status == 'pending');
    _showRoute = (status == 'accepted' || status == 'started');

    // Start listening to trip updates
    listenToTrip(tripId);

    // If already accepted/started, try to listen to driver immediately
    final driverUid = tripData['driver']?.toString();
    if (driverUid != null && (status == 'accepted' || status == 'started')) {
      _startListeningToDriver(driverUid);
      _fetchDriverProfile(driverUid);
    }

    notifyListeners();
    debugPrint("TRIP RESTORED: $tripId (status: $status)");
  }
}
