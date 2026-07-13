import 'package:flutter_test/flutter_test.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_trip_repository.dart';

void main() {
  late DriverState driverState;
  late FakeTripRepository fakeRepo;
  late FakeAuthRepository fakeAuth;

  setUp(() {
    fakeRepo = FakeTripRepository();
    fakeAuth = FakeAuthRepository();
    // Simulate a logged-in driver
    fakeAuth.setUser(AppUser(uid: 'driver-999', phoneNumber: '123456789'));
    driverState = DriverState(repository: fakeRepo, auth: fakeAuth);
  });

  group('DriverState - Testes de Fluxo de Viagem', () {
    test('Deve iniciar o toque e carregar dados ao receber nova viagem', () async {
      const tripId = 'trip-123';
      
      // Simular criação de viagem no fake
      fakeRepo.addTrip(tripId, {
        'passenger': 'user-456',
        'origin': {'name': 'Origem', 'lat': 0.0, 'lng': 0.0},
        'destination': {'name': 'Destino', 'lat': 1.0, 'lng': 1.0},
        'estimatedPrice': 500,
        'paymentMethod': 'cash',
        'status': 'pending',
      });

      await driverState.handleNewTripRequest(tripId);

      expect(driverState.currentTripId, tripId);
      expect(driverState.isRinging, true);
      expect(driverState.isOnTrip, false);
      expect(driverState.originLocation, isNotNull);
    });

    test('Aceitar deve parar o toque INSTANTANEAMENTE e iniciar viagem', () async {
      const tripId = 'trip-123';
      
      // Setup
      fakeRepo.addTrip(tripId, {
        'passenger': 'user-456',
        'origin': {'name': 'O', 'lat': 0.0, 'lng': 0.0},
        'destination': {'name': 'D', 'lat': 1.0, 'lng': 1.0},
        'estimatedPrice': 500,
        'paymentMethod': 'cash',
        'status': 'pending',
      });
      await driverState.handleNewTripRequest(tripId);

      // Execução
      // Simulamos o acceptTrip sem o Firebase real (usando fake)
      // Nota: fakeService.acceptTrip ainda dá UnimplementedError no seu ficheiro,
      // mas vamos focar no estado local do DriverState que é o que corrigimos.
      
      // Como o acceptTrip no models usa await _service.acceptTrip,
      // precisamos que o fake não lance erro.
      
      final acceptFuture = driverState.acceptTrip();
      
      // VERIFICAÇÃO INSTANTÂNEA (antes do futuro terminar)
      expect(driverState.isRinging, false, reason: 'O toque deve parar logo no clique');
      expect(driverState.isOnTrip, true, reason: 'Deve mostrar GoingToPassenger logo no clique');

      await acceptFuture;
    });

    test('endTrip deve limpar todas as variáveis de localização e IDs', () {
      driverState.endTrip();
      
      expect(driverState.isOnTrip, false);
      expect(driverState.currentTripId, isNull);
      expect(driverState.originLocation, isNull);
      expect(driverState.destinationLocation, isNull);
      expect(driverState.currentTripData, isNull);
    });
  });
}
