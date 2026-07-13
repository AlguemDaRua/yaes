import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/driver/components/dialogs/unaccepted_trip_dialog.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/repositories/firebase_trip_repository.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/firebase_auth_repository.dart';
import 'package:limousineexecutive/services/wallet_service.dart';

class DriverState extends ChangeNotifier {
  Color mainColor = Colors.amber.withValues(alpha: 0.59);

  final ITripRepository _tripRepository;
  final IAuthRepository _authRepository;

  DriverState({ITripRepository? repository, IAuthRepository? auth}) 
    : _tripRepository = repository ?? FirebaseTripRepository(),
      _authRepository = auth ?? FirebaseAuthRepository();

  LatLng? _currentLocation;
  LatLng? _originLocation;
  LatLng? _destinationLocation;
  double _vehicleAngle = 0;
  bool _isOnline = false;
  bool _isOnTrip = false;
  bool _isRinging = false;
  bool _isTripStarted = false;
  bool _showRoute = false;
  String? _currentTripId;
  Map<String, dynamic>? _currentTripData;
  StreamSubscription? _tripSubscription;
  DriverWallet? _wallet;
  StreamSubscription? _profileSubscription;
  StreamSubscription? _walletSubscription;

  // Getters
  LatLng? get currentLocation => _currentLocation;
  LatLng? get originLocation => _originLocation;
  LatLng? get destinationLocation => _destinationLocation;
  double get vehicleAngle => _vehicleAngle;
  bool get isOnline => _isOnline;
  bool get isOnTrip => _isOnTrip;
  bool get isRinging => _isRinging;
  bool get isTripStarted => _isTripStarted;
  bool get showRoute => _showRoute;
  String? get currentTripId => _currentTripId;
  Map<String, dynamic>? get currentTripData => _currentTripData;
  DriverWallet? get wallet => _wallet;

  /// Bloqueado por dívida de comissão (carteira YA Direct) — não pode
  /// ficar online até recarregar. Ver functions/src/wallet.ts.
  bool get isWalletBlocked => _wallet?.isBlocked ?? false;

  // Setters
  void setCurrentLocation(LatLng? location) {
    _currentLocation = location;
    notifyListeners();
  }

  void setOriginLocation(LatLng? location) {
    _originLocation = location;
    notifyListeners();
  }

  void setDestinationLocation(LatLng? location) {
    _destinationLocation = location;
    notifyListeners();
  }

  void setAngle(double angle) {
    _vehicleAngle = angle;
    notifyListeners();
  }

  void setIsOnline(bool status) {
    // Gate de carteira: com dívida acima do limite o motorista não fica
    // online (a UI mostra o aviso; aqui é a salvaguarda de estado).
    if (status && isWalletBlocked) {
      _isOnline = false;
      notifyListeners();
      return;
    }
    _isOnline = status;
    notifyListeners();

    // Publish status to Firebase
    final uid = _authRepository.currentUser?.uid;
    if (uid != null) {
      _tripRepository.setOnlineStatus(uid, status);
    }
  }

  /// Observa a carteira de comissão do motorista (perfil → partnerId →
  /// /driverWallets). Idempotente; chamada ao entrar na home do motorista.
  void startWalletWatch() {
    final uid = _authRepository.currentUser?.uid;
    if (uid == null || _profileSubscription != null) return;

    String? watchedPartnerId;
    _profileSubscription =
        _tripRepository.watchProfile(uid).listen((profile) {
      final partnerId = profile?['partnerId']?.toString();
      if (partnerId == watchedPartnerId) return;
      watchedPartnerId = partnerId;
      _walletSubscription?.cancel();
      _walletSubscription = null;
      if (partnerId == null || partnerId.isEmpty) {
        _wallet = null;
        notifyListeners();
        return;
      }
      _walletSubscription =
          WalletService.watch(partnerId, uid).listen((wallet) {
        _wallet = wallet;
        // Se ficou bloqueado enquanto online, tira-o de circulação.
        if (isWalletBlocked && _isOnline && !_isOnTrip) {
          setIsOnline(false);
        } else {
          notifyListeners();
        }
      });
    });
  }

  void setIsOnTrip(bool status) {
    _isOnTrip = status;
    notifyListeners();
  }

  void setIsRinging(bool status) {
    _isRinging = status;
    notifyListeners();
  }

  void setIsTripStarted(bool status) {
    _isTripStarted = status;
    notifyListeners();
  }

  void setShowRoute(bool status) {
    _showRoute = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    _profileSubscription?.cancel();
    _walletSubscription?.cancel();
    super.dispose();
  }

  void showUnacceptDialog(BuildContext context) {
    showUnacceptedDialog(context);
  }

  Future<void> acceptTrip() async {
    final tripId = _currentTripId;
    final uid = _authRepository.currentUser?.uid;
    if (tripId == null || uid == null) return;

    _isRinging = false;
    _isOnTrip = true; // Set this TRUE immediately to show the next modal
    notifyListeners();

    try {
      HapticFeedback.mediumImpact().catchError((_) {});
    } catch (_) {}
    
    try {
      await _tripRepository.acceptTrip(tripId, uid);
      _startListeningToTrip(tripId);
    } catch (e) {
      debugPrint("Error accepting trip: $e");
      _isOnTrip = false; // Rollback if it fails
      notifyListeners();
    }
  }

  void _startListeningToTrip(String tripId) {
    _tripSubscription?.cancel();
    _tripSubscription = _tripRepository.watchTrip(tripId).listen((tripData) {
      if (tripData == null) {
        // Only end trip if we already had data before (avoid flicker on initial subscribe)
        if (_currentTripData != null) {
          endTrip();
        }
        return;
      }

      final status = tripData['status']?.toString() ?? '';
      
      // Update local data
      _currentTripData = tripData;

      if (status == 'completed' || status == 'cancelled') {
        endTrip();
      } else {
        _isTripStarted = (status == 'started');
        _isOnTrip = true; // Ensure it stays true
        notifyListeners();
      }
    });
  }

  void endTrip() {
    _isRinging = false;
    _isOnTrip = false;
    _showRoute = false;
    _isTripStarted = false;
    _currentTripId = null;
    _currentTripData = null;
    _originLocation = null;
    _destinationLocation = null;
    _tripSubscription?.cancel();
    _tripSubscription = null;
    notifyListeners();
  }

  /// Handles an incoming trip request ID from FCM by fetching the real data
  Future<void> handleNewTripRequest(String tripId) async {
    // 0. Reset previous state
    _originLocation = null;
    _destinationLocation = null;
    notifyListeners();

    // 1. Fetch trip data
    final trip = await _tripRepository.watchTrip(tripId).first;
    if (trip == null) return;

    // 2. Set coordinates for the map
    final origin = trip['origin'] as Map?;
    final destination = trip['destination'] as Map?;

    if (origin != null) {
      _originLocation = LatLng(
        (origin['lat'] as num).toDouble(),
        (origin['lng'] as num).toDouble(),
      );
    }

    if (destination != null) {
      _destinationLocation = LatLng(
        (destination['lat'] as num).toDouble(),
        (destination['lng'] as num).toDouble(),
      );
    }

    // 3. Update state
    _currentTripId = tripId;
    _currentTripData = trip;
    _isRinging = true;

    // HAPTIC FEEDBACK: NEW TRIP ALERT
    try {
      HapticFeedback.lightImpact().catchError((_) {});
      SystemChannels.platform.invokeMethod('HapticFeedback.vibrate').catchError((_) {});
    } catch (_) {}

    notifyListeners();

    debugPrint("NEW TRIP RECEIVED: $tripId, online: $_isOnline");
  }

  void updateVehicle(LatLng position, double angle) {
    _currentLocation = position;
    _vehicleAngle = angle;
    notifyListeners();

    // Publish location to Firebase in real time
    final uid = _authRepository.currentUser?.uid;
    if (uid != null) {
      _tripRepository.updateLocation(
        uid,
        position.latitude,
        position.longitude,
        angle,
      );
    }
  }

  /// Restores the driver's trip state from Firebase data after an app restart.
  /// Called from the splash screen when an active trip is found.
  void restoreActiveTrip(String tripId, Map<String, dynamic> tripData) {
    final status = tripData['status']?.toString() ?? '';

    // Parse origin coordinates
    final origin = tripData['origin'] as Map?;
    if (origin != null) {
      _originLocation = LatLng(
        (origin['lat'] as num).toDouble(),
        (origin['lng'] as num).toDouble(),
      );
    }

    // Parse destination coordinates
    final destination = tripData['destination'] as Map?;
    if (destination != null) {
      _destinationLocation = LatLng(
        (destination['lat'] as num).toDouble(),
        (destination['lng'] as num).toDouble(),
      );
    }

    // Restore trip state
    _currentTripId = tripId;
    _currentTripData = tripData;
    _isOnTrip = true;
    _isOnline = true;
    _isTripStarted = (status == 'started');
    _isRinging = false;

    _startListeningToTrip(tripId);

    notifyListeners();
    debugPrint("TRIP RESTORED: $tripId (status: $status)");
  }
}
