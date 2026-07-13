import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'trip_repository.dart';

dynamic _sanitize(dynamic v) {
  if (v is LatLng) return {'lat': v.latitude, 'lng': v.longitude};
  if (v is DateTime) return v.toIso8601String();
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), _sanitize(val)));
  }
  if (v is Iterable) return v.map(_sanitize).toList();
  return v;
}

class FirebaseTripRepository implements ITripRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

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
    final now = DateTime.now().toIso8601String();
    final newTrip = _db.child("trips").push();
    await newTrip.set(
      _sanitize({
        "passenger": passengerUid,
        "driver": null,
        "origin": origin,
        "destination": destination,
        "stops": stops ?? [],
        "estimatedPrice": estimatedPrice,
        "paymentMethod": paymentMethod,
        "tripType": tripType,
        "tipo": tripType,
        "status": status,
        if (carCategory != null) "carCategory": carCategory,
        // Route estimate from Mapbox; the backoffice panel reports on these.
        if (distanceKm != null) "distanceKm": distanceKm,
        if (durationMinutes != null) "durationMinutes": durationMinutes,
        // Flat timestamp read by the backoffice panel; the nested `timestamps`
        // map is kept for the notification triggers.
        "createdAt": now,
        "timestamps": {"created": now},
      }),
    );
    return newTrip.key!;
  }

  @override
  Stream<Map<String, dynamic>?> watchTrip(String tripId) {
    return _db.child("trips/$tripId").onValue.map((event) {
      if (!event.snapshot.exists) return null;
      final v = Map<String, dynamic>.from(event.snapshot.value as Map);
      v["id"] = tripId;
      return v;
    });
  }

  @override
  Stream<Map<String, dynamic>?> watchDriverLocation(String driverUid) {
    return _db.child("drivers/$driverUid/location").onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchOnlineDrivers() {
    return _db
        .child("drivers")
        .orderByChild("online")
        .equalTo(true)
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return [];
          return data.entries.map((e) {
            final val = Map<String, dynamic>.from(e.value as Map);
            val["uid"] = e.key;
            return val;
          }).toList();
        });
  }

  @override
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _db.child("users/$uid").onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {
    await _db.child("users/$uid").update(fields);
  }

  @override
  Future<void> createSchedule(String uid, Map<String, dynamic> agenda) async {
    final newSchedule = _db.child("schedules/$uid").push();
    await newSchedule.set(
      _sanitize({...agenda, "id": newSchedule.key, "status": "scheduled"}),
    );
  }

  @override
  Future<void> deleteSchedule(String uid, String scheduleId) async {
    await _db.child("schedules/$uid/$scheduleId").remove();
  }

  @override
  Stream<List<Map<String, dynamic>>> readSchedules(String uid) {
    return _db.child("schedules/$uid").onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((e) {
        if (e.value is! Map) return <String, dynamic>{};
        final a = Map<String, dynamic>.from(e.value as Map);
        a["id"] = e.key;
        return a;
      }).toList();
    });
  }

  @override
  Future<void> updateSchedule(String uid, String scheduleId, Map<String, dynamic> data) async {
    await _db.child("schedules/$uid/$scheduleId").update(_sanitize(data));
  }

  @override
  Future<void> acceptTrip(String tripId, String driverUid) async {
    final now = DateTime.now().toIso8601String();

    // B2B model: stamp the driver's partner/vehicle and the passenger name onto
    // the trip so the backoffice panel can attribute it without extra lookups.
    final driverSnap = await _db.child("users/$driverUid").get();
    final driver = driverSnap.value as Map?;
    final partnerId = driver?["partnerId"];
    final vehicleId = driver?["vehicleId"];

    final passengerSnap = await _db.child("trips/$tripId/passenger").get();
    final passengerUid = passengerSnap.value?.toString();
    String? passengerName;
    if (passengerUid != null && passengerUid.isNotEmpty) {
      final nameSnap = await _db.child("users/$passengerUid/name").get();
      final name = nameSnap.value?.toString();
      if (name != null && name.isNotEmpty) passengerName = name;
    }

    final updates = <String, dynamic>{
      "driver": driverUid,
      "driverId": driverUid,
      "status": "accepted",
      "acceptedAt": now,
      "updatedAt": now,
      "timestamps/accepted": now,
    };
    if (partnerId != null) updates["partnerId"] = partnerId;
    if (vehicleId != null) updates["vehicleId"] = vehicleId;
    if (passengerName != null) updates["passengerName"] = passengerName;

    await _db.child("trips/$tripId").update(updates);
    await _db.child("drivers/$driverUid").update({"busy": true});
  }

  @override
  Future<void> updateTripStatus(String tripId, String status) async {
    final now = DateTime.now().toIso8601String();
    await _db.child("trips/$tripId").update({
      "status": status,
      "updatedAt": now,
      "${status}At": now,
      "timestamps/$status": now,
    });

    if (status == "completed") {
      await _stampCompletionFinancials(tripId);
    }
  }

  /// On completion, persist the amounts the panel reports on and update the
  /// driver's running totals. Distance/duration come from the Mapbox route
  /// estimate stamped at creation, so only the monetary fields are stamped here.
  Future<void> _stampCompletionFinancials(String tripId) async {
    final snap = await _db.child("trips/$tripId").get();
    final trip = snap.value as Map?;
    if (trip == null) return;
    // Idempotent: if already stamped (e.g. a double "complete" tap), don't
    // increment the driver's totals again.
    if (trip["partnerNetMtn"] != null) return;

    final amount = (trip["estimatedPrice"] as num?)?.round() ?? 0;
    final tipo = (trip["tipo"] ?? trip["tripType"] ?? "regular").toString();
    final partnerNet = (amount * (1 - _commissionFor(tipo))).round();

    await _db.child("trips/$tripId").update({
      "amountMtn": amount,
      "partnerNetMtn": partnerNet,
    });

    final driverUid = (trip["driver"] ?? trip["driverId"])?.toString();
    if (driverUid != null && driverUid.isNotEmpty) {
      await _db.child("users/$driverUid").update({
        "tripsCount": ServerValue.increment(1),
        "totalEarningsMtn": ServerValue.increment(partnerNet),
      });
    }
  }

  /// YA platform commission per trip type, mirroring functions/src/pricing.ts.
  double _commissionFor(String tipo) {
    switch (tipo) {
      case "scheduled":
        return 0.10;
      case "airport":
        return 0.15;
      case "event":
        return 0.10;
      default:
        return 0.12;
    }
  }

  @override
  Future<void> updateLocation(String uid, double lat, double lng, double angle) async {
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return;
    if (lat == 0.0 && lng == 0.0) return;
    await _db.child("drivers/$uid/location").set({
      "lat": lat,
      "lng": lng,
      "angle": angle,
      "updatedAt": DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> setOnlineStatus(String uid, bool online) async {
    final ref = _db.child("drivers/$uid");
    await ref.update({"online": online});
    if (online) {
      await ref.child("online").onDisconnect().set(false);
    }
  }

  @override
  Future<void> saveFcmToken(String uid, String token) async {
    await _db.child("users/$uid/fcmToken").set(token);
  }

  @override
  Stream<List<Map<String, dynamic>>> readTripsByPassenger(String uid) {
    return _db.child("trips").orderByChild("passenger").equalTo(uid).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((e) {
        if (e.value is! Map) return <String, dynamic>{};
        final v = Map<String, dynamic>.from(e.value as Map);
        v["id"] = e.key;
        return v;
      }).toList();
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> readTripsByDriver(String uid) {
    return _db.child("trips").orderByChild("driver").equalTo(uid).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((e) {
        if (e.value is! Map) return <String, dynamic>{};
        final v = Map<String, dynamic>.from(e.value as Map);
        v["id"] = e.key;
        return v;
      }).toList();
    });
  }

  @override
  Future<void> sendMessage(String tripId, String senderId, String senderType, String text) async {
    final messageRef = _db.child("chats/$tripId/messages").push();
    await messageRef.set({
      "senderId": senderId,
      "senderType": senderType,
      "text": text,
      "timestamp": DateTime.now().toIso8601String(),
      "read": false,
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> listenToMessages(String tripId) {
    return _db.child("chats/$tripId/messages").orderByChild("timestamp").onValue.map((event) {
      final Map<dynamic, dynamic>? values = event.snapshot.value as Map?;
      if (values == null) return [];
      final List<Map<String, dynamic>> messages = [];
      values.forEach((key, value) {
        messages.add(Map<String, dynamic>.from(value as Map)..addAll({"id": key}));
      });
      messages.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));
      return messages;
    });
  }

  @override
  Future<void> markMessagesAsRead(String tripId, String currentUserUid) async {
    final snapshot = await _db.child("chats/$tripId/messages").get();
    if (snapshot.exists) {
      final messages = snapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};
      messages.forEach((key, value) {
        final msg = Map<String, dynamic>.from(value as Map);
        if (msg['senderId'] != currentUserUid && msg['read'] == false) {
          updates["chats/$tripId/messages/$key/read"] = true;
        }
      });
      if (updates.isNotEmpty) {
        await _db.update(updates);
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> findActiveTripForDriver(String uid) async {
    final snapshot = await _db.child("trips").orderByChild("driver").equalTo(uid).once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return null;
    const activeStatuses = {'accepted', 'started'};
    for (final entry in data.entries) {
      if (entry.value is! Map) continue;
      final trip = Map<String, dynamic>.from(entry.value as Map);
      final status = trip['status']?.toString() ?? '';
      if (activeStatuses.contains(status)) {
        trip['id'] = entry.key;
        return trip;
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> findActiveTripForPassenger(String uid) async {
    final snapshot = await _db.child("trips").orderByChild("passenger").equalTo(uid).once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return null;
    const activeStatuses = {'pending', 'accepted', 'started'};
    for (final entry in data.entries) {
      if (entry.value is! Map) continue;
      final trip = Map<String, dynamic>.from(entry.value as Map);
      final status = trip['status']?.toString() ?? '';
      if (activeStatuses.contains(status)) {
        trip['id'] = entry.key;
        return trip;
      }
    }
    return null;
  }
}
