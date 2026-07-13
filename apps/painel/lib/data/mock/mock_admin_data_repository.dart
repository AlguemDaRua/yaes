import '../../admin/data/mock_admin_data.dart';
import '../../admin/data/types.dart';
import '../repositories/admin_data_repository.dart';

class MockAdminDataRepository implements AdminDataRepository {
  const MockAdminDataRepository();

  @override
  Future<List<AdminPartner>> listPartners() async => MockAdminData.partners;

  @override
  Future<List<AdminDriver>> listDrivers() async => MockAdminData.drivers;

  @override
  Future<List<AdminVehicle>> listVehicles() async => MockAdminData.vehicles;

  @override
  Future<List<AdminTrip>> listTrips() async => MockAdminData.trips;

  @override
  Future<List<AdminUser>> listUsers() async => MockAdminData.users;

  @override
  Future<List<AdminFleet>> listFleets() async => MockAdminData.fleets;

  @override
  Future<List<AdminDocument>> listDocuments() async => MockAdminData.documents;

  @override
  Future<List<AdminAlert>> listAlerts() async => MockAdminData.alerts;

  @override
  Future<List<AdminAuditLog>> listAuditLogs() async => MockAdminData.auditLogs;

  @override
  Future<List<AdminCommission>> listCommissions() async {
    return MockAdminData.commissions;
  }

  @override
  Future<List<AdminPayment>> listPayments() async => <AdminPayment>[];

  @override
  Future<List<AdminPayout>> listPayouts() async => <AdminPayout>[];

  @override
  Future<List<AdminBroadcast>> listBroadcasts() async => <AdminBroadcast>[];

  @override
  Future<AdminPartner?> partnerById(String id) async {
    return _firstOrNull(MockAdminData.partners, (AdminPartner p) => p.id == id);
  }

  @override
  Future<AdminDriver?> driverById(String id) async {
    return _firstOrNull(MockAdminData.drivers, (AdminDriver d) => d.id == id);
  }

  @override
  Future<AdminVehicle?> vehicleById(String id) async {
    return _firstOrNull(
      MockAdminData.vehicles,
      (AdminVehicle v) => v.id == id || v.plate == id,
    );
  }

  @override
  Future<AdminTrip?> tripById(String id) async {
    return _firstOrNull(MockAdminData.trips, (AdminTrip t) => t.id == id);
  }

  @override
  Future<AdminUser?> userById(String id) async {
    return _firstOrNull(MockAdminData.users, (AdminUser u) => u.id == id);
  }

  @override
  Future<AdminFleet?> fleetById(String id) async {
    return _firstOrNull(MockAdminData.fleets, (AdminFleet f) => f.id == id);
  }

  @override
  Stream<List<AdminTrip>> watchActiveTripsForMap() {
    return Stream<List<AdminTrip>>.value(
      MockAdminData.trips
          .where((AdminTrip trip) => trip.status != 'completed')
          .toList(),
    );
  }

  @override
  Stream<List<AdminDriverLocation>> watchDriverLocations() {
    return Stream<List<AdminDriverLocation>>.value(
      const <AdminDriverLocation>[],
    );
  }

  @override
  Future<void> resolveAlert(String id) async {}

  @override
  Future<Map<String, dynamic>> getConfig(String section) async {
    return <String, dynamic>{};
  }

  @override
  Future<void> setConfig(String section, Map<String, Object?> value) async {}

  @override
  Future<void> removeConfig(String section) async {}

  @override
  Future<void> updateVehicle(
    String partnerId,
    String vehicleId,
    Map<String, Object?> fields,
  ) async {}

  @override
  Future<String> createVehicle(
    String partnerId,
    Map<String, Object?> fields,
  ) async =>
      'mock-vehicle';

  @override
  Future<void> writeAuditLog(AdminAuditLog log) async {}

  // ponytail: sem carteira fixa no mock — o tab mostra o EmptyState nesse caso,
  // que é o que já acontece hoje para partners sem requiresWalletSettlement.
  @override
  Future<AdminDriverWallet?> driverWallet(
    String partnerId,
    String driverId,
  ) async =>
      null;

  T? _firstOrNull<T>(List<T> values, bool Function(T value) test) {
    for (final T value in values) {
      if (test(value)) return value;
    }
    return null;
  }
}
