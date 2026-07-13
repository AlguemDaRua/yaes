import 'package:flutter_test/flutter_test.dart';
import 'package:ya_painel/data/mock/mock_partner_data_repository.dart';
import 'package:ya_painel/partner/data/mock_partner_data.dart';
import 'package:ya_painel/partner/data/mock_types.dart';

void main() {
  const repo = MockPartnerDataRepository();

  test('uses the canonical mock partner id', () {
    expect(repo.partnerId, MockPartner.id);
  });

  test('returns drivers, vehicles and trips from mock data', () async {
    final drivers = await repo.listDrivers();
    final vehicles = await repo.listVehicles();
    final trips = await repo.listTrips();

    expect(drivers, isNotEmpty);
    expect(vehicles, isNotEmpty);
    expect(trips, isNotEmpty);
    expect(drivers, same(MockPartnerData.drivers));
    expect(vehicles, same(MockPartnerData.vehicles));
    expect(trips, same(MockPartnerData.trips));
  });

  test('filters trips by driver and vehicle', () async {
    final driver = MockPartnerData.drivers.first;
    final vehicle = MockPartnerData.vehicles.first;

    final driverTrips = await repo.tripsByDriver(driver.id);
    final vehicleTrips = await repo.tripsByVehicle(vehicle.id);

    expect(driverTrips, isNotEmpty);
    expect(driverTrips.every((trip) => trip.driverId == driver.id), isTrue);
    expect(vehicleTrips, isNotEmpty);
    expect(vehicleTrips.every((trip) => trip.vehicleId == vehicle.id), isTrue);
  });

  test('resolves entities by id', () async {
    final driver = MockPartnerData.drivers.first;
    final vehicle = MockPartnerData.vehicles.first;
    final trip = MockPartnerData.trips.first;

    expect(await repo.driverById(driver.id), same(driver));
    expect(await repo.vehicleById(vehicle.id), same(vehicle));
    expect(await repo.tripById(trip.id), same(trip));
    expect(await repo.driverById('missing'), isNull);
  });

  test('returns only critical alerts in criticalAlerts', () async {
    final alerts = await repo.criticalAlerts();

    expect(alerts, isNotEmpty);
    expect(
      alerts.every((alert) => alert.severity == MockAlertSeverity.critical),
      isTrue,
    );
  });

  test('returns earning transactions with expected statuses', () async {
    final transactions = await repo.earningsTransactions();

    expect(transactions, isNotEmpty);
    expect(
      transactions.map((transaction) => transaction.status).toSet(),
      containsAll(<MockTransactionStatus>{
        MockTransactionStatus.paid,
        MockTransactionStatus.pending,
        MockTransactionStatus.failed,
      }),
    );
    expect(
      transactions.every((transaction) => transaction.id.isNotEmpty),
      isTrue,
    );
  });

  test('returns documents, maintenance, ratings, incentives and messages',
      () async {
    final vehicle = MockPartnerData.vehicles.first;
    final driver = MockPartnerData.drivers.first;

    final documents = await repo.listDocuments();
    final maintenance = await repo.maintenancesByVehicle(vehicle.id);
    final ratings = await repo.ratingsByDriver(driver.id);
    final incentives = await repo.incentives();
    final messages = await repo.messageThreads();

    expect(documents, isNotEmpty);
    expect(
      maintenance.every((item) => item.vehicleId == vehicle.id),
      isTrue,
    );
    expect(ratings.every((rating) => rating.driverId == driver.id), isTrue);
    expect(incentives, isNotEmpty);
    expect(messages, isNotEmpty);
  });

  test('streams drivers and vehicles', () async {
    await expectLater(repo.watchDrivers(), emits(MockPartnerData.drivers));
    await expectLater(repo.watchVehicles(), emits(MockPartnerData.vehicles));
  });

  test('partnerProfile returns the demo partner profile', () async {
    final profile = await repo.partnerProfile();
    expect(profile.id, MockPartner.id);
    expect(profile.name, MockPartner.name);
    expect(profile.city, MockPartner.city);
    expect(profile.status, 'active');
  });

  test('createVehicle adds and deleteVehicle removes a vehicle', () async {
    final String id = await repo.createVehicle(
      plate: 'TST-000-MP',
      model: 'Test Model',
      type: 'Sedan',
      year: 2024,
      seats: 4,
    );
    final created = await repo.vehicleById(id);
    expect(created, isNotNull);
    expect(created!.plate, 'TST-000-MP');
    expect(created.status, MockVehicleStatus.available);

    await repo.deleteVehicle(id);
    expect(await repo.vehicleById(id), isNull);
  });

  test('updateVehicle mutates the given fields', () async {
    final String id = await repo.createVehicle(
      plate: 'UPD-000-MP',
      model: 'Old',
      type: 'Sedan',
      year: 2020,
      seats: 4,
    );
    await repo.updateVehicle(id, <String, dynamic>{
      'model': 'New',
      'status': 'maintenance',
    });
    final updated = await repo.vehicleById(id);
    expect(updated!.model, 'New');
    expect(updated.status, MockVehicleStatus.maintenance);

    await repo.deleteVehicle(id);
  });

  test('sendThreadMessage appends and watchThreadMessages emits it', () async {
    await repo.sendThreadMessage('thread-test', 'ola suporte');
    await expectLater(
      repo.watchThreadMessages('thread-test'),
      emits(
        predicate<List<MockChatMessage>>(
          (msgs) => msgs.any((m) => m.text == 'ola suporte' && m.fromPartner),
        ),
      ),
    );
  });
}
