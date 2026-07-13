// Script de seed para popular o emulator Firebase com dados consistentes
// para desenvolvimento do painel.
//
// Usage:
//   flutter pub get
//   dart run tool/seed.dart
//
// Pré-requisitos:
//   - JDK 21+ no PATH (exigido pelo firebase-tools recente)
//   - Emulators ligados: cd ya-app && firebase emulators:start
//   - O script liga-se aos emulators (não toca em produção) e usa o mesmo
//     namespace RTDB que o app sob emulador (`ya-app-z`).
//
// Cria:
//   - 3 contas no Auth emulator (login no painel) — password: painel123
//       admin@ya.co.mz · owner@maputoexec.co.mz · support@ya.co.mz
//     Os nós /users/{uid} ficam chaveados pelo uid de autenticação.
//   - 1 partner Maputo Executive (active)
//   - 5 drivers + 5 vehicles dentro do partner
//   - 50 trips (forma de produção: createdAt plano + distanceKm)
//   - 5 alertas
//   - 3 tickets

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:ya_painel/firebase_options.dart';

const String _partnerId = 'ptr-maputo-exec';
const String _partnerYaId = 'partner_ya';
final String _now = DateTime.now().toIso8601String();

Future<void> main() async {
  await Firebase.initializeApp(
    // Semear no namespace `ya-app-z-default-rtdb` — a instancia default onde os
    // triggers e o admin.database() das functions atacam (igual a producao, e ao
    // que o app/painel usam sob USE_EMULATORS). O bare `ya-app-z` e uma instancia
    // separada que os triggers nao observam.
    options: DefaultFirebaseOptions.currentPlatform
        .copyWith(databaseURL: 'https://ya-app-z-default-rtdb.firebaseio.com'),
  );

  // Emulators
  FirebaseDatabase.instance.useDatabaseEmulator('localhost', 9000);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

  final DatabaseReference db = FirebaseDatabase.instance.ref();

  stdout.writeln('Seeding emulator database...');

  final Map<String, String> uids = await _seedAuthUsers();
  await _seedUsers(db, uids);
  await _seedPartner(db, uids['owner']!);
  await _seedDriversAndVehicles(db);
  await _seedTrips(db);
  await _seedAlerts(db);
  await _seedTickets(db);
  await _seedYaDirectPartner(db);

  stdout.writeln('Done. Open http://localhost:4000 to inspect.');
  stdout.writeln('Login (emulador): admin@ya.co.mz / owner@maputoexec.co.mz / '
      'support@ya.co.mz — password: painel123');
  exit(0);
}

/// Cria contas no Auth emulator para os 3 utilizadores do painel e devolve os
/// uids reais (admin/owner/support), para que os nos `/users/{uid}` fiquem
/// chaveados pelo uid de autenticacao — e o login resolva o papel.
Future<Map<String, String>> _seedAuthUsers() async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  const String password = 'painel123';

  Future<String> ensure(String email) async {
    try {
      final UserCredential cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final UserCredential cred = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return cred.user!.uid;
      }
      rethrow;
    }
  }

  final String adminUid = await ensure('admin@ya.co.mz');
  final String ownerUid = await ensure('owner@maputoexec.co.mz');
  final String supportUid = await ensure('support@ya.co.mz');
  await auth.signOut();

  stdout.writeln('  + 3 contas Auth (password: $password)');
  return <String, String>{
    'admin': adminUid,
    'owner': ownerUid,
    'support': supportUid,
  };
}

Future<void> _seedUsers(DatabaseReference db, Map<String, String> uids) async {
  // Admin
  await db.child('users/${uids['admin']}').set(<String, dynamic>{
    'phone': '+258841000001',
    'name': 'Amina Mussa',
    'email': 'admin@ya.co.mz',
    'type': 'admin',
    'rating': null,
    'ratingCount': 0,
    'createdAt': _now,
  });
  await db.child('admins/${uids['admin']}').set(true);

  // Partner owner
  await db.child('users/${uids['owner']}').set(<String, dynamic>{
    'phone': '+258841000002',
    'name': 'Maputo Executive Owner',
    'email': 'owner@maputoexec.co.mz',
    'type': 'partner_owner',
    'partnerId': _partnerId,
    'rating': null,
    'ratingCount': 0,
    'createdAt': _now,
  });

  // Support
  await db.child('users/${uids['support']}').set(<String, dynamic>{
    'phone': '+258841000003',
    'name': 'Antonio Massango',
    'email': 'support@ya.co.mz',
    'type': 'support',
    'rating': null,
    'ratingCount': 0,
    'createdAt': _now,
  });

  stdout.writeln('  + 3 system users (admin, partner_owner, support)');
}

Future<void> _seedPartner(DatabaseReference db, String ownerUid) async {
  await db.child('partners/$_partnerId').set(<String, dynamic>{
    'name': 'Maputo Executive',
    'nuit': '400123456',
    'city': 'Maputo',
    'email': 'contacto@maputoexec.co.mz',
    'phone': '+258 84 999 0000',
    'status': 'active',
    'ownerUid': ownerUid,
    'createdAt': _now,
  });
  await db.child('partners/$_partnerId/staff/$ownerUid').set('partner_owner');

  stdout.writeln('  + partner $_partnerId');
}

Future<void> _seedDriversAndVehicles(DatabaseReference db) async {
  const List<({String uid, String name, String phone})> drivers =
      <({String uid, String name, String phone})>[
    (uid: 'drv-001', name: 'A. Macuvele', phone: '+258 84 332 8910'),
    (uid: 'drv-002', name: 'J. Mondlane', phone: '+258 84 332 8911'),
    (uid: 'drv-003', name: 'C. Sitoe', phone: '+258 84 332 8912'),
    (uid: 'drv-004', name: 'M. Tembe', phone: '+258 84 332 8913'),
    (uid: 'drv-005', name: 'R. Bila', phone: '+258 84 332 8914'),
  ];

  const List<({String id, String plate, String model})> vehicles =
      <({String id, String plate, String model})>[
    (id: 'veh-001', plate: 'AAA-001-MP', model: 'Toyota Corolla 2022'),
    (id: 'veh-002', plate: 'AAA-002-MP', model: 'Honda Civic 2021'),
    (id: 'veh-003', plate: 'AAA-003-MP', model: 'Mazda 3 2023'),
    (id: 'veh-004', plate: 'AAA-004-MP', model: 'Hyundai Elantra 2020'),
    (id: 'veh-005', plate: 'AAA-005-MP', model: 'Toyota Camry 2023'),
  ];

  for (int i = 0; i < drivers.length; i++) {
    final d = drivers[i];
    final v = vehicles[i];
    await db.child('users/${d.uid}').set(<String, dynamic>{
      'phone': d.phone,
      'name': d.name,
      'email': '${d.uid}@maputoexec.co.mz',
      'type': 'driver',
      'partnerId': _partnerId,
      'vehicleId': v.id,
      'rating': 4.5 + (i * 0.1),
      'ratingCount': 120 + i * 30,
      'tripsCount': 200 + i * 40,
      'totalEarningsMtn': 80000 + i * 12000,
      'createdAt': _now,
    });
    await db.child('partners/$_partnerId/drivers/${d.uid}').set(true);
    await db
        .child('partners/$_partnerId/vehicles/${v.id}')
        .set(<String, dynamic>{
      'plate': v.plate,
      'model': v.model,
      'type': 'sedan',
      'status': 'available',
      'driverId': d.uid,
      'year': 2020 + i,
      'seats': 4,
      'createdAt': _now,
    });
    await db.child('drivers/${d.uid}/online').set(i.isEven);
  }

  stdout.writeln('  + 5 drivers + 5 vehicles in $_partnerId');
}

Future<void> _seedTrips(DatabaseReference db) async {
  const List<String> origins = <String>[
    'Polana',
    'Baixa',
    'Museu',
    'Costa do Sol',
    'Aeroporto',
  ];
  const List<String> destinations = <String>[
    'Matola',
    'Magoanine',
    'Aeroporto',
    'Polana',
    'Baixa',
  ];

  for (int i = 0; i < 50; i++) {
    final String tripId = 'TRP-${(2900 + i).toString()}';
    final String driverUid = 'drv-${((i % 5) + 1).toString().padLeft(3, '0')}';
    final String vehicleId = 'veh-${((i % 5) + 1).toString().padLeft(3, '0')}';
    final int amount = 320 + (i * 47) % 1100;
    final String status = i % 13 == 0
        ? 'cancelled'
        : i % 17 == 0
            ? 'started'
            : 'completed';
    // Espelha a forma escrita pela app (ya-app firebase_trip_repository.dart):
    // `createdAt` plano (lido pelo painel) + `distanceKm` + `timestamps`.
    final String created =
        DateTime.now().subtract(Duration(hours: i * 6)).toIso8601String();
    await db.child('trips/$tripId').set(<String, dynamic>{
      'passenger': 'pax-mock-${i % 10}',
      'driver': driverUid,
      'vehicleId': vehicleId,
      'partnerId': _partnerId,
      'origin': <String, dynamic>{
        'name': origins[i % origins.length],
        'lat': -25.96 + (i % 5) * 0.01,
        'lng': 32.58 + (i % 5) * 0.01,
      },
      'destination': <String, dynamic>{
        'name': destinations[i % destinations.length],
        'lat': -25.95 + (i % 5) * 0.01,
        'lng': 32.60 + (i % 5) * 0.01,
      },
      'estimatedPrice': amount,
      'distanceKm': 3.0 + (i % 10),
      'durationMinutes': 8 + (i % 20),
      'paymentMethod': i.isEven ? 'mpesa' : 'cash',
      'tipo': 'regular',
      'tripType': 'regular',
      'status': status,
      'createdAt': created,
      'timestamps': <String, dynamic>{'created': created},
    });
  }

  stdout.writeln('  + 50 trips');
}

Future<void> _seedAlerts(DatabaseReference db) async {
  const List<({String title, String severity, String description})> alerts =
      <({String title, String severity, String description})>[
    (
      title: 'Carta de M. Tembe expira em 5 dias',
      severity: 'warning',
      description: 'Renovar antes da expiração para evitar suspensão.',
    ),
    (
      title: 'Veículo AAA-005-MP necessita manutenção',
      severity: 'warning',
      description: 'Próxima manutenção: hoje',
    ),
    (
      title: 'Driver J. Mondlane teve 2 ratings de 1★',
      severity: 'critical',
      description: 'Verificar feedback dos passageiros',
    ),
    (
      title: 'R. Bila recusou 5 corridas seguidas',
      severity: 'info',
      description: 'Comportamento atípico detectado',
    ),
    (
      title: 'Rating médio da frota abaixo de 4.5',
      severity: 'critical',
      description: 'Investigar drivers com performance baixa',
    ),
  ];

  for (int i = 0; i < alerts.length; i++) {
    final a = alerts[i];
    final DatabaseReference ref = db.child('alerts').push();
    await ref.set(<String, dynamic>{
      'partnerId': _partnerId,
      'title': a.title,
      'description': a.description,
      'severity': a.severity,
      'resolved': false,
      'createdAt':
          DateTime.now().subtract(Duration(hours: i * 4)).toIso8601String(),
    });
  }

  stdout.writeln('  + ${alerts.length} alerts');
}

Future<void> _seedTickets(DatabaseReference db) async {
  const List<({String subject, String priority})> tickets =
      <({String subject, String priority})>[
    (subject: 'Cobrança duplicada em corrida', priority: 'urgent'),
    (subject: 'Driver não apareceu, preciso reembolso', priority: 'high'),
    (subject: 'Como mudo método de pagamento padrão?', priority: 'medium'),
  ];

  for (int i = 0; i < tickets.length; i++) {
    final t = tickets[i];
    final DatabaseReference ref = db.child('tickets').push();
    await ref.set(<String, dynamic>{
      'subject': t.subject,
      'priority': t.priority,
      'status': i == 0 ? 'open' : 'in_progress',
      'authorUid': 'pax-mock-$i',
      'partnerId': _partnerId,
      'createdAt':
          DateTime.now().subtract(Duration(minutes: i * 30)).toIso8601String(),
    });
  }

  stdout.writeln('  + ${tickets.length} tickets');
}

/// Partner "YA Direct" (Nampula, motoristas directos) para testar a
/// carteira de comissão no painel: 2 drivers, um saudável e um bloqueado.
Future<void> _seedYaDirectPartner(DatabaseReference db) async {
  await db.child('partners/$_partnerYaId').set(<String, dynamic>{
    'name': 'YA Direct',
    'nuit': '400999888',
    'city': 'Nampula',
    'status': 'active',
    'requiresWalletSettlement': true,
    'commissionFloatMtn': 500,
    'createdAt': _now,
  });

  const List<({String uid, String name, String phone, String veh, String plate})>
      drivers = <({
    String uid,
    String name,
    String phone,
    String veh,
    String plate
  })>[
    (
      uid: 'drv-ya-001',
      name: 'F. Nacuo',
      phone: '+258 86 220 1001',
      veh: 'veh-ya-001',
      plate: 'MOT-01-NPL'
    ),
    (
      uid: 'drv-ya-002',
      name: 'S. Wazir',
      phone: '+258 86 220 1002',
      veh: 'veh-ya-002',
      plate: 'MOT-02-NPL'
    ),
  ];

  for (final d in drivers) {
    await db.child('users/${d.uid}').set(<String, dynamic>{
      'phone': d.phone,
      'name': d.name,
      'email': '${d.uid}@yadirect.co.mz',
      'type': 'driver',
      'partnerId': _partnerYaId,
      'vehicleId': d.veh,
      'rating': 4.6,
      'ratingCount': 40,
      'tripsCount': 90,
      'createdAt': _now,
    });
    await db.child('partners/$_partnerYaId/drivers/${d.uid}').set(true);
    // Moto registada pelo parceiro (categoria moto para Nampula). O trigger
    // onVehicleChanged espelha isto em users/{uid}/vehicle para o passageiro.
    await db
        .child('partners/$_partnerYaId/vehicles/${d.veh}')
        .set(<String, dynamic>{
      'plate': d.plate,
      'model': 'Honda 125',
      'type': 'moto',
      'category': 'moto',
      'status': 'available',
      'driverId': d.uid,
      'seats': 1,
      'createdAt': _now,
    });
    await db.child('drivers/${d.uid}/online').set(true);
  }

  // Carteira saudável.
  await db.child('driverWallets/$_partnerYaId/drv-ya-001').set(<String, dynamic>{
    'balance': -120,
    'blockedAt': null,
    'entries': <String, dynamic>{
      'seed-entry-1': <String, dynamic>{
        'type': 'commission',
        'amountMtn': -120,
        'tripId': 'TRP-YA-001',
        'createdAt': _now,
      },
    },
  });

  // Carteira bloqueada (saldo abaixo do float de 500).
  await db.child('driverWallets/$_partnerYaId/drv-ya-002').set(<String, dynamic>{
    'balance': -650,
    'blockedAt': _now,
    'entries': <String, dynamic>{
      'seed-entry-2': <String, dynamic>{
        'type': 'commission',
        'amountMtn': -650,
        'tripId': 'TRP-YA-002',
        'createdAt': _now,
      },
    },
  });

  stdout.writeln('  + partner $_partnerYaId (YA Direct) + 2 drivers + carteiras');
}
