import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../../partner/data/mock_partner_data.dart';
import '../../partner/data/mock_types.dart';
import '../repositories/partner_data_repository.dart';

class FirebasePartnerDataRepository implements PartnerDataRepository {
  FirebasePartnerDataRepository({required this.partnerId});

  @override
  final String partnerId;

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference get _partnerRef => _db.child('partners/$partnerId');

  @override
  Future<MockPartnerProfile> partnerProfile() async {
    final DataSnapshot snap = await _partnerRef.get();
    final Map<String, dynamic> map =
        snap.exists ? _snapshotValueMap(snap) : <String, dynamic>{};
    final DataSnapshot fleetSnap = await _partnerRef.child('fleet/name').get();
    final Map<String, dynamic> payout = _mapValue(map['payout']) ?? <String, dynamic>{};
    final Map<String, dynamic> notificationPrefs =
        _mapValue(map['notificationPrefs']) ?? <String, dynamic>{};
    return MockPartnerProfile(
      id: partnerId,
      name: _string(map, 'name') ?? '',
      city: _string(map, 'city') ?? '',
      nuit: _string(map, 'nuit') ?? '',
      email: _string(map, 'email') ?? '',
      phone: _string(map, 'phone') ?? '',
      fleetName: (fleetSnap.value as String?) ?? 'Frota',
      status: _string(map, 'status') ?? 'active',
      payoutMethod: _string(payout, 'method') ?? 'none',
      payoutMpesaNumber: _string(payout, 'mpesaNumber'),
      payoutIban: _string(payout, 'iban'),
      broadcastsEnabled: _bool(notificationPrefs, 'broadcastsEnabled') ?? true,
    );
  }

  @override
  Future<List<MockPartnerStaff>> listStaff() async {
    final DataSnapshot indexSnap = await _partnerRef.child('staff').get();
    final Map<String, dynamic> index = _snapshotValueMap(indexSnap);
    final Map<String, Map<String, dynamic>> users =
        await _fetchUsers(index.keys.toList());
    return index.entries.map((MapEntry<String, dynamic> entry) {
      final Map<String, dynamic> user = users[entry.key] ?? <String, dynamic>{};
      return MockPartnerStaff(
        id: entry.key,
        name: _string(user, 'name') ?? _string(user, 'email') ?? 'Sem nome',
        email: _string(user, 'email') ?? '',
        role: entry.value is String
            ? entry.value as String
            : 'partner_staff',
      );
    }).toList()
      ..sort((MockPartnerStaff a, MockPartnerStaff b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<MockDriver>> listDrivers() async {
    final DataSnapshot indexSnap = await _partnerDriversRef.get();
    final Map<String, Map<String, dynamic>> users =
        await _fetchUsers(_driverUidsFromIndex(indexSnap));
    final DataSnapshot driverStateSnap = await _db.child('drivers').get();
    return _driversFromUsers(users, driverStateSnap);
  }

  @override
  Stream<List<MockDriver>> watchDrivers() {
    late final StreamController<List<MockDriver>> controller;
    StreamSubscription<DatabaseEvent>? indexSub;
    StreamSubscription<DatabaseEvent>? driverStateSub;
    Map<String, Map<String, dynamic>> users = <String, Map<String, dynamic>>{};
    DataSnapshot? driverStateSnap;

    void emit() {
      if (controller.isClosed) return;
      controller.add(_driversFromUsers(users, driverStateSnap));
    }

    // The partner's driver set lives at /partners/{pid}/drivers (an index the
    // owner can read), not via a /users collection query — so a partner owner
    // never needs read access to other partners' users. We fan out to each
    // /users/{uid} (readable per-uid) when the index changes.
    Future<void> refreshUsers(DataSnapshot indexSnap) async {
      final Map<String, Map<String, dynamic>> fetched =
          await _fetchUsers(_driverUidsFromIndex(indexSnap));
      if (controller.isClosed) return;
      users = fetched;
      emit();
    }

    controller = StreamController<List<MockDriver>>(
      onListen: () {
        indexSub = _partnerDriversRef.onValue.listen(
          (DatabaseEvent event) {
            refreshUsers(event.snapshot);
          },
          onError: controller.addError,
        );
        driverStateSub = _db.child('drivers').onValue.listen(
          (DatabaseEvent event) {
            driverStateSnap = event.snapshot;
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await indexSub?.cancel();
        await driverStateSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<MockDriver?> driverById(String id) async {
    final List<MockDriver> drivers = await listDrivers();
    for (final MockDriver driver in drivers) {
      if (driver.id == id) return driver;
    }
    return null;
  }

  @override
  Future<List<MockVehicle>> listVehicles() async {
    final DataSnapshot snap = await _partnerRef.child('vehicles').get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _vehicleFromMap(entry.key, entry.value);
    }).toList();
  }

  @override
  Stream<List<MockVehicle>> watchVehicles() {
    return _partnerRef.child('vehicles').onValue.map((DatabaseEvent event) {
      return _snapshotEntries(event.snapshot)
          .map((MapEntry<String, Map<String, dynamic>> entry) {
        return _vehicleFromMap(entry.key, entry.value);
      }).toList();
    });
  }

  @override
  Future<MockVehicle?> vehicleById(String id) async {
    final DataSnapshot snap = await _partnerRef.child('vehicles/$id').get();
    if (!snap.exists) return null;
    return _vehicleFromMap(id, _snapshotValueMap(snap));
  }

  @override
  Future<String> createVehicle({
    required String plate,
    required String model,
    required String type,
    required int year,
    required int seats,
  }) async {
    final DatabaseReference ref = _partnerRef.child('vehicles').push();
    await ref.set(<String, dynamic>{
      'plate': plate,
      'model': model,
      'type': type,
      'year': year,
      'seats': seats,
      'status': 'available',
      'odometerKm': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return ref.key!;
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    await _partnerRef.update(fields);
  }

  @override
  Future<void> updateVehicle(String id, Map<String, dynamic> fields) async {
    await _partnerRef.child('vehicles/$id').update(fields);
  }

  @override
  Future<void> deleteVehicle(String id) async {
    await _partnerRef.child('vehicles/$id').remove();
  }

  @override
  Future<List<MockTrip>> listTrips() async {
    final DataSnapshot snap = await _db
        .child('trips')
        .orderByChild('partnerId')
        .equalTo(partnerId)
        .get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _tripFromMap(entry.key, entry.value);
    }).toList()
      ..sort((MockTrip a, MockTrip b) => b.startedAt.compareTo(a.startedAt));
  }

  @override
  Future<List<MockTrip>> tripsByDriver(String driverId) async {
    final List<MockTrip> trips = await listTrips();
    return trips.where((MockTrip trip) => trip.driverId == driverId).toList();
  }

  @override
  Future<List<MockTrip>> tripsByVehicle(String vehicleId) async {
    final List<MockTrip> trips = await listTrips();
    return trips.where((MockTrip trip) => trip.vehicleId == vehicleId).toList();
  }

  @override
  Future<MockTrip?> tripById(String id) async {
    final DataSnapshot snap = await _db.child('trips/$id').get();
    if (!snap.exists) return null;
    final Map<String, dynamic> map = _snapshotValueMap(snap);
    if (_string(map, 'partnerId') != partnerId) return null;
    return _tripFromMap(id, map);
  }

  @override
  Future<List<MockAlert>> listAlerts() async {
    final DataSnapshot snap = await _db
        .child('alerts')
        .orderByChild('partnerId')
        .equalTo(partnerId)
        .get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _alertFromMap(entry.key, entry.value);
    }).toList()
      ..sort((MockAlert a, MockAlert b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<MockAlert>> criticalAlerts() async {
    final List<MockAlert> alerts = await listAlerts();
    return alerts
        .where(
          (MockAlert alert) => alert.severity == MockAlertSeverity.critical,
        )
        .toList();
  }

  @override
  Future<List<MockDocument>> listDocuments() async {
    final List<MockDocument> documents = <MockDocument>[];
    documents.addAll(
      await _documentsForOwner(MockDocumentOwnerType.partner, partnerId),
    );
    for (final MockDriver driver in await listDrivers()) {
      documents.addAll(
        await _documentsForOwner(MockDocumentOwnerType.driver, driver.id),
      );
    }
    for (final MockVehicle vehicle in await listVehicles()) {
      documents.addAll(
        await _documentsForOwner(MockDocumentOwnerType.vehicle, vehicle.id),
      );
    }
    return documents;
  }

  @override
  Future<List<MockMaintenance>> maintenancesByVehicle(String vehicleId) async {
    final DataSnapshot snap =
        await _partnerRef.child('vehicles/$vehicleId/maintenances').get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _maintenanceFromMap(entry.key, vehicleId, entry.value);
    }).toList();
  }

  @override
  Future<List<MockRating>> ratingsByDriver(String driverId) async {
    final DataSnapshot snap = await _db
        .child('ratings')
        .orderByChild('driverId')
        .equalTo(driverId)
        .get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _ratingFromMap(entry.key, driverId, entry.value);
    }).toList();
  }

  @override
  Future<List<MockEarningsTransaction>> earningsTransactions() async {
    final DataSnapshot snap = await _db.child('payouts/$partnerId').get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _earningsFromMap(entry.key, entry.value);
    }).toList()
      ..sort(
        (MockEarningsTransaction a, MockEarningsTransaction b) =>
            b.date.compareTo(a.date),
      );
  }

  @override
  Future<List<MockIncentive>> incentives() async {
    final DataSnapshot snap = await _db.child('incentives').get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _incentiveFromMap(entry.key, entry.value);
    }).toList();
  }

  @override
  Future<List<MockMessageThread>> messageThreads() async {
    final DataSnapshot snap = await _db
        .child('messages')
        .orderByChild('partnerId')
        .equalTo(partnerId)
        .get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _threadFromMap(entry.key, entry.value);
    }).toList()
      ..sort(
        (MockMessageThread a, MockMessageThread b) =>
            b.updatedAt.compareTo(a.updatedAt),
      );
  }

  @override
  Stream<List<MockChatMessage>> watchThreadMessages(String threadId) {
    return _db
        .child('messages/$threadId/messages')
        .onValue
        .map((DatabaseEvent event) {
      final List<MockChatMessage> msgs = _snapshotEntries(event.snapshot)
          .map((MapEntry<String, Map<String, dynamic>> entry) {
        final Map<String, dynamic> m = entry.value;
        final String from =
            _string(m, 'from') ?? _string(m, 'author') ?? '';
        return MockChatMessage(
          id: entry.key,
          text: _string(m, 'text') ?? '',
          fromPartner: from == partnerId,
          timestamp: _date(m['timestamp']) ??
              _date(m['createdAt']) ??
              DateTime.now(),
        );
      }).toList()
        ..sort(
          (MockChatMessage a, MockChatMessage b) =>
              a.timestamp.compareTo(b.timestamp),
        );
      return msgs;
    });
  }

  @override
  Future<void> sendThreadMessage(String threadId, String text) async {
    final String now = DateTime.now().toIso8601String();
    final String key =
        _db.child('messages/$threadId/messages').push().key ?? now;
    // Single multi-path write at the thread level so the security rules see the
    // partner in participantUids on the same update.
    await _db.child('messages/$threadId').update(<String, dynamic>{
      'messages/$key': <String, dynamic>{
        'from': partnerId,
        'to': '',
        'text': text,
        'timestamp': now,
        'role': 'partner',
      },
      'lastMessage': text,
      'updatedAt': now,
      'participantUids/$partnerId': true,
    });
  }

  DatabaseReference get _partnerDriversRef => _partnerRef.child('drivers');

  List<String> _driverUidsFromIndex(DataSnapshot indexSnap) {
    return _snapshotValueMap(indexSnap)
        .entries
        .where((MapEntry<String, dynamic> entry) => entry.value == true)
        .map((MapEntry<String, dynamic> entry) => entry.key)
        .toList();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUsers(
    List<String> uids,
  ) async {
    final Map<String, Map<String, dynamic>> users =
        <String, Map<String, dynamic>>{};
    await Future.wait(
      uids.map((String uid) async {
        final DataSnapshot snap = await _db.child('users/$uid').get();
        if (snap.exists) users[uid] = _snapshotValueMap(snap);
      }),
    );
    return users;
  }

  List<MockDriver> _driversFromUsers(
    Map<String, Map<String, dynamic>> users,
    DataSnapshot? driverStateSnap,
  ) {
    final Map<String, dynamic> driverState = driverStateSnap == null
        ? <String, dynamic>{}
        : _snapshotValueMap(driverStateSnap);

    return users.entries
        .where((MapEntry<String, Map<String, dynamic>> entry) {
      return _string(entry.value, 'type') == 'driver';
    }).map((MapEntry<String, Map<String, dynamic>> entry) {
      final Map<String, dynamic> state =
          _mapValue(driverState[entry.key]) ?? <String, dynamic>{};
      return _driverFromMap(entry.key, entry.value, state);
    }).toList()
      ..sort((MockDriver a, MockDriver b) => a.name.compareTo(b.name));
  }

  Future<List<MockDocument>> _documentsForOwner(
    MockDocumentOwnerType ownerType,
    String ownerId,
  ) async {
    final String ownerKey = ownerType.name;
    final DataSnapshot snap =
        await _db.child('documents/$ownerKey/$ownerId').get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _documentFromMap(entry.key, ownerType, ownerId, entry.value);
    }).toList();
  }

  MockDriver _driverFromMap(
    String uid,
    Map<String, dynamic> user,
    Map<String, dynamic> state,
  ) {
    return MockDriver(
      id: uid,
      name: _string(user, 'name') ?? _string(user, 'phone') ?? 'Sem nome',
      phone: _string(user, 'phone') ?? '',
      email: _string(user, 'email') ?? '',
      status: _driverStatus(
        _string(user, 'driverStatus') ?? _string(user, 'status'),
      ),
      online: _bool(user, 'online') ?? _bool(state, 'online') ?? false,
      vehicleId: _string(user, 'vehicleId') ?? _string(state, 'vehicleId'),
      rating: _double(user, 'rating') ?? 0,
      ratingsCount:
          _int(user, 'ratingCount') ?? _int(user, 'ratingsCount') ?? 0,
      tripsCount: _int(user, 'tripsCount') ?? 0,
      totalEarningsMtn: _int(user, 'totalEarningsMtn') ?? 0,
      joinedAt: _date(user['createdAt']) ?? DateTime.now(),
    );
  }

  MockVehicle _vehicleFromMap(String id, Map<String, dynamic> map) {
    return MockVehicle(
      id: id,
      plate: _string(map, 'plate') ?? '',
      type: _string(map, 'type') ?? 'Sedan',
      model: _string(map, 'model') ?? '',
      status: _vehicleStatus(_string(map, 'status')),
      driverId: _string(map, 'driverId'),
      year: _int(map, 'year') ?? DateTime.now().year,
      seats: _int(map, 'seats') ?? 5,
      odometerKm: _int(map, 'odometerKm') ?? _int(map, 'odometer') ?? 0,
    );
  }

  MockTrip _tripFromMap(String id, Map<String, dynamic> map) {
    final int amount = _int(map, 'amountMtn') ??
        _int(map, 'amount') ??
        _int(map, 'estimatedPrice') ??
        0;
    return MockTrip(
      id: id,
      driverId: _string(map, 'driverId') ?? _string(map, 'driver') ?? '',
      vehicleId: _string(map, 'vehicleId') ?? '',
      passengerName:
          _string(map, 'passengerName') ?? _string(map, 'passenger') ?? '',
      origin: _placeName(map['origin']),
      destination: _placeName(map['destination']),
      amountMtn: amount,
      partnerNetMtn: _int(map, 'partnerNetMtn') ?? (amount * 0.88).round(),
      distanceKm: _double(map, 'distanceKm') ?? _double(map, 'distance') ?? 0,
      durationMinutes:
          _int(map, 'durationMinutes') ?? _int(map, 'duration') ?? 0,
      status: _tripStatus(_string(map, 'status')),
      startedAt: _date(map['startedAt']) ??
          _date(map['createdAt']) ??
          _date(map['updatedAt']) ??
          DateTime.now(),
      offeredAt: _date(map['offeredAt']),
      acceptedAt: _date(map['acceptedAt']),
    );
  }

  MockAlert _alertFromMap(String id, Map<String, dynamic> map) {
    return MockAlert(
      id: id,
      title: _string(map, 'title') ?? '',
      description: _string(map, 'description') ?? '',
      severity: _alertSeverity(_string(map, 'severity')),
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      driverId: _string(map, 'driverId'),
      vehicleId: _string(map, 'vehicleId'),
    );
  }

  MockDocument _documentFromMap(
    String id,
    MockDocumentOwnerType ownerType,
    String ownerId,
    Map<String, dynamic> map,
  ) {
    return MockDocument(
      id: id,
      ownerType: ownerType,
      ownerId: ownerId,
      title: _string(map, 'title') ?? _string(map, 'type') ?? 'Documento',
      status: _documentStatus(_string(map, 'status')),
      expiresAt: _date(map['expiresAt']),
    );
  }

  MockMaintenance _maintenanceFromMap(
    String id,
    String vehicleId,
    Map<String, dynamic> map,
  ) {
    return MockMaintenance(
      id: id,
      vehicleId: vehicleId,
      title: _string(map, 'title') ?? 'Manutencao',
      scheduledAt: _date(map['scheduledAt']) ?? DateTime.now(),
      costMtn: _int(map, 'costMtn') ?? _int(map, 'cost') ?? 0,
      completed: _bool(map, 'completed') ?? false,
    );
  }

  MockRating _ratingFromMap(
    String id,
    String driverId,
    Map<String, dynamic> map,
  ) {
    return MockRating(
      id: id,
      driverId: driverId,
      tripId: _string(map, 'tripId') ?? '',
      value: _int(map, 'value') ?? _int(map, 'rating') ?? 0,
      comment: _string(map, 'comment') ?? '',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
    );
  }

  MockEarningsTransaction _earningsFromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return MockEarningsTransaction(
      id: id,
      label: _string(map, 'label') ?? _string(map, 'description') ?? 'Payout',
      amountMtn: _int(map, 'amountMtn') ?? _int(map, 'amount') ?? 0,
      status: _transactionStatus(_string(map, 'status')),
      date: _date(map['date']) ?? _date(map['createdAt']) ?? DateTime.now(),
    );
  }

  MockIncentive _incentiveFromMap(String id, Map<String, dynamic> map) {
    return MockIncentive(
      id: id,
      title: _string(map, 'title') ?? '',
      target: _string(map, 'target') ?? '',
      rewardMtn: _int(map, 'rewardMtn') ?? _int(map, 'reward') ?? 0,
      progress: _double(map, 'progress') ?? 0,
      status: _incentiveStatus(_string(map, 'status')),
      endsAt: _date(map['endsAt']) ?? DateTime.now(),
    );
  }

  MockMessageThread _threadFromMap(String id, Map<String, dynamic> map) {
    return MockMessageThread(
      id: id,
      subject: _string(map, 'subject') ?? _string(map, 'title') ?? '',
      participant:
          _string(map, 'participant') ?? _string(map, 'assignedTo') ?? 'YA',
      lastMessage: _string(map, 'lastMessage') ?? '',
      unreadCount: _int(map, 'unreadCount') ?? 0,
      updatedAt:
          _date(map['updatedAt']) ?? _date(map['createdAt']) ?? DateTime.now(),
    );
  }

  List<MapEntry<String, Map<String, dynamic>>> _snapshotEntries(
    DataSnapshot snapshot,
  ) {
    final Map<String, dynamic> map = _snapshotValueMap(snapshot);
    return map.entries.map((MapEntry<String, dynamic> entry) {
      return MapEntry<String, Map<String, dynamic>>(
        entry.key,
        _mapValue(entry.value) ?? <String, dynamic>{},
      );
    }).toList();
  }

  Map<String, dynamic> _snapshotValueMap(DataSnapshot snapshot) {
    return _mapValue(snapshot.value) ?? <String, dynamic>{};
  }

  Map<String, dynamic>? _mapValue(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  String? _string(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    return value is String ? value : null;
  }

  bool? _bool(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    return value is bool ? value : null;
  }

  int? _int(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _double(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  DateTime? _date(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is num) {
      final int raw = value.toInt();
      final int millis = raw < 100000000000 ? raw * 1000 : raw;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }

  String _placeName(Object? value) {
    final Map<String, dynamic>? map = _mapValue(value);
    if (map != null) {
      return _string(map, 'name') ??
          _string(map, 'address') ??
          _string(map, 'label') ??
          '';
    }
    return value is String ? value : '';
  }

  MockDriverStatus _driverStatus(String? raw) {
    return switch (raw) {
      'pending' => MockDriverStatus.pending,
      'suspended' || 'blocked' => MockDriverStatus.suspended,
      _ => MockDriverStatus.active,
    };
  }

  MockVehicleStatus _vehicleStatus(String? raw) {
    return switch (raw) {
      'busy' || 'in_trip' => MockVehicleStatus.busy,
      'maintenance' => MockVehicleStatus.maintenance,
      _ => MockVehicleStatus.available,
    };
  }

  MockTripStatus _tripStatus(String? raw) {
    return switch (raw) {
      'pending' => MockTripStatus.pending,
      'accepted' => MockTripStatus.accepted,
      'started' => MockTripStatus.started,
      'cancelled' || 'canceled' => MockTripStatus.cancelled,
      _ => MockTripStatus.completed,
    };
  }

  MockAlertSeverity _alertSeverity(String? raw) {
    return switch (raw) {
      'critical' || 'danger' => MockAlertSeverity.critical,
      'warning' => MockAlertSeverity.warning,
      _ => MockAlertSeverity.info,
    };
  }

  MockDocumentStatus _documentStatus(String? raw) {
    return switch (raw) {
      'approved' || 'ok' => MockDocumentStatus.ok,
      'expiring_soon' || 'expiringSoon' => MockDocumentStatus.expiringSoon,
      'expired' => MockDocumentStatus.expired,
      _ => MockDocumentStatus.missing,
    };
  }

  MockTransactionStatus _transactionStatus(String? raw) {
    return switch (raw) {
      'pending' => MockTransactionStatus.pending,
      'failed' || 'rejected' => MockTransactionStatus.failed,
      _ => MockTransactionStatus.paid,
    };
  }

  MockIncentiveStatus _incentiveStatus(String? raw) {
    return switch (raw) {
      'scheduled' => MockIncentiveStatus.scheduled,
      'ended' || 'finished' => MockIncentiveStatus.ended,
      _ => MockIncentiveStatus.active,
    };
  }
}
