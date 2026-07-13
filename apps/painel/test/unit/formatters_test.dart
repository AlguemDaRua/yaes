import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ya_painel/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
    YaFormat.init();
  });

  group('YaFormat.currency', () {
    test('formats MTn values with suffix and spaced thousands', () {
      expect(YaFormat.currency(1234), '1 234 MTn');
      expect(YaFormat.currencyNoSuffix(1234567), '1 234 567');
    });

    test('formats zero values', () {
      expect(YaFormat.currency(0), '0 MTn');
    });

    test('formats compact values', () {
      expect(YaFormat.currency(1250000, compact: true), '1,25M MTn');
      expect(YaFormat.currency(28000, compact: true), '28K MTn');
    });
  });

  group('YaFormat.phone', () {
    test('formats national and full Mozambique numbers', () {
      expect(YaFormat.phone('841234567'), '+258 84 123 4567');
      expect(YaFormat.phone('+258841234567'), '+258 84 123 4567');
    });

    test('returns raw value when number length is invalid', () {
      expect(YaFormat.phone('123'), '123');
    });
  });

  test('formats NUIT values', () {
    expect(YaFormat.nuit('400123456'), '400 123 456');
    expect(YaFormat.nuit('40012345'), '40012345');
  });

  test('formats license plates', () {
    expect(YaFormat.licensePlate('aaa123mp'), 'AAA-123-MP');
    expect(YaFormat.licensePlate('AB123'), 'AB123');
  });

  test('formats date and time values in pt_PT', () {
    final value = DateTime(2026, 5, 3, 14, 32);

    expect(YaFormat.dateShort(value), '03/05/2026');
    expect(YaFormat.dateLong(value), contains('2026'));
    expect(YaFormat.dateTime(value), '03/05/2026 14:32');
    expect(YaFormat.timeOnly(value), '14:32');
  });

  test('formats relative dates', () {
    final value = DateTime.now().subtract(const Duration(minutes: 5));

    expect(YaFormat.relative(value), isNotEmpty);
  });

  test('formats distance, duration, ratings, percentages and counts', () {
    expect(YaFormat.distance(12.4), '12,4 km');
    expect(YaFormat.duration(25), '25 min');
    expect(YaFormat.duration(75), '1h 15min');
    expect(YaFormat.rating(4.8), '4,8 ★');
    expect(YaFormat.percent(12), '12%');
    expect(YaFormat.percent(12.5), '12,5%');
    expect(YaFormat.count(0), '—');
    expect(YaFormat.count(null), '—');
    expect(YaFormat.count(1234), '1 234');
  });

  test('formats percent changes', () {
    expect(YaFormat.percentChange(12, 10), '12% → 10%');
  });
}
