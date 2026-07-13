import 'dart:async';

import '../../partner/data/mock_partner_data.dart';
import '../../partner/data/mock_types.dart';
import '../repositories/partner_data_repository.dart';

/// Implementação mock do [PartnerDataRepository] que delega para [MockPartnerData].
/// Devolve dados síncronos via Future.value e usa Stream.value para watchers.
/// A implementação Firebase (Fase D) substitui esta classe sem alterar callers.
class MockPartnerDataRepository implements PartnerDataRepository {
  const MockPartnerDataRepository({this.partnerId = MockPartner.id});

  @override
  final String partnerId;

  @override
  Future<MockPartnerProfile> partnerProfile() async =>
      MockPartnerProfile.demo;

  @override
  Future<List<MockPartnerStaff>> listStaff() async => MockPartnerData.staff;

  @override
  Future<List<MockDriver>> listDrivers() async => MockPartnerData.drivers;

  @override
  Stream<List<MockDriver>> watchDrivers() => Stream<List<MockDriver>>.value(
        MockPartnerData.drivers,
      );

  @override
  Future<MockDriver?> driverById(String id) async =>
      MockPartnerData.driverById(id);

  @override
  Future<List<MockVehicle>> listVehicles() async => MockPartnerData.vehicles;

  @override
  Stream<List<MockVehicle>> watchVehicles() => Stream<List<MockVehicle>>.value(
        MockPartnerData.vehicles,
      );

  @override
  Future<MockVehicle?> vehicleById(String id) async =>
      MockPartnerData.vehicleById(id);

  @override
  Future<String> createVehicle({
    required String plate,
    required String model,
    required String type,
    required int year,
    required int seats,
  }) async {
    final String id = 'veh-${DateTime.now().millisecondsSinceEpoch}';
    MockPartnerData.vehicles.add(
      MockVehicle(
        id: id,
        plate: plate,
        type: type,
        model: model,
        status: MockVehicleStatus.available,
        driverId: null,
        year: year,
        seats: seats,
        odometerKm: 0,
      ),
    );
    return id;
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> fields) async {}

  @override
  Future<void> updateVehicle(String id, Map<String, dynamic> fields) async {
    final int i =
        MockPartnerData.vehicles.indexWhere((MockVehicle v) => v.id == id);
    if (i < 0) return;
    final MockVehicle v = MockPartnerData.vehicles[i];
    MockPartnerData.vehicles[i] = MockVehicle(
      id: v.id,
      plate: fields['plate'] as String? ?? v.plate,
      type: fields['type'] as String? ?? v.type,
      model: fields['model'] as String? ?? v.model,
      status: _statusFrom(fields['status'] as String?) ?? v.status,
      driverId: fields.containsKey('driverId')
          ? fields['driverId'] as String?
          : v.driverId,
      year: fields['year'] as int? ?? v.year,
      seats: fields['seats'] as int? ?? v.seats,
      odometerKm: fields['odometerKm'] as int? ?? v.odometerKm,
    );
  }

  @override
  Future<void> deleteVehicle(String id) async {
    MockPartnerData.vehicles.removeWhere((MockVehicle v) => v.id == id);
  }

  MockVehicleStatus? _statusFrom(String? key) {
    switch (key) {
      case 'available':
        return MockVehicleStatus.available;
      case 'busy':
        return MockVehicleStatus.busy;
      case 'maintenance':
        return MockVehicleStatus.maintenance;
      default:
        return null;
    }
  }

  @override
  Future<List<MockTrip>> listTrips() async => MockPartnerData.trips;

  @override
  Future<List<MockTrip>> tripsByDriver(String driverId) async =>
      MockPartnerData.tripsByDriver(driverId);

  @override
  Future<List<MockTrip>> tripsByVehicle(String vehicleId) async =>
      MockPartnerData.tripsByVehicle(vehicleId);

  @override
  Future<MockTrip?> tripById(String id) async => MockPartnerData.tripById(id);

  @override
  Future<List<MockAlert>> listAlerts() async => MockPartnerData.alerts;

  @override
  Future<List<MockAlert>> criticalAlerts() async =>
      MockPartnerData.criticalAlerts;

  @override
  Future<List<MockDocument>> listDocuments() async =>
      MockPartnerData.documents;

  @override
  Future<List<MockMaintenance>> maintenancesByVehicle(String vehicleId) async {
    return MockPartnerData.maintenances
        .where((MockMaintenance m) => m.vehicleId == vehicleId)
        .toList();
  }

  @override
  Future<List<MockRating>> ratingsByDriver(String driverId) async {
    return MockPartnerData.ratings
        .where((MockRating r) => r.driverId == driverId)
        .toList();
  }

  @override
  Future<List<MockEarningsTransaction>> earningsTransactions() async =>
      MockPartnerData.earningsTransactions;

  @override
  Future<List<MockIncentive>> incentives() async => MockPartnerData.incentives;

  @override
  Future<List<MockMessageThread>> messageThreads() async =>
      MockPartnerData.messageThreads;

  static final Map<String, List<MockChatMessage>> _threadMessages =
      <String, List<MockChatMessage>>{};
  static final StreamController<String> _threadChanges =
      StreamController<String>.broadcast();

  @override
  Stream<List<MockChatMessage>> watchThreadMessages(String threadId) async* {
    yield _threadMessages[threadId] ?? const <MockChatMessage>[];
    yield* _threadChanges.stream
        .where((String id) => id == threadId)
        .map((_) => _threadMessages[threadId] ?? const <MockChatMessage>[]);
  }

  @override
  Future<void> sendThreadMessage(String threadId, String text) async {
    final List<MockChatMessage> list = _threadMessages.putIfAbsent(
      threadId,
      () => <MockChatMessage>[],
    );
    list.add(
      MockChatMessage(
        id: 'm${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        fromPartner: true,
        timestamp: DateTime.now(),
      ),
    );
    _threadChanges.add(threadId);
  }
}
