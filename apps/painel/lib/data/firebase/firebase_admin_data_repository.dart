import 'package:firebase_database/firebase_database.dart';

import '../../admin/data/types.dart';
import '../repositories/admin_data_repository.dart';

class FirebaseAdminDataRepository implements AdminDataRepository {
  FirebaseAdminDataRepository();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  @override
  Future<List<AdminPartner>> listPartners() async {
    final DataSnapshot snap = await _db.child('partners').get();
    return _entries(snap).map((entry) {
      return _partnerFromMap(entry.key, entry.value);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<AdminDriver>> listDrivers() async {
    final DataSnapshot usersSnap = await _db.child('users').get();
    final DataSnapshot stateSnap = await _db.child('drivers').get();
    final Map<String, dynamic> driverState = _valueMap(stateSnap);
    return _entries(usersSnap)
        .where((entry) => _string(entry.value, 'type') == 'driver')
        .map((entry) {
      final Map<String, dynamic> state =
          _map(driverState[entry.key]) ?? <String, dynamic>{};
      return _driverFromMap(entry.key, entry.value, state);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<AdminVehicle>> listVehicles() async {
    final List<AdminVehicle> vehicles = <AdminVehicle>[];
    for (final AdminPartner partner in await listPartners()) {
      final DataSnapshot snap =
          await _db.child('partners/${partner.id}/vehicles').get();
      vehicles.addAll(
        _entries(snap).map((entry) {
          return _vehicleFromMap(partner.id, entry.key, entry.value);
        }),
      );
    }
    return vehicles;
  }

  @override
  Future<List<AdminTrip>> listTrips() async {
    final DataSnapshot snap = await _db.child('trips').get();
    return _entries(snap).map((entry) {
      return _tripFromMap(entry.key, entry.value);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<AdminUser>> listUsers() async {
    final DataSnapshot snap = await _db.child('users').get();
    return _entries(snap).map((entry) {
      return _userFromMap(entry.key, entry.value);
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Future<List<AdminFleet>> listFleets() async {
    final List<AdminFleet> fleets = <AdminFleet>[];
    for (final AdminPartner partner in await listPartners()) {
      final DataSnapshot fleetSnap =
          await _db.child('partners/${partner.id}/fleet').get();
      final Map<String, dynamic> fleet = _valueMap(fleetSnap);
      fleets.add(
        AdminFleet(
          id: _string(fleet, 'id') ?? 'fleet-${partner.id}',
          partnerId: partner.id,
          name: _string(fleet, 'name') ?? '${partner.name} Fleet',
          driversCount: partner.driversCount,
          vehiclesCount: partner.vehiclesCount,
        ),
      );
    }
    return fleets;
  }

  @override
  Future<List<AdminDocument>> listDocuments() async {
    final DataSnapshot snap = await _db.child('documents').get();
    final List<AdminDocument> docs = <AdminDocument>[];
    for (final ownerTypeEntry in _entries(snap)) {
      for (final ownerEntry in _entryMap(ownerTypeEntry.value).entries) {
        final Map<String, dynamic> ownerDocs =
            _map(ownerEntry.value) ?? <String, dynamic>{};
        for (final docEntry in ownerDocs.entries) {
          docs.add(
            _documentFromMap(
              docEntry.key,
              ownerTypeEntry.key,
              ownerEntry.key,
              _map(docEntry.value) ?? <String, dynamic>{},
            ),
          );
        }
      }
    }
    return docs;
  }

  @override
  Future<List<AdminPayment>> listPayments() async {
    final DataSnapshot snap = await _db.child('payments').get();
    return _entries(snap).map((entry) {
      return _paymentFromMap(entry.key, entry.value);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<AdminPayout>> listPayouts() async {
    final DataSnapshot snap = await _db.child('payouts').get();
    final List<AdminPayout> payouts = <AdminPayout>[];
    for (final partnerEntry in _entries(snap)) {
      for (final payoutEntry in _entryMap(partnerEntry.value).entries) {
        payouts.add(
          _payoutFromMap(
            payoutEntry.key,
            partnerEntry.key,
            payoutEntry.value,
          ),
        );
      }
    }
    return payouts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<AdminBroadcast>> listBroadcasts() async {
    final DataSnapshot snap = await _db.child('broadcasts').get();
    return _entries(snap).map((entry) {
      final Map<String, dynamic> map = entry.value;
      return AdminBroadcast(
        id: entry.key,
        title: _string(map, 'title') ?? '-',
        body: _string(map, 'body') ?? '',
        audience: _string(map, 'audience') ?? 'all',
        status: _string(map, 'status') ?? 'sent',
        createdAt: _date(map['createdAt']) ?? DateTime.now(),
        sentBy: _string(map, 'sentBy'),
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<AdminAlert>> listAlerts() async {
    final DataSnapshot snap = await _db.child('alerts').get();
    return _entries(snap).map((entry) {
      return _alertFromMap(entry.key, entry.value);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<AdminAuditLog>> listAuditLogs() async {
    final DataSnapshot snap = await _db.child('audit').get();
    return _entries(snap).map((entry) {
      return _auditFromMap(entry.key, entry.value);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<AdminCommission>> listCommissions() async {
    final DataSnapshot snap = await _db.child('commissions').get();
    final List<AdminCommission> rows = <AdminCommission>[];
    for (final partnerEntry in _entries(snap)) {
      for (final commissionEntry in _entryMap(partnerEntry.value).entries) {
        rows.add(
          _commissionFromMap(
            commissionEntry.key,
            partnerEntry.key,
            _map(commissionEntry.value) ?? <String, dynamic>{},
          ),
        );
      }
    }
    return rows;
  }

  @override
  Future<AdminPartner?> partnerById(String id) async {
    final DataSnapshot snap = await _db.child('partners/$id').get();
    if (!snap.exists) return null;
    return _partnerFromMap(id, _valueMap(snap));
  }

  @override
  Future<AdminDriver?> driverById(String id) async {
    final DataSnapshot userSnap = await _db.child('users/$id').get();
    if (!userSnap.exists) return null;
    final DataSnapshot stateSnap = await _db.child('drivers/$id').get();
    return _driverFromMap(id, _valueMap(userSnap), _valueMap(stateSnap));
  }

  @override
  Future<AdminVehicle?> vehicleById(String id) async {
    for (final AdminVehicle vehicle in await listVehicles()) {
      if (vehicle.id == id || vehicle.plate == id) return vehicle;
    }
    return null;
  }

  @override
  Future<AdminTrip?> tripById(String id) async {
    final DataSnapshot snap = await _db.child('trips/$id').get();
    if (!snap.exists) return null;
    return _tripFromMap(id, _valueMap(snap));
  }

  @override
  Future<AdminUser?> userById(String id) async {
    final DataSnapshot snap = await _db.child('users/$id').get();
    if (!snap.exists) return null;
    return _userFromMap(id, _valueMap(snap));
  }

  @override
  Future<AdminFleet?> fleetById(String id) async {
    for (final AdminFleet fleet in await listFleets()) {
      if (fleet.id == id) return fleet;
    }
    return null;
  }

  @override
  Stream<List<AdminTrip>> watchActiveTripsForMap() {
    return _db.child('trips').onValue.map((event) {
      return _entries(event.snapshot)
          .map((entry) => _tripFromMap(entry.key, entry.value))
          .where((trip) {
        return trip.status == 'pending' ||
            trip.status == 'accepted' ||
            trip.status == 'started';
      }).toList();
    });
  }

  @override
  Stream<List<AdminDriverLocation>> watchDriverLocations() {
    return _db.child('drivers').onValue.map((event) {
      final List<AdminDriverLocation> locations = <AdminDriverLocation>[];
      for (final entry in _entries(event.snapshot)) {
        final Map<String, dynamic>? location = _map(entry.value['location']);
        if (location == null) continue;
        final double? lat = _double(location, 'lat');
        final double? lng = _double(location, 'lng');
        if (lat == null || lng == null) continue;
        locations.add(
          AdminDriverLocation(
            driverId: entry.key,
            lat: lat,
            lng: lng,
            online: entry.value['online'] == true,
            angle: _double(location, 'angle'),
            updatedAt: _date(location['updatedAt']),
          ),
        );
      }
      return locations;
    });
  }

  @override
  Future<void> resolveAlert(String id) async {
    await _db.child('alerts/$id').update(<String, Object?>{'resolved': true});
  }

  @override
  Future<Map<String, dynamic>> getConfig(String section) async {
    final DataSnapshot snap = await _db.child('config/$section').get();
    return _valueMap(snap);
  }

  @override
  Future<void> setConfig(String section, Map<String, Object?> value) async {
    await _db.child('config/$section').set(value);
  }

  @override
  Future<void> removeConfig(String section) async {
    await _db.child('config/$section').remove();
  }

  @override
  Future<void> updateVehicle(
    String partnerId,
    String vehicleId,
    Map<String, Object?> fields,
  ) async {
    await _db.child('partners/$partnerId/vehicles/$vehicleId').update(fields);
  }

  @override
  Future<String> createVehicle(
    String partnerId,
    Map<String, Object?> fields,
  ) async {
    final ref = _db.child('partners/$partnerId/vehicles').push();
    await ref.set(fields);
    return ref.key!;
  }

  @override
  Future<void> writeAuditLog(AdminAuditLog log) async {
    await _db.child('audit/${log.id}').set(<String, Object?>{
      'actorUid': log.actorUid,
      'action': log.action,
      'targetPath': log.targetPath,
      'metadata': log.metadata,
      'createdAt': log.createdAt.toIso8601String(),
    });
  }

  @override
  Future<AdminDriverWallet?> driverWallet(
    String partnerId,
    String driverId,
  ) async {
    final DataSnapshot snap =
        await _db.child('driverWallets/$partnerId/$driverId').get();
    if (!snap.exists) return null;
    final Map<String, dynamic> map = _valueMap(snap);
    final List<AdminWalletEntry> entries =
        _entryMap(_map(map['entries']) ?? <String, dynamic>{})
            .entries
            .map((e) => _walletEntryFromMap(e.key, e.value))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return AdminDriverWallet(
      partnerId: partnerId,
      driverId: driverId,
      balance: _int(map, 'balance') ?? 0,
      blockedAt: _date(map['blockedAt']),
      entries: entries,
    );
  }

  AdminWalletEntry _walletEntryFromMap(String id, Map<String, dynamic> map) {
    return AdminWalletEntry(
      id: id,
      type: _string(map, 'type') ?? 'adjustment',
      amountMtn: _int(map, 'amountMtn') ?? 0,
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      tripId: _string(map, 'tripId'),
      mpesaRef: _string(map, 'mpesaRef'),
      adminId: _string(map, 'adminId'),
      note: _string(map, 'note'),
    );
  }

  AdminPartner _partnerFromMap(String id, Map<String, dynamic> map) {
    return AdminPartner(
      id: id,
      name: _string(map, 'name') ?? id,
      city: _string(map, 'city') ?? '',
      status: _string(map, 'status') ?? 'pending',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      nuit: _string(map, 'nuit'),
      driversCount: _childCount(map['drivers']),
      vehiclesCount: _childCount(map['vehicles']),
      requiresWalletSettlement: _bool(map, 'requiresWalletSettlement') ?? false,
      commissionFloatMtn: _int(map, 'commissionFloatMtn') ?? 500,
    );
  }

  AdminDriver _driverFromMap(
    String id,
    Map<String, dynamic> user,
    Map<String, dynamic> state,
  ) {
    return AdminDriver(
      id: id,
      name: _string(user, 'name') ?? _string(user, 'phone') ?? id,
      status:
          _string(user, 'driverStatus') ?? _string(user, 'status') ?? 'active',
      partnerId: _string(user, 'partnerId'),
      online: _bool(user, 'online') ?? _bool(state, 'online') ?? false,
      phone: _string(user, 'phone'),
      email: _string(user, 'email'),
      vehicleId: _string(user, 'vehicleId') ?? _string(state, 'vehicleId'),
      rating: _double(user, 'rating') ?? 0,
      tripsCount: _int(user, 'tripsCount') ?? 0,
    );
  }

  AdminVehicle _vehicleFromMap(
    String partnerId,
    String id,
    Map<String, dynamic> map,
  ) {
    return AdminVehicle(
      id: id,
      partnerId: partnerId,
      plate: _string(map, 'plate') ?? '',
      model: _string(map, 'model') ?? '',
      type: _string(map, 'type') ?? '',
      status: _string(map, 'status') ?? 'available',
      driverId: _string(map, 'driverId'),
      year: _int(map, 'year'),
      category: _string(map, 'category'),
      seats: _int(map, 'seats'),
      photoUrl: _string(map, 'photoUrl'),
      color: _string(map, 'color'),
    );
  }

  AdminTrip _tripFromMap(String id, Map<String, dynamic> map) {
    return AdminTrip(
      id: id,
      status: _string(map, 'status') ?? 'pending',
      createdAt: _date(map['createdAt']) ??
          _date(map['startedAt']) ??
          _date(map['updatedAt']) ??
          DateTime.now(),
      partnerId: _string(map, 'partnerId'),
      driverId: _string(map, 'driverId') ?? _string(map, 'driver'),
      vehicleId: _string(map, 'vehicleId'),
      passengerId: _string(map, 'passengerId') ?? _string(map, 'passenger'),
      origin: _placeName(map['origin']),
      destination: _placeName(map['destination']),
      amountMtn: _int(map, 'amountMtn') ?? _int(map, 'estimatedPrice') ?? 0,
      distanceKm: _double(map, 'distanceKm') ?? _double(map, 'distance'),
      originLat: _coord(map['origin'], 'lat'),
      originLng: _coord(map['origin'], 'lng'),
      destLat: _coord(map['destination'], 'lat'),
      destLng: _coord(map['destination'], 'lng'),
      offeredAt: _date(map['offeredAt']),
      acceptedAt: _date(map['acceptedAt']),
    );
  }

  double? _coord(Object? place, String key) {
    final Map<String, dynamic>? map = _map(place);
    if (map == null) return null;
    return _double(map, key);
  }

  AdminUser _userFromMap(String id, Map<String, dynamic> map) {
    return AdminUser(
      id: id,
      type: _string(map, 'type') ?? 'passenger',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      name: _string(map, 'name'),
      email: _string(map, 'email'),
      phone: _string(map, 'phone'),
      partnerId: _string(map, 'partnerId'),
      status: _string(map, 'status'),
    );
  }

  AdminDocument _documentFromMap(
    String id,
    String ownerType,
    String ownerId,
    Map<String, dynamic> map,
  ) {
    return AdminDocument(
      id: id,
      ownerType: ownerType,
      ownerId: ownerId,
      type: _string(map, 'type') ?? 'document',
      status: _string(map, 'status') ?? 'pending',
      url: _string(map, 'url'),
      expiresAt: _date(map['expiresAt']),
    );
  }

  AdminAlert _alertFromMap(String id, Map<String, dynamic> map) {
    return AdminAlert(
      id: id,
      title: _string(map, 'title') ?? id,
      severity: _string(map, 'severity') ?? 'info',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      partnerId: _string(map, 'partnerId'),
      description: _string(map, 'description'),
      resolved: _bool(map, 'resolved') ?? false,
    );
  }

  AdminAuditLog _auditFromMap(String id, Map<String, dynamic> map) {
    // As Cloud Functions escrevem {action, actorUid, at, targetType, targetId,
    // meta}; entradas antigas do painel usavam {createdAt, targetPath,
    // metadata}. Aceitar ambos.
    final String? targetType = _string(map, 'targetType');
    final String? targetId = _string(map, 'targetId');
    return AdminAuditLog(
      id: id,
      actorUid: _string(map, 'actorUid') ?? '',
      action: _string(map, 'action') ?? '',
      targetPath: _string(map, 'targetPath') ??
          (targetId == null ? null : '${targetType ?? ''}/$targetId'),
      metadata:
          _map(map['metadata']) ?? _map(map['meta']) ?? <String, Object?>{},
      createdAt: _date(map['createdAt']) ?? _date(map['at']) ?? DateTime.now(),
    );
  }

  AdminCommission _commissionFromMap(
    String id,
    String partnerId,
    Map<String, dynamic> map,
  ) {
    return AdminCommission(
      id: id,
      partnerId: partnerId,
      rate: _double(map, 'rate') ?? _double(map, 'commission') ?? 0,
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      status: _string(map, 'status') ?? 'active',
    );
  }

  AdminPayout _payoutFromMap(
    String id,
    String partnerId,
    Map<String, dynamic> map,
  ) {
    return AdminPayout(
      id: id,
      partnerId: partnerId,
      amountMtn: _int(map, 'amountMtn') ?? 0,
      method: _string(map, 'method') ?? '-',
      status: _string(map, 'status') ?? 'paid',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      label: _string(map, 'label'),
      reference: _string(map, 'reference'),
    );
  }

  AdminPayment _paymentFromMap(String id, Map<String, dynamic> map) {
    return AdminPayment(
      id: id,
      tripId: _string(map, 'tripId') ?? '-',
      passenger: _string(map, 'passenger') ?? '-',
      method: _string(map, 'method') ?? '-',
      amountMtn: _int(map, 'amountMtn') ?? 0,
      status: _string(map, 'status') ?? 'pending',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      pspRef: _string(map, 'pspRef'),
      gateway: _string(map, 'gateway'),
    );
  }

  List<MapEntry<String, Map<String, dynamic>>> _entries(DataSnapshot snapshot) {
    return _entryMap(_valueMap(snapshot)).entries.toList();
  }

  Map<String, Map<String, dynamic>> _entryMap(Map<String, dynamic> map) {
    return map.map((key, value) {
      return MapEntry<String, Map<String, dynamic>>(
        key,
        _map(value) ?? <String, dynamic>{},
      );
    });
  }

  Map<String, dynamic> _valueMap(DataSnapshot snapshot) {
    return _map(snapshot.value) ?? <String, dynamic>{};
  }

  Map<String, dynamic>? _map(Object? value) {
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
    final Map<String, dynamic>? map = _map(value);
    if (map != null) {
      return _string(map, 'name') ??
          _string(map, 'address') ??
          _string(map, 'label') ??
          '';
    }
    return value is String ? value : '';
  }

  int _childCount(Object? value) {
    if (value is Map) return value.length;
    if (value is List) return value.length;
    if (value is num) return value.toInt();
    return 0;
  }
}
