import 'package:flutter_test/flutter_test.dart';
import 'package:limousineexecutive/services/wallet_service.dart';

void main() {
  group('DriverWallet.fromMap', () {
    test('parses balance, blockedAt and sorts entries newest-first', () {
      final wallet = DriverWallet.fromMap({
        'balance': -340,
        'blockedAt': '2026-06-27T10:00:00.000Z',
        'entries': {
          'TRP-1': {
            'type': 'commission',
            'amountMtn': -40,
            'tripId': 'TRP-1',
            'createdAt': '2026-06-25T08:00:00.000Z',
          },
          'topup-1': {
            'type': 'topup',
            'amountMtn': 500,
            'mpesaRef': 'MP123',
            'createdAt': '2026-06-26T09:00:00.000Z',
          },
        },
      });

      expect(wallet.balance, -340);
      expect(wallet.isBlocked, isTrue);
      expect(wallet.entries, hasLength(2));
      expect(wallet.entries.first.type, 'topup');
      expect(wallet.entries.first.amountMtn, 500);
      expect(wallet.entries.first.reference, 'MP123');
      expect(wallet.entries.last.type, 'commission');
      expect(wallet.entries.last.reference, 'TRP-1');
    });

    test('handles missing fields and no entries', () {
      final wallet = DriverWallet.fromMap({});
      expect(wallet.balance, 0);
      expect(wallet.isBlocked, isFalse);
      expect(wallet.entries, isEmpty);
    });

    test('rounds non-integer amounts', () {
      final wallet = DriverWallet.fromMap({
        'balance': 99.6,
        'entries': {
          'e1': {'type': 'adjustment', 'amountMtn': 10.4},
        },
      });
      expect(wallet.balance, 100);
      expect(wallet.entries.single.amountMtn, 10);
    });
  });
}
