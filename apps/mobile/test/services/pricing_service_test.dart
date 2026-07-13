import 'package:flutter_test/flutter_test.dart';
import 'package:limousineexecutive/services/pricing_service.dart';

void main() {
  group('TripType', () {
    test('has all expected values', () {
      expect(TripType.values, containsAll([
        TripType.regular,
        TripType.scheduled,
        TripType.airport,
        TripType.event,
      ]));
    });

    test('name matches expected string', () {
      expect(TripType.regular.name, 'regular');
      expect(TripType.scheduled.name, 'scheduled');
      expect(TripType.airport.name, 'airport');
      expect(TripType.event.name, 'event');
    });
  });

  group('SurgeLevel', () {
    test('has all expected values', () {
      expect(SurgeLevel.values, containsAll([
        SurgeLevel.normal,
        SurgeLevel.moderate,
        SurgeLevel.high,
        SurgeLevel.extreme,
        SurgeLevel.maximum,
      ]));
    });
  });

  group('PricingResult.fromMap', () {
    test('parses a valid regular trip map', () {
      final map = {
        'tripType': 'regular',
        'baseFare': 150.0,
        'distanceAmount': 105.0,
        'timeAmount': 25.0,
        'subtotal': 280.0,
        'surgeMultiplier': 1.0,
        'totalAmount': 280.0,
        'minimumFare': 250.0,
        'minimumFareApplied': false,
        'commissionRate': 0.12,
        'commissionAmount': 33.6,
        'netAmount': 246.4,
      };

      final result = PricingResult.fromMap(map);

      expect(result.tripType, 'regular');
      expect(result.baseFare, 150.0);
      expect(result.distanceAmount, 105.0);
      expect(result.timeAmount, 25.0);
      expect(result.subtotal, 280.0);
      expect(result.surgeMultiplier, 1.0);
      expect(result.totalAmount, 280.0);
      expect(result.minimumFare, 250.0);
      expect(result.minimumFareApplied, false);
      expect(result.commissionRate, 0.12);
      expect(result.commissionAmount, 33.6);
      expect(result.netAmount, 246.4);
    });

    test('applies minimum fare when subtotal is below minimum', () {
      final map = {
        'tripType': 'regular',
        'baseFare': 150.0,
        'distanceAmount': 35.0,
        'timeAmount': 5.0,
        'subtotal': 190.0,
        'surgeMultiplier': 1.0,
        'totalAmount': 250.0,
        'minimumFare': 250.0,
        'minimumFareApplied': true,
        'commissionRate': 0.12,
        'commissionAmount': 30.0,
        'netAmount': 220.0,
      };

      final result = PricingResult.fromMap(map);

      expect(result.minimumFareApplied, true);
      expect(result.totalAmount, 250.0);
    });

    test('handles integer values from server (num cast)', () {
      final map = {
        'tripType': 'airport',
        'baseFare': 500,
        'distanceAmount': 90,
        'timeAmount': 0,
        'subtotal': 590,
        'surgeMultiplier': 1,
        'totalAmount': 590,
        'minimumFare': 500,
        'minimumFareApplied': false,
        'commissionRate': 0.15,
        'commissionAmount': 88,
        'netAmount': 502,
      };

      final result = PricingResult.fromMap(map);

      expect(result.baseFare, isA<double>());
      expect(result.totalAmount, 590.0);
    });
  });

  group('PricingService.computeLocal (fallback)', () {
    test('applies minimum fare for a zero-distance regular trip', () {
      final result = PricingService.computeLocal(
        tripType: TripType.regular,
        distanceKm: 0,
        durationMinutes: 0,
      );

      expect(result.totalAmount, 250.0);
      expect(result.minimumFareApplied, true);
      expect(result.isFallback, true);
    });

    test('computes a standard regular trip the same as the server formula', () {
      // 150 base + (5 km × 35) + (10 min × 5) = 375
      final result = PricingService.computeLocal(
        tripType: TripType.regular,
        distanceKm: 5,
        durationMinutes: 10,
      );

      expect(result.baseFare, 150.0);
      expect(result.distanceAmount, 175.0);
      expect(result.timeAmount, 50.0);
      expect(result.subtotal, 375.0);
      expect(result.totalAmount, 375.0);
      expect(result.minimumFareApplied, false);
      expect(result.isFallback, true);
    });

    test('applies surge multiplier on regular trips', () {
      final result = PricingService.computeLocal(
        tripType: TripType.regular,
        distanceKm: 5,
        durationMinutes: 10,
        surge: SurgeLevel.maximum,
      );

      expect(result.surgeMultiplier, 2.0);
      expect(result.totalAmount, 750.0);
    });

    test('does not apply surge on airport trips', () {
      final result = PricingService.computeLocal(
        tripType: TripType.airport,
        distanceKm: 10,
        durationMinutes: 0,
        surge: SurgeLevel.maximum,
      );

      expect(result.surgeMultiplier, 1.0);
      expect(result.totalAmount, 800.0);
    });

    test('enforces 2-hour minimum on event trips', () {
      final result = PricingService.computeLocal(
        tripType: TripType.event,
        distanceKm: 0,
        durationMinutes: 0,
        hours: 1,
      );

      expect(result.timeAmount, 1600.0); // 2h × 800
      expect(result.totalAmount, 2100.0);
    });

    test('computes netAmount = totalAmount - commissionAmount', () {
      final result = PricingService.computeLocal(
        tripType: TripType.regular,
        distanceKm: 8,
        durationMinutes: 15,
      );

      expect(result.netAmount, closeTo(result.totalAmount - result.commissionAmount, 0.01));
    });
  });
}
