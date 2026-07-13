import 'package:flutter_test/flutter_test.dart';
import 'package:limousineexecutive/services/messaging_service.dart';

void main() {
  group('NotificationPayload.encode/tryParse', () {
    test('round-trips a payload with type and tripId', () {
      const original = NotificationPayload(type: 'new_trip', tripId: 'abc123');

      final parsed = NotificationPayload.tryParse(original.encode());

      expect(parsed, isNotNull);
      expect(parsed!.type, 'new_trip');
      expect(parsed.tripId, 'abc123');
    });

    test('round-trips a payload with null tripId', () {
      const original = NotificationPayload(type: 'trip_completed');

      final parsed = NotificationPayload.tryParse(original.encode());

      expect(parsed, isNotNull);
      expect(parsed!.type, 'trip_completed');
      expect(parsed.tripId, isNull);
    });

    test('returns null for null or empty input', () {
      expect(NotificationPayload.tryParse(null), isNull);
      expect(NotificationPayload.tryParse(''), isNull);
    });

    test('accepts a bare legacy type string as a fallback', () {
      // Older builds used to pass message.data['type'] as the raw payload.
      final parsed = NotificationPayload.tryParse('trip_accepted');

      expect(parsed, isNotNull);
      expect(parsed!.type, 'trip_accepted');
      expect(parsed.tripId, isNull);
    });

    test('returns null when JSON lacks a string "type"', () {
      expect(NotificationPayload.tryParse('{"tripId":"x"}'), isNull);
    });
  });
}
