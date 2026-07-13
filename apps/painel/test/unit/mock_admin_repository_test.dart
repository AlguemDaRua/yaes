import 'package:flutter_test/flutter_test.dart';
import 'package:ya_painel/admin/data/types.dart';
import 'package:ya_painel/data/mock/mock_admin_data_repository.dart';

void main() {
  const repo = MockAdminDataRepository();

  test('returns admin collection data', () async {
    expect(await repo.listPartners(), isNotEmpty);
    expect(await repo.listDrivers(), isNotEmpty);
    expect(await repo.listVehicles(), isNotEmpty);
    expect(await repo.listTrips(), isNotEmpty);
    expect(await repo.listUsers(), isNotEmpty);
    expect(await repo.listFleets(), isNotEmpty);
    expect(await repo.listDocuments(), isNotEmpty);
    expect(await repo.listAlerts(), isNotEmpty);
    expect(await repo.listAuditLogs(), isEmpty);
    expect(await repo.listCommissions(), isNotEmpty);
  });

  test('resolves admin entities by id', () async {
    final partner = (await repo.listPartners()).first;
    final driver = (await repo.listDrivers()).first;
    final vehicle = (await repo.listVehicles()).first;
    final trip = (await repo.listTrips()).first;
    final user = (await repo.listUsers()).first;
    final fleet = (await repo.listFleets()).first;

    expect(await repo.partnerById(partner.id), same(partner));
    expect(await repo.driverById(driver.id), same(driver));
    expect(await repo.vehicleById(vehicle.id), same(vehicle));
    expect(await repo.vehicleById(vehicle.plate), same(vehicle));
    expect(await repo.tripById(trip.id), same(trip));
    expect(await repo.userById(user.id), same(user));
    expect(await repo.fleetById(fleet.id), same(fleet));
  });

  test('returns null for unknown admin ids', () async {
    expect(await repo.partnerById('missing'), isNull);
    expect(await repo.driverById('missing'), isNull);
    expect(await repo.vehicleById('missing'), isNull);
    expect(await repo.tripById('missing'), isNull);
    expect(await repo.userById('missing'), isNull);
    expect(await repo.fleetById('missing'), isNull);
  });

  test('watches active trips for map', () async {
    final trips = await repo.watchActiveTripsForMap().first;

    expect(trips, isNotEmpty);
    expect(trips.every((AdminTrip trip) => trip.status != 'completed'), isTrue);
  });

  test('accepts audit log writes as a no-op', () async {
    await repo.writeAuditLog(
      AdminAuditLog(
        id: 'AUD-test',
        actorUid: 'usr-admin-001',
        action: 'test',
        createdAt: DateTime(2026, 5, 9),
      ),
    );
  });
}
