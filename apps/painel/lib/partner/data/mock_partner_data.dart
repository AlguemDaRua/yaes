import 'dart:math';

import 'mock_types.dart';

abstract class MockPartner {
  static const String id = 'ptr-maputo-exec';
  static const String name = 'Maputo Executive';
  static const String city = 'Maputo';
  static const String nuit = '400123456';
  static const String email = 'contacto@maputoexec.co.mz';
  static const String phone = '+258 84 999 0000';
  static const String? logoUrl = null;

  static const String fleetId = 'flt-maputo-exec';
  static const String fleetName = 'Frota Maputo Executive';
}

/// Perfil de instância de um partner (partilhado entre mock e Firebase).
class MockPartnerProfile {
  const MockPartnerProfile({
    required this.id,
    required this.name,
    required this.city,
    required this.nuit,
    required this.email,
    required this.phone,
    required this.fleetName,
    required this.status,
    this.payoutMethod = 'none',
    this.payoutMpesaNumber,
    this.payoutIban,
    this.broadcastsEnabled = true,
  });

  final String id;
  final String name;
  final String city;
  final String nuit;
  final String email;
  final String phone;
  final String fleetName;
  final String status;

  /// `'none' | 'mpesa' | 'iban'` — para onde a YA envia os payouts do partner.
  final String payoutMethod;
  final String? payoutMpesaNumber;
  final String? payoutIban;

  /// Se falso, os motoristas desta frota deixam de ser subscritos aos tópicos
  /// FCM de broadcast (`all`/`drivers`) no próximo login/refresh do app.
  final bool broadcastsEnabled;

  static const MockPartnerProfile demo = MockPartnerProfile(
    id: MockPartner.id,
    name: MockPartner.name,
    city: MockPartner.city,
    nuit: MockPartner.nuit,
    email: MockPartner.email,
    phone: MockPartner.phone,
    fleetName: MockPartner.fleetName,
    status: 'active',
  );
}

class MockDriver {
  const MockDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.status,
    required this.online,
    required this.vehicleId,
    required this.rating,
    required this.ratingsCount,
    required this.tripsCount,
    required this.totalEarningsMtn,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final MockDriverStatus status;
  final bool online;
  final String? vehicleId;
  final double rating;
  final int ratingsCount;
  final int tripsCount;
  final int totalEarningsMtn;
  final DateTime joinedAt;
}

class MockPartnerStaff {
  const MockPartnerStaff({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String role;
}

class MockVehicle {
  const MockVehicle({
    required this.id,
    required this.plate,
    required this.type,
    required this.model,
    required this.status,
    required this.driverId,
    required this.year,
    required this.seats,
    required this.odometerKm,
  });

  final String id;
  final String plate;
  final String type;
  final String model;
  final MockVehicleStatus status;
  final String? driverId;
  final int year;
  final int seats;
  final int odometerKm;
}

class MockTrip {
  const MockTrip({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.passengerName,
    required this.origin,
    required this.destination,
    required this.amountMtn,
    required this.partnerNetMtn,
    required this.distanceKm,
    required this.durationMinutes,
    required this.status,
    required this.startedAt,
    this.offeredAt,
    this.acceptedAt,
  });

  final String id;
  final String driverId;
  final String vehicleId;
  final String passengerName;
  final String origin;
  final String destination;
  final int amountMtn;
  final int partnerNetMtn;
  final double distanceKm;
  final int durationMinutes;
  final MockTripStatus status;
  final DateTime startedAt;
  final DateTime? offeredAt;
  final DateTime? acceptedAt;
}

class MockDocument {
  const MockDocument({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.title,
    required this.status,
    required this.expiresAt,
  });

  final String id;
  final MockDocumentOwnerType ownerType;
  final String ownerId;
  final String title;
  final MockDocumentStatus status;
  final DateTime? expiresAt;
}

class MockAlert {
  const MockAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.createdAt,
    this.driverId,
    this.vehicleId,
  });

  final String id;
  final String title;
  final String description;
  final MockAlertSeverity severity;
  final DateTime createdAt;
  final String? driverId;
  final String? vehicleId;
}

class MockRating {
  const MockRating({
    required this.id,
    required this.driverId,
    required this.tripId,
    required this.value,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String driverId;
  final String tripId;
  final int value;
  final String comment;
  final DateTime createdAt;
}

class MockMaintenance {
  const MockMaintenance({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.scheduledAt,
    required this.costMtn,
    required this.completed,
  });

  final String id;
  final String vehicleId;
  final String title;
  final DateTime scheduledAt;
  final int costMtn;
  final bool completed;
}

class MockEarningsTransaction {
  const MockEarningsTransaction({
    required this.id,
    required this.label,
    required this.amountMtn,
    required this.status,
    required this.date,
  });

  final String id;
  final String label;
  final int amountMtn;
  final MockTransactionStatus status;
  final DateTime date;
}

class MockIncentive {
  const MockIncentive({
    required this.id,
    required this.title,
    required this.target,
    required this.rewardMtn,
    required this.progress,
    required this.status,
    required this.endsAt,
  });

  final String id;
  final String title;
  final String target;
  final int rewardMtn;
  final double progress;
  final MockIncentiveStatus status;
  final DateTime endsAt;
}

class MockMessageThread {
  const MockMessageThread({
    required this.id,
    required this.subject,
    required this.participant,
    required this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  final String id;
  final String subject;
  final String participant;
  final String lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
}

/// Mensagem individual dentro de uma conversa (`/messages/{threadId}/messages`).
class MockChatMessage {
  const MockChatMessage({
    required this.id,
    required this.text,
    required this.fromPartner,
    required this.timestamp,
  });

  final String id;
  final String text;
  final bool fromPartner;
  final DateTime timestamp;
}

abstract class MockPartnerData {
  static final DateTime referenceNow = DateTime(2026, 5, 5, 12);

  static const List<int> dailyEarningsMtn7d = <int>[
    24000,
    28000,
    22000,
    31000,
    35000,
    28000,
    18000,
  ];

  static const List<MockPartnerStaff> staff = <MockPartnerStaff>[
    MockPartnerStaff(
      id: 'STF-001',
      name: 'Ines Chambal',
      email: 'ines.chambal@maputoexec.co.mz',
      role: 'partner_owner',
    ),
    MockPartnerStaff(
      id: 'STF-002',
      name: 'Bruno Machaieie',
      email: 'bruno.machaieie@maputoexec.co.mz',
      role: 'partner_staff',
    ),
  ];

  static final List<MockDriver> drivers = _generateDrivers();
  static final List<MockVehicle> vehicles = _generateVehicles(drivers);
  static final List<MockTrip> trips = _generateTrips(drivers, vehicles);
  static final List<MockDocument> documents = _generateDocuments(
    drivers,
    vehicles,
  );
  static final List<MockAlert> alerts = _generateAlerts();
  static final List<MockRating> ratings = _generateRatings(drivers, trips);
  static final List<MockMaintenance> maintenances = _generateMaintenances(
    vehicles,
  );
  static final List<MockEarningsTransaction> earningsTransactions =
      _generateEarningsTransactions();
  static final List<MockIncentive> incentives = _generateIncentives();
  static final List<MockMessageThread> messageThreads =
      _generateMessageThreads();

  static List<MockDriver> driversByFleet([String? fleetId]) => drivers;

  static List<MockVehicle> vehiclesByFleet([String? fleetId]) => vehicles;

  static List<MockTrip> tripsByFleet([String? fleetId]) => trips;

  static List<MockTrip> tripsByDriver(String driverId) {
    return trips.where((MockTrip trip) => trip.driverId == driverId).toList();
  }

  static List<MockTrip> tripsByVehicle(String vehicleId) {
    return trips.where((MockTrip trip) => trip.vehicleId == vehicleId).toList();
  }

  static MockDriver? driverById(String id) {
    for (final MockDriver driver in drivers) {
      if (driver.id == id) return driver;
    }
    return null;
  }

  static MockVehicle? vehicleById(String id) {
    for (final MockVehicle vehicle in vehicles) {
      if (vehicle.id == id) return vehicle;
    }
    return null;
  }

  static MockTrip? tripById(String id) {
    for (final MockTrip trip in trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  static List<MockAlert> get criticalAlerts {
    return alerts
        .where(
          (MockAlert alert) => alert.severity == MockAlertSeverity.critical,
        )
        .toList();
  }

  static List<MockDriver> get topDrivers {
    final List<MockDriver> sorted = <MockDriver>[...drivers]..sort(
        (MockDriver a, MockDriver b) =>
            b.totalEarningsMtn.compareTo(a.totalEarningsMtn),
      );
    return sorted;
  }

  static List<MockTrip> get recentTrips {
    final List<MockTrip> sorted = <MockTrip>[...trips]
      ..sort((MockTrip a, MockTrip b) => b.startedAt.compareTo(a.startedAt));
    return sorted;
  }

  static int get onlineDriversCount {
    return drivers.where((MockDriver driver) => driver.online).length;
  }

  static int get availableVehiclesCount {
    return vehicles
        .where(
          (MockVehicle vehicle) =>
              vehicle.status == MockVehicleStatus.available,
        )
        .length;
  }

  static int get weeklyTripsCount {
    final DateTime start = referenceNow.subtract(const Duration(days: 7));
    return trips
        .where(
          (MockTrip trip) => !trip.startedAt.isBefore(start),
        )
        .length;
  }

  static int get monthlyTripsCount {
    final DateTime start = referenceNow.subtract(const Duration(days: 30));
    return trips
        .where(
          (MockTrip trip) => !trip.startedAt.isBefore(start),
        )
        .length;
  }

  static int get weeklyNetEarningsMtn {
    return dailyEarningsMtn7d.fold<int>(
      0,
      (int total, int value) => total + value,
    );
  }

  static int get ratingsCount {
    return drivers.fold<int>(
      0,
      (int total, MockDriver driver) => total + driver.ratingsCount,
    );
  }

  static double get averageRating {
    final int count = ratingsCount;
    if (count == 0) return 0;
    final double weighted = drivers.fold<double>(
      0,
      (double total, MockDriver driver) =>
          total + driver.rating * driver.ratingsCount,
    );
    return weighted / count;
  }

  static List<MockDriver> _generateDrivers() {
    const List<String> names = <String>[
      'Afonso Macuvele',
      'Judite Mondlane',
      'Celia Sitoe',
      'Elias Cossa',
      'Marta Tembe',
      'Tito Mucavele',
      'Helena Nhantumbo',
      'Salvador Mabunda',
      'Rosa Muchanga',
      'Nelson Chissano',
      'Carla Matavele',
      'Bento Machel',
      'Luisa Massingue',
      'Jorge Sumbana',
      'Amelia Bila',
      'Daniel Nhampossa',
      'Teresa Guambe',
      'Osvaldo Manhica',
      'Fatima Chongo',
      'Raul Chauque',
      'Ivone Tivane',
      'Paulo Mula',
      'Sonia Hlungwane',
      'Mateus Dlamini',
      'Edna Cuambe',
      'Victor Zandamela',
      'Lidia Maluleke',
      'Arlindo Matsinhe',
      'Nelia Sithole',
      'Julio Mabjaia',
      'Beatriz Ndlovu',
      'Hugo Machava',
      'Lucia Mucavel',
      'Nuno Macamo',
      'Ilda Chemane',
      'Mario Nhaca',
      'Sandra Malate',
      'Adelino Cuna',
      'Madalena Magaia',
      'Gilberto Sambo',
      'Palmira Mahumane',
      'Valter Langa',
      'Celeste Mavie',
      'Isaias Zitha',
      'Noemia Matsolo',
      'Abel Mucave',
      'Elsa Cumbane',
    ];
    const List<int> ratingCounts = <int>[
      41,
      39,
      37,
      36,
      35,
      34,
      33,
      32,
      32,
      31,
      30,
      30,
      29,
      29,
      28,
      28,
      28,
      27,
      27,
      27,
      26,
      26,
      26,
      25,
      25,
      25,
      25,
      24,
      24,
      24,
      24,
      21,
      21,
      21,
      20,
      20,
      20,
      19,
      19,
      19,
      18,
      18,
      18,
      17,
      17,
      16,
      16,
    ];
    final Random random = Random(42);

    return <MockDriver>[
      for (int i = 0; i < names.length; i++)
        MockDriver(
          id: 'DRV-${(i + 1).toString().padLeft(3, '0')}',
          name: names[i],
          phone: '+258 84 ${100 + i} ${200 + i} ${300 + i}',
          email:
              '${names[i].toLowerCase().replaceAll(' ', '.')}@maputoexec.co.mz',
          status: i == 45
              ? MockDriverStatus.pending
              : i == 46
                  ? MockDriverStatus.suspended
                  : MockDriverStatus.active,
          online: i < 28,
          vehicleId:
              i < 38 ? 'VEH-${(i + 1).toString().padLeft(3, '0')}' : null,
          rating: i == 18
              ? 3.8
              : i == 36
                  ? 3.9
                  : 4.55 + random.nextDouble() * 0.35,
          ratingsCount: ratingCounts[i],
          tripsCount: 96 + random.nextInt(88) + (i < 8 ? 42 - i * 3 : 0),
          totalEarningsMtn:
              42000 + random.nextInt(48000) + (i < 8 ? 56000 - i * 3500 : 0),
          joinedAt: referenceNow.subtract(Duration(days: 35 + i * 9)),
        ),
    ];
  }

  static List<MockVehicle> _generateVehicles(List<MockDriver> drivers) {
    const List<String> models = <String>[
      'Toyota Corolla',
      'Hyundai Accent',
      'Kia Rio',
      'VW Polo',
      'Nissan Almera',
      'Toyota Avanza',
      'Suzuki Dzire',
      'Honda Fit',
    ];
    const List<String> types = <String>[
      'Sedan',
      'Sedan',
      'Sedan',
      'Hatchback',
      'Sedan',
      'Monovolume',
      'Sedan',
      'Hatchback',
    ];
    final Random random = Random(42);

    return <MockVehicle>[
      for (int i = 0; i < 38; i++)
        MockVehicle(
          id: 'VEH-${(i + 1).toString().padLeft(3, '0')}',
          plate:
              '${String.fromCharCode(65 + i ~/ 26)}${String.fromCharCode(65 + i % 26)}${String.fromCharCode(65 + (i * 3) % 26)}-${(123 + i * 7).toString().padLeft(3, '0')}-MP',
          type: types[i % types.length],
          model: models[i % models.length],
          status: i < 5
              ? MockVehicleStatus.available
              : i < 30
                  ? MockVehicleStatus.busy
                  : MockVehicleStatus.maintenance,
          driverId: drivers[i].id,
          year: 2018 + random.nextInt(7),
          seats: types[i % types.length] == 'Monovolume' ? 7 : 5,
          odometerKm: 24000 + random.nextInt(136000),
        ),
    ];
  }

  static List<MockTrip> _generateTrips(
    List<MockDriver> drivers,
    List<MockVehicle> vehicles,
  ) {
    const List<String> origins = <String>[
      'Polana',
      'Sommerschield',
      'Costa do Sol',
      'Baixa',
      'Aeroporto',
      'Maputo Shopping',
      'Matola',
      'Jardim',
      'Museu',
      'Zimpeto',
    ];
    const List<String> destinations = <String>[
      'Aeroporto',
      'Hotel Polana',
      'Matola',
      'Baixa',
      'Costa do Sol',
      'Sommerschield',
      'Julius Nyerere',
      'Marracuene',
      'Porto de Maputo',
      'Triunfo',
    ];
    const List<String> passengers = <String>[
      'Maria Tembe',
      'Paulo Guambe',
      'Anita Cossa',
      'Rui Manhica',
      'Carolina Bila',
      'Samuel Langa',
    ];
    final Random random = Random(42);
    final List<MockTrip> result = <MockTrip>[];

    void addTrip(int index, int daysAgo) {
      final MockDriver driver = drivers[index % drivers.length];
      final MockVehicle vehicle = vehicles[index % vehicles.length];
      final int amount = 320 + random.nextInt(1120);
      // Index 0 (TRP-2847A) é sempre completed para suportar testes legados.
      final MockTripStatus status = index == 0
          ? MockTripStatus.completed
          : index % 23 == 0
              ? MockTripStatus.cancelled
              : index % 31 == 0
                  ? MockTripStatus.started
                  : index % 37 == 0
                      ? MockTripStatus.accepted
                      : MockTripStatus.completed;
      final DateTime startedAt = referenceNow.subtract(
        Duration(
          days: daysAgo,
          hours: random.nextInt(20),
          minutes: random.nextInt(60),
        ),
      );
      final DateTime offeredAt = startedAt.subtract(const Duration(minutes: 3));
      final bool wasAccepted = status != MockTripStatus.pending;
      result.add(
        MockTrip(
          id: 'TRP-${(2847 + index).toString()}${String.fromCharCode(65 + index % 26)}',
          driverId: driver.id,
          vehicleId: vehicle.id,
          passengerName: passengers[index % passengers.length],
          origin: origins[index % origins.length],
          destination: destinations[(index * 3) % destinations.length],
          amountMtn: amount,
          partnerNetMtn: (amount * 0.88).round(),
          distanceKm: 2.8 + random.nextDouble() * 22,
          durationMinutes: 8 + random.nextInt(42),
          status: status,
          startedAt: startedAt,
          offeredAt: offeredAt,
          acceptedAt:
              wasAccepted ? offeredAt.add(Duration(seconds: 40 + random.nextInt(180))) : null,
        ),
      );
    }

    for (int i = 0; i < 247; i++) {
      addTrip(i, i % 7);
    }
    for (int i = 247; i < 1047; i++) {
      addTrip(i, 8 + (i % 22));
    }
    for (int i = 1047; i < 1100; i++) {
      addTrip(i, 31 + (i % 59));
    }

    return result;
  }

  static List<MockDocument> _generateDocuments(
    List<MockDriver> drivers,
    List<MockVehicle> vehicles,
  ) {
    return <MockDocument>[
      MockDocument(
        id: 'DOC-PTR-001',
        ownerType: MockDocumentOwnerType.partner,
        ownerId: MockPartner.id,
        title: 'Licenca comercial',
        status: MockDocumentStatus.ok,
        expiresAt: referenceNow.add(const Duration(days: 220)),
      ),
      for (final MockDriver driver in drivers)
        MockDocument(
          id: 'DOC-${driver.id}-LIC',
          ownerType: MockDocumentOwnerType.driver,
          ownerId: driver.id,
          title: 'Carta de conducao',
          status: driver.status == MockDriverStatus.pending
              ? MockDocumentStatus.missing
              : MockDocumentStatus.ok,
          expiresAt: referenceNow.add(const Duration(days: 180)),
        ),
      for (final MockVehicle vehicle in vehicles)
        MockDocument(
          id: 'DOC-${vehicle.id}-INS',
          ownerType: MockDocumentOwnerType.vehicle,
          ownerId: vehicle.id,
          title: 'Seguro automovel',
          status: vehicle.status == MockVehicleStatus.maintenance
              ? MockDocumentStatus.expiringSoon
              : MockDocumentStatus.ok,
          expiresAt: referenceNow.add(
            Duration(
              days: vehicle.status == MockVehicleStatus.maintenance ? 18 : 120,
            ),
          ),
        ),
    ];
  }

  static List<MockAlert> _generateAlerts() {
    return <MockAlert>[
      MockAlert(
        id: 'ALT-001',
        title: 'Seguro a expirar',
        description: '3 veiculos precisam renovar seguro nos proximos 20 dias.',
        severity: MockAlertSeverity.critical,
        createdAt: referenceNow.subtract(const Duration(hours: 2)),
        vehicleId: 'VEH-031',
      ),
      MockAlert(
        id: 'ALT-002',
        title: 'Driver suspenso',
        description: 'Elsa Cumbane esta suspensa ate validacao documental.',
        severity: MockAlertSeverity.critical,
        createdAt: referenceNow.subtract(const Duration(hours: 5)),
        driverId: 'DRV-047',
      ),
      MockAlert(
        id: 'ALT-003',
        title: 'Rating abaixo do esperado',
        description: '2 motoristas estao abaixo de 4,0 na media semanal.',
        severity: MockAlertSeverity.warning,
        createdAt: referenceNow.subtract(const Duration(days: 1)),
      ),
      MockAlert(
        id: 'ALT-004',
        title: 'Incentivo perto da meta',
        description: 'A frota esta a 83% do alvo semanal de corridas.',
        severity: MockAlertSeverity.info,
        createdAt: referenceNow.subtract(const Duration(days: 2)),
      ),
    ];
  }

  static List<MockRating> _generateRatings(
    List<MockDriver> drivers,
    List<MockTrip> trips,
  ) {
    const List<String> comments = <String>[
      'Pontual e profissional',
      'Carro limpo',
      'Conducao segura',
      'Boa comunicacao',
      'Rota eficiente',
    ];
    return <MockRating>[
      for (int i = 0; i < 50; i++)
        MockRating(
          id: 'RAT-${(i + 1).toString().padLeft(3, '0')}',
          driverId: drivers[i % drivers.length].id,
          tripId: trips[i % trips.length].id,
          value: i % 11 == 0 ? 4 : 5,
          comment: comments[i % comments.length],
          createdAt: referenceNow.subtract(Duration(days: i % 30)),
        ),
    ];
  }

  static List<MockMaintenance> _generateMaintenances(
    List<MockVehicle> vehicles,
  ) {
    const List<String> titles = <String>[
      'Troca de oleo',
      'Inspeccao de travoes',
      'Alinhamento',
      'Revisao AC',
      'Pneus',
    ];
    return <MockMaintenance>[
      for (final MockVehicle vehicle in vehicles)
        for (int i = 0; i < titles.length; i++)
          MockMaintenance(
            id: 'MNT-${vehicle.id}-${i + 1}',
            vehicleId: vehicle.id,
            title: titles[i],
            scheduledAt: referenceNow.add(Duration(days: i * 18 - 20)),
            costMtn: 1800 + i * 900,
            completed: i < 2,
          ),
    ];
  }

  static List<MockEarningsTransaction> _generateEarningsTransactions() {
    return <MockEarningsTransaction>[
      for (int i = 0; i < 30; i++)
        MockEarningsTransaction(
          id: 'ERN-${(i + 1).toString().padLeft(3, '0')}',
          label: i % 7 == 0 ? 'Ajuste de comissao' : 'Liquidacao diaria',
          amountMtn: i % 7 == 0 ? -1200 : 7400 + i * 180,
          status: i < 27
              ? MockTransactionStatus.paid
              : i == 28
                  ? MockTransactionStatus.pending
                  : MockTransactionStatus.failed,
          date: referenceNow.subtract(Duration(days: i)),
        ),
    ];
  }

  static List<MockIncentive> _generateIncentives() {
    return <MockIncentive>[
      MockIncentive(
        id: 'INC-001',
        title: 'Pico da semana',
        target: '300 corridas completas',
        rewardMtn: 42000,
        progress: 0.83,
        status: MockIncentiveStatus.active,
        endsAt: referenceNow.add(const Duration(days: 2)),
      ),
      MockIncentive(
        id: 'INC-002',
        title: 'Rating premium',
        target: 'Media >= 4,8 com 120 avaliacoes',
        rewardMtn: 25000,
        progress: 0.64,
        status: MockIncentiveStatus.active,
        endsAt: referenceNow.add(const Duration(days: 9)),
      ),
      MockIncentive(
        id: 'INC-003',
        title: 'Arranque de Junho',
        target: '40 drivers online no horario de pico',
        rewardMtn: 18000,
        progress: 0,
        status: MockIncentiveStatus.scheduled,
        endsAt: referenceNow.add(const Duration(days: 35)),
      ),
    ];
  }

  static List<MockMessageThread> _generateMessageThreads() {
    return <MockMessageThread>[
      MockMessageThread(
        id: 'MSG-001',
        subject: 'Validacao de seguro',
        participant: 'Equipa de Operacoes YA',
        lastMessage: 'Envie os comprovativos dos veiculos em alerta.',
        unreadCount: 2,
        updatedAt: referenceNow.subtract(const Duration(minutes: 35)),
      ),
      MockMessageThread(
        id: 'MSG-002',
        subject: 'Campanha fim-de-semana',
        participant: 'Financeiro YA',
        lastMessage: 'O incentivo entra em vigor na sexta-feira as 17h.',
        unreadCount: 1,
        updatedAt: referenceNow.subtract(const Duration(hours: 4)),
      ),
      MockMessageThread(
        id: 'MSG-003',
        subject: 'Suporte motorista',
        participant: 'Suporte YA',
        lastMessage: 'Caso DRV-018 resolvido.',
        unreadCount: 0,
        updatedAt: referenceNow.subtract(const Duration(days: 1)),
      ),
    ];
  }
}

final List<MockDriver> mockDrivers = MockPartnerData.drivers;
final List<MockVehicle> mockVehicles = MockPartnerData.vehicles;
final List<MockTrip> mockTrips = MockPartnerData.trips;
final List<MockDocument> mockDocuments = MockPartnerData.documents;
final List<MockAlert> mockAlerts = MockPartnerData.alerts;
final List<MockAlert> mockCriticalAlerts = MockPartnerData.criticalAlerts;
final List<MockRating> mockRatings = MockPartnerData.ratings;
final List<MockMaintenance> mockMaintenances = MockPartnerData.maintenances;
final List<MockEarningsTransaction> mockEarningsTransactions =
    MockPartnerData.earningsTransactions;
final List<MockIncentive> mockIncentives = MockPartnerData.incentives;
final List<MockMessageThread> mockMessageThreads =
    MockPartnerData.messageThreads;
final List<MockDriver> mockTopDrivers = MockPartnerData.topDrivers;
final List<MockTrip> mockRecentTrips = MockPartnerData.recentTrips;

List<MockDriver> mockDriversByFleet([String? fleetId]) {
  return MockPartnerData.driversByFleet(fleetId);
}

List<MockTrip> mockTripsByDriver(String id) {
  return MockPartnerData.tripsByDriver(id);
}

List<MockTrip> mockTripsByVehicle(String id) {
  return MockPartnerData.tripsByVehicle(id);
}

MockDriver? mockDriverById(String id) {
  return MockPartnerData.driverById(id);
}

MockVehicle? mockVehicleById(String id) {
  return MockPartnerData.vehicleById(id);
}

MockTrip? mockTripById(String id) {
  return MockPartnerData.tripById(id);
}
