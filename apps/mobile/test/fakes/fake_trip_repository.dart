import 'package:limousineexecutive/repositories/trip_repository.dart';

class FakeTripRepository implements ITripRepository {
  final Map<String, List<Map<String, dynamic>>> _schedules = {};
  final Map<String, Map<String, dynamic>> _trips = {};
  int createScheduleCallCount = 0;

  @override
  Future<String> createTrip({
    required String passengerUid,
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    required double estimatedPrice,
    required String paymentMethod,
    List<Map<String, dynamic>>? stops,
    String tripType = 'regular',
    double? distanceKm,
    double? durationMinutes,
    String status = 'pending',
    String? carCategory,
  }) async {
    return 'fake_trip_id';
  }

  @override
  Stream<Map<String, dynamic>?> watchTrip(String tripId) => Stream.value(_trips[tripId]);

  @override
  Stream<Map<String, dynamic>?> watchDriverLocation(String driverUid) => const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> watchOnlineDrivers() => Stream.value([]);

  @override
  Stream<Map<String, dynamic>?> watchProfile(String uid) => Stream.value(null);

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {}

  @override
  Future<void> createSchedule(String uid, Map<String, dynamic> data) async {
    createScheduleCallCount++;
    _schedules.putIfAbsent(uid, () => []).add(Map.from(data));
  }

  @override
  Future<void> deleteSchedule(String uid, String scheduleId) async {
    _schedules[uid]?.removeWhere((s) => s['id'] == scheduleId);
  }

  @override
  Stream<List<Map<String, dynamic>>> readSchedules(String uid) {
    return Stream.value([]);
  }

  @override
  Future<void> updateSchedule(String uid, String scheduleId, Map<String, dynamic> data) async {
    final list = _schedules[uid];
    if (list != null) {
      final index = list.indexWhere((s) => s['id'] == scheduleId);
      if (index != -1) {
        list[index].addAll(data);
      }
    }
  }

  @override
  Future<void> acceptTrip(String tripId, String driverUid) async {
    _trips[tripId]?['status'] = 'accepted';
    _trips[tripId]?['driver'] = driverUid;
  }

  @override
  Future<void> updateTripStatus(String tripId, String status) async {
    _trips[tripId]?['status'] = status;
  }

  @override
  Future<void> setOnlineStatus(String uid, bool online) async {}

  @override
  Future<void> updateLocation(String uid, double lat, double lng, double angle) async {}

  @override
  Future<void> saveFcmToken(String uid, String token) async {}

  @override
  Stream<List<Map<String, dynamic>>> readTripsByPassenger(String uid) => Stream.value([]);

  @override
  Stream<List<Map<String, dynamic>>> readTripsByDriver(String uid) => Stream.value([]);

  @override
  Future<void> sendMessage(String tripId, String senderId, String senderType, String text) async {}

  @override
  Stream<List<Map<String, dynamic>>> listenToMessages(String tripId) => Stream.value([]);

  @override
  Future<void> markMessagesAsRead(String tripId, String currentUserUid) async {}

  @override
  Future<Map<String, dynamic>?> findActiveTripForPassenger(String uid) async {
    for (final entry in _trips.entries) {
      final trip = entry.value;
      if (trip['passenger'] == uid &&
          {'pending', 'accepted', 'started'}.contains(trip['status'])) {
        return {...trip, 'id': entry.key};
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> findActiveTripForDriver(String uid) async {
    for (final entry in _trips.entries) {
      final trip = entry.value;
      if (trip['driver'] == uid &&
          {'accepted', 'started'}.contains(trip['status'])) {
        return {...trip, 'id': entry.key};
      }
    }
    return null;
  }

  void addTrip(String id, Map<String, dynamic> data) {
    _trips[id] = data;
  }
}
