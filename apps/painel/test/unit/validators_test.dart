import 'package:flutter_test/flutter_test.dart';
import 'package:ya_painel/core/validators/ya_validators.dart';

void main() {
  group('YaValidators.required', () {
    test('rejects null and blank values', () {
      expect(YaValidators.required(null), isNotNull);
      expect(YaValidators.required('   '), isNotNull);
    });

    test('accepts non-empty values', () {
      expect(YaValidators.required('YA'), isNull);
    });
  });

  group('YaValidators.email', () {
    test('accepts valid email addresses', () {
      expect(YaValidators.email('admin@ya.co.mz'), isNull);
    });

    test('rejects invalid email addresses', () {
      expect(YaValidators.email('admin'), isNotNull);
      expect(YaValidators.email('admin@'), isNotNull);
      expect(YaValidators.email(''), isNotNull);
    });
  });

  group('YaValidators.phone', () {
    test('accepts Mozambique phone formats and prefixes', () {
      expect(YaValidators.phone('841234567'), isNull);
      expect(YaValidators.phone('+258 84 123 4567'), isNull);
      expect(YaValidators.phone('258871234567'), isNull);
    });

    test('rejects invalid lengths and prefixes', () {
      expect(YaValidators.phone('84123'), isNotNull);
      expect(YaValidators.phone('891234567'), isNotNull);
    });

    test('accepts all configured operator prefixes', () {
      for (final prefix in <String>['82', '83', '84', '85', '86', '87']) {
        expect(YaValidators.phone('${prefix}1234567'), isNull);
      }
    });
  });

  group('YaValidators.nuit', () {
    test('accepts exactly nine digits after formatting is removed', () {
      expect(YaValidators.nuit('400123456'), isNull);
      expect(YaValidators.nuit('400 123 456'), isNull);
    });

    test('rejects invalid lengths', () {
      expect(YaValidators.nuit('40012345'), isNotNull);
      expect(YaValidators.nuit('4001234567'), isNotNull);
    });
  });

  group('YaValidators.licensePlate', () {
    test('accepts canonical Mozambique plate formats', () {
      expect(YaValidators.licensePlate('AAA-123-MP'), isNull);
      expect(YaValidators.licensePlate('aaa123mc'), isNull);
    });

    test('rejects malformed plates', () {
      expect(YaValidators.licensePlate('AA-123-MP'), isNotNull);
      expect(YaValidators.licensePlate('AAA-ABC-MP'), isNotNull);
    });
  });

  group('YaValidators.numberInRange', () {
    test('accepts values in range with dot or comma decimals', () {
      final validator = YaValidators.numberInRange(0, 100, 'Valor');

      expect(validator('50'), isNull);
      expect(validator('12,5'), isNull);
    });

    test('rejects blank, non-numeric and out-of-range values', () {
      final validator = YaValidators.numberInRange(1, 60, 'Lugares');

      expect(validator(''), isNotNull);
      expect(validator('abc'), isNotNull);
      expect(validator('0'), isNotNull);
      expect(validator('61'), isNotNull);
    });
  });

  group('YaValidators domain numeric helpers', () {
    test('validates commission rates', () {
      expect(YaValidators.commissionRate('12'), isNull);
      expect(YaValidators.commissionRate('101'), isNotNull);
    });

    test('validates vehicle seats', () {
      expect(YaValidators.vehicleSeats('4'), isNull);
      expect(YaValidators.vehicleSeats('0'), isNotNull);
    });

    test('validates vehicle year against the current year', () {
      final currentYear = DateTime.now().year;

      expect(YaValidators.vehicleYear('$currentYear'), isNull);
      expect(YaValidators.vehicleYear('${currentYear + 2}'), isNotNull);
    });
  });

  group('YaValidators date helpers', () {
    test('futureDate rejects null and past dates', () {
      final validator = YaValidators.futureDate('Documento');

      expect(validator(null), isNotNull);
      expect(
        validator(DateTime.now().subtract(const Duration(days: 1))),
        isNotNull,
      );
    });

    test('futureDate accepts future dates', () {
      final validator = YaValidators.futureDate('Documento');

      expect(validator(DateTime.now().add(const Duration(days: 1))), isNull);
    });

    test('licenseExpiry rejects null and dates under 30 days away', () {
      expect(YaValidators.licenseExpiry(null), isNotNull);
      expect(
        YaValidators.licenseExpiry(
          DateTime.now().add(const Duration(days: 10)),
        ),
        isNotNull,
      );
    });

    test('licenseExpiry accepts dates beyond 30 days away', () {
      expect(
        YaValidators.licenseExpiry(
          DateTime.now().add(const Duration(days: 31)),
        ),
        isNull,
      );
    });
  });

  group('YaValidators.minLength', () {
    final validator = YaValidators.minLength(5);

    test('rejects values shorter than the minimum', () {
      expect(validator('abc'), isNotNull);
    });

    test('accepts values at the minimum', () {
      expect(validator('abcde'), isNull);
    });
  });

  group('YaValidators.maxLength', () {
    final validator = YaValidators.maxLength(5);

    test('accepts values under the maximum', () {
      expect(validator('abc'), isNull);
    });

    test('rejects values over the maximum', () {
      expect(validator('abcdef'), isNotNull);
    });
  });

  test('compose returns the first validation error', () {
    final validator = YaValidators.compose([
      YaValidators.required,
      YaValidators.email,
    ]);

    expect(validator(''), isNotNull);
    expect(validator('invalid'), isNotNull);
    expect(validator('admin@ya.co.mz'), isNull);
  });
}
