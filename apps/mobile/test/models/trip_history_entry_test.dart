import 'package:flutter_test/flutter_test.dart';
import 'package:limousineexecutive/shared/models/trip_date_filter.dart';
import 'package:limousineexecutive/shared/models/trip_history_entry.dart';

void main() {
  group('TripHistoryEntry', () {
    test('translates the trip and cancellation fields for display', () {
      final trip = TripHistoryEntry.fromMap({
        'id': 'trip-123',
        'status': 'cancelled',
        'origin': {'name': 'Maputo'},
        'destination': {'name': 'Matola'},
        'stops': [
          {'name': 'Polana'},
        ],
        'tripType': 'airport',
        'carCategory': 'economico',
        'createdAt': '2026-05-10T08:30:00Z',
        'passengerName': 'Amina',
        'driverName': 'Mussa',
        'estimatedPrice': 450,
        'paymentMethod': 'mpesa',
        'cancelledBy': 'driver',
        'cancellationReason': 'Alteração dos planos',
        'cancelledAt': '2026-05-10T09:00:00Z',
      });

      expect(trip.statusLabel, 'Cancelada');
      expect(trip.tripTypeLabel, 'Aeroporto');
      expect(trip.vehicleCategory, 'Económico');
      expect(trip.origin, 'Maputo');
      expect(trip.destination, 'Matola');
      expect(trip.stops, ['Polana']);
      expect(trip.passengerName, 'Amina');
      expect(trip.driverName, 'Mussa');
      expect(trip.paymentMethod, 'M-Pesa');
      expect(trip.cancelledBy, 'Motorista');
      expect(trip.cancellationReason, 'Alteração dos planos');
      expect(trip.createdAt, isNotNull);
      expect(trip.cancelledAt, isNotNull);
    });

    test('does not infer a payment status when it is absent', () {
      final trip = TripHistoryEntry.fromMap({
        'id': 'legacy-trip',
        'status': 'completed',
      });

      expect(trip.paymentStatus, 'Não registado');
      expect(trip.paymentMethod, 'Não registado');
      expect(trip.amountLabel, 'Não registado');
      expect(trip.origin, 'Local de recolha');
      expect(trip.destination, 'Destino');
      expect(trip.createdAt, isNull);
      expect(trip.createdAtLabel, 'Data não disponível');
    });
  });

  group('TripDateFilter', () {
    final reference = DateTime(2026, 5, 10, 18, 45);

    test('today uses local calendar-day boundaries', () {
      final filter = TripDateFilter.today(referenceDate: reference);

      expect(filter.includes(DateTime(2026, 5, 10)), isTrue);
      expect(filter.includes(DateTime(2026, 5, 10, 23, 59, 59)), isTrue);
      expect(filter.includes(DateTime(2026, 5, 9, 23, 59, 59)), isFalse);
      expect(filter.includes(null), isFalse);
    });

    test('last seven days includes today and the previous six days', () {
      final filter = TripDateFilter.lastSevenDays(referenceDate: reference);

      expect(filter.startDate, DateTime(2026, 5, 4));
      expect(filter.includes(DateTime(2026, 5, 4)), isTrue);
      expect(filter.includes(DateTime(2026, 5, 10, 23, 59, 59)), isTrue);
      expect(filter.includes(DateTime(2026, 5, 3, 23, 59, 59)), isFalse);
    });

    test('custom range includes both endpoint days', () {
      final filter = TripDateFilter.custom(
        startDate: DateTime(2026, 3, 30, 16),
        endDate: DateTime(2026, 4, 1, 9),
      );

      expect(filter.includes(DateTime(2026, 3, 30)), isTrue);
      expect(filter.includes(DateTime(2026, 4, 1, 23, 59, 59)), isTrue);
      expect(filter.includes(DateTime(2026, 4, 2)), isFalse);
    });
  });
}
