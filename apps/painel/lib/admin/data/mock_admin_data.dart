import '../../partner/data/mock_partner_data.dart';
import '../../partner/data/mock_types.dart';
import 'types.dart';

abstract class MockAdminData {
  static final DateTime referenceNow = MockPartnerData.referenceNow;

  static final List<AdminPartner> partners = <AdminPartner>[
    AdminPartner(
      id: MockPartner.id,
      name: MockPartner.name,
      city: MockPartner.city,
      status: 'active',
      createdAt: referenceNow.subtract(const Duration(days: 240)),
      nuit: MockPartner.nuit,
      driversCount: MockPartnerData.drivers.length,
      vehiclesCount: MockPartnerData.vehicles.length,
    ),
  ];

  static final List<AdminDriver> drivers = MockPartnerData.drivers.map((
    MockDriver driver,
  ) {
    return AdminDriver(
      id: driver.id,
      name: driver.name,
      status: driver.status.key,
      partnerId: MockPartner.id,
      online: driver.online,
      phone: driver.phone,
      email: driver.email,
      vehicleId: driver.vehicleId,
      rating: driver.rating,
      tripsCount: driver.tripsCount,
    );
  }).toList();

  static final List<AdminVehicle> vehicles = MockPartnerData.vehicles.map((
    MockVehicle vehicle,
  ) {
    return AdminVehicle(
      id: vehicle.id,
      partnerId: MockPartner.id,
      plate: vehicle.plate,
      model: vehicle.model,
      type: vehicle.type,
      status: vehicle.status.key,
      driverId: vehicle.driverId,
      year: vehicle.year,
    );
  }).toList();

  static final List<AdminTrip> trips = MockPartnerData.trips.map((
    MockTrip trip,
  ) {
    final DateTime offeredAt =
        trip.startedAt.subtract(const Duration(minutes: 3));
    final bool wasAccepted = trip.status != MockTripStatus.pending;
    return AdminTrip(
      id: trip.id,
      status: trip.status.key,
      createdAt: trip.startedAt,
      partnerId: MockPartner.id,
      driverId: trip.driverId,
      vehicleId: trip.vehicleId,
      origin: trip.origin,
      destination: trip.destination,
      amountMtn: trip.amountMtn,
      offeredAt: offeredAt,
      acceptedAt: wasAccepted
          ? offeredAt.add(Duration(seconds: 40 + (trip.id.hashCode % 180)))
          : null,
    );
  }).toList();

  static final List<AdminUser> users = <AdminUser>[
    AdminUser(
      id: 'usr-admin-001',
      type: 'admin',
      createdAt: referenceNow.subtract(const Duration(days: 365)),
      name: 'Amina Mussa',
      email: 'admin@ya.co.mz',
    ),
    for (final AdminDriver driver in drivers)
      AdminUser(
        id: driver.id,
        type: 'driver',
        createdAt: referenceNow.subtract(const Duration(days: 120)),
        name: driver.name,
        email: driver.email,
        phone: driver.phone,
        partnerId: driver.partnerId,
      ),
  ];

  static final List<AdminFleet> fleets = <AdminFleet>[
    AdminFleet(
      id: MockPartner.fleetId,
      partnerId: MockPartner.id,
      name: MockPartner.fleetName,
      driversCount: drivers.length,
      vehiclesCount: vehicles.length,
    ),
  ];

  static final List<AdminDocument> documents = MockPartnerData.documents.map((
    MockDocument document,
  ) {
    return AdminDocument(
      id: document.id,
      ownerType: document.ownerType.name,
      ownerId: document.ownerId,
      type: document.title,
      status: document.status.key,
      expiresAt: document.expiresAt,
    );
  }).toList();

  static final List<AdminAlert> alerts = MockPartnerData.alerts.map((
    MockAlert alert,
  ) {
    return AdminAlert(
      id: alert.id,
      title: alert.title,
      severity: alert.severity.name,
      createdAt: alert.createdAt,
      partnerId: MockPartner.id,
      description: alert.description,
    );
  }).toList();

  static final List<AdminAuditLog> auditLogs = <AdminAuditLog>[];
  static final List<AdminCommission> commissions = <AdminCommission>[
    AdminCommission(
      id: 'COM-${MockPartner.id}',
      partnerId: MockPartner.id,
      rate: 0.12,
      createdAt: referenceNow.subtract(const Duration(days: 240)),
    ),
  ];
}
