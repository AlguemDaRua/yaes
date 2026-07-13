// Fluxo crítico end-to-end contra o emulador Firebase real (Auth + RTDB +
// Functions): login por telefone (OTP real, obtido via REST do emulador de
// Auth) -> home -> escolher categoria -> pedir viagem (escrita real em
// /trips, verificada por leitura direta ao emulador).
//
// GPS e geocodificação (Mapbox) não são simuláveis neste ambiente — a
// localização/origem/destino são seeded diretamente no PassengerState em vez
// de percorridos pelo ecrã de pesquisa de morada, que depende de um
// MAPBOX_TOKEN real (gerido pelo CLÉSIO). O resto do fluxo (login, seleção
// de categoria, pedido de viagem, escrita em /trips) corre através dos
// widgets reais.
//
// Corre com o emulador Firebase (auth+database+functions) já a correr:
//   firebase emulators:start
//   flutter test integration_test/critical_flow_test.dart -d chrome \
//     --dart-define=USE_EMULATORS=true
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/main.dart' as app;
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:provider/provider.dart';

const String _dbHost = 'http://localhost:9000';
const String _authHost = 'http://localhost:9099';
const String _projectId = 'ya-app-z';
const String _ns = 'ya-app-z-default-rtdb';

const String _driverUid = 'it-driver-1';
const String _phoneNumber = '841234500';
const String _fullPhone = '+258$_phoneNumber';

Future<void> _seed() async {
  final String now = DateTime.now().toIso8601String();
  await http.patch(
    Uri.parse('$_dbHost/.json?ns=$_ns&auth=owner'),
    body: jsonEncode(<String, dynamic>{
      'users/$_driverUid': <String, dynamic>{
        'phone': '+258849990001',
        'type': 'driver',
        'name': 'Motorista Teste',
        'createdAt': now,
        'vehicle': <String, dynamic>{
          'category': 'economico',
          'model': 'Corolla Teste IT',
          'plate': 'IT-001',
          'seats': 4,
        },
      },
      'drivers/$_driverUid': <String, dynamic>{
        'online': true,
        'busy': false,
        'location': <String, dynamic>{
          'lat': -25.9,
          'lng': 32.6,
          'angle': 0,
          'updatedAt': now,
        },
      },
      'config/pricing/categories': <String, dynamic>{
        'moto': <String, dynamic>{
          'label': 'Moto',
          'multiplier': 0.5,
          'seats': 1,
          'order': 0,
        },
        'economico': <String, dynamic>{
          'label': 'Económico',
          'multiplier': 1.0,
          'seats': 4,
          'order': 1,
        },
      },
    }),
  );
}

/// Poll do emulador de Auth pelo código de verificação real — nunca um valor
/// fixo assumido (o emulador gera um código diferente a cada corrida).
Future<String> _fetchOtp(String phoneNumber) async {
  for (int attempt = 0; attempt < 30; attempt++) {
    final http.Response res = await http.get(
      Uri.parse(
        '$_authHost/emulator/v1/projects/$_projectId/verificationCodes',
      ),
    );
    final Map<String, dynamic> body =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List<dynamic> codes =
        (body['verificationCodes'] as List<dynamic>?) ?? <dynamic>[];
    for (final dynamic c in codes.reversed) {
      final Map<String, dynamic> entry = c as Map<String, dynamic>;
      if (entry['phoneNumber'] == phoneNumber) {
        return entry['code'] as String;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  throw StateError('OTP não recebido do emulador para $phoneNumber');
}

Future<Map<String, dynamic>?> _fetchPendingTrip() async {
  final http.Response res = await http.get(
    Uri.parse('$_dbHost/trips.json?ns=$_ns&auth=owner'),
  );
  final Object? decoded = jsonDecode(res.body);
  if (decoded is! Map) return null;
  for (final dynamic value in decoded.values) {
    final Map<String, dynamic> trip = Map<String, dynamic>.from(value as Map);
    if (trip['carCategory'] == 'economico' &&
        (trip['status'] == 'pending' || trip['status'] == 'awaiting_payment')) {
      return trip;
    }
  }
  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login por telefone -> home -> categoria -> pedir viagem',
      (WidgetTester tester) async {
    await _seed();

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // ── Login: número de telefone ──
    await tester.enterText(find.byType(TextFormField).first, _phoneNumber);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── OTP real, obtido do emulador ──
    final String otp = await _fetchOtp(_fullPhone);
    await tester.enterText(find.byType(TextField).first, otp);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byType(TextField), findsNothing,
        reason: 'devia ter navegado para fora do ecrã de OTP');

    // ── Home: sem GPS/Mapbox neste ambiente — seed direto de localização/
    // morada no estado, como se o utilizador já tivesse escolhido no ecrã de
    // pesquisa de morada. ──
    final BuildContext ctx = tester.element(find.byType(Scaffold).first);
    final PassengerState appState =
        // ignore: use_build_context_synchronously
        Provider.of<PassengerState>(ctx, listen: false);
    appState.currentLocation = const LatLng(-25.97, 32.58);
    appState.originLocation = const LatLng(-25.97, 32.58);
    appState.fromAddress = 'Origem Teste';
    appState.destinationLocation = const LatLng(-25.92, 32.57);
    appState.toAddress = 'Destino Teste';
    await tester.pumpAndSettle();

    // ── Categoria ──
    await tester.tap(find.text('Económico'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ── Pedir viagem: escolher o veículo seeded ──
    await tester.tap(find.text('Corolla Teste IT'));
    await tester.pumpAndSettle();

    // Data/hora: aceitar "agora"
    await tester.tap(find.text('Concluído'));
    await tester.pumpAndSettle();

    // Método de pagamento (cartão = não pré-pago, evita simular webhook)
    await tester.tap(find.text('Cartão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pagar'));
    await tester.pumpAndSettle();

    // Confirmação final
    await tester.tap(find.text('Confirmar Viagem'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── Verificação real: a viagem foi escrita no RTDB do emulador ──
    Map<String, dynamic>? trip;
    for (int attempt = 0; attempt < 10 && trip == null; attempt++) {
      trip = await _fetchPendingTrip();
      if (trip == null) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
    expect(trip, isNotNull, reason: 'nenhuma viagem pending encontrada em /trips');
    expect(trip!['paymentMethod'], 'cartao');
    expect(appState.currentTripId, isNotNull);
  });
}
