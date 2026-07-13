abstract class ITripRepository {
  /// Create a new trip request
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
  });

  /// Listen to a specific trip's updates
  Stream<Map<String, dynamic>?> watchTrip(String tripId);

  /// Listen to a driver's location updates
  Stream<Map<String, dynamic>?> watchDriverLocation(String driverUid);

  /// Listen to all online drivers
  Stream<List<Map<String, dynamic>>> watchOnlineDrivers();

  /// Get/Listen a user's profile data
  Stream<Map<String, dynamic>?> watchProfile(String uid);

  /// Update profile fields
  Future<void> updateProfile(String uid, Map<String, dynamic> fields);

  /// Create a scheduled trip
  Future<void> createSchedule(String uid, Map<String, dynamic> agenda);

  /// Delete a scheduled trip
  Future<void> deleteSchedule(String uid, String scheduleId);

  /// Get all scheduled trips for a user
  Stream<List<Map<String, dynamic>>> readSchedules(String uid);

  /// Update a scheduled trip
  Future<void> updateSchedule(String uid, String scheduleId, Map<String, dynamic> data);

  /// Driver: Accept a trip request
  Future<void> acceptTrip(String tripId, String driverUid);

  /// Generic update for trip status
  Future<void> updateTripStatus(String tripId, String status);

  /// Driver: Update current location and orientation
  Future<void> updateLocation(String uid, double lat, double lng, double angle);

  /// Driver: Set online/offline status
  Future<void> setOnlineStatus(String uid, bool online);

  /// FCM Token management
  Future<void> saveFcmToken(String uid, String token);

  /// History: Read trips for passenger
  Stream<List<Map<String, dynamic>>> readTripsByPassenger(String uid);

  /// History: Read trips for driver
  Stream<List<Map<String, dynamic>>> readTripsByDriver(String uid);

  /// Chat: Send message
  Future<void> sendMessage(String tripId, String senderId, String senderType, String text);

  /// Chat: Listen to messages
  Stream<List<Map<String, dynamic>>> listenToMessages(String tripId);

  /// Chat: Mark messages as read
  Future<void> markMessagesAsRead(String tripId, String currentUserUid);

  /// Discovery: Find an active trip for a driver
  Future<Map<String, dynamic>?> findActiveTripForDriver(String uid);

  /// Discovery: Find an active trip for a passenger
  Future<Map<String, dynamic>?> findActiveTripForPassenger(String uid);
}
