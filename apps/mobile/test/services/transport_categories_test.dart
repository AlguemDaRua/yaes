import 'package:flutter_test/flutter_test.dart';
import 'package:limousineexecutive/services/pricing_service.dart';

void main() {
  test('catalogue contains the four current types in presentation order', () {
    final categories = parseCarCategories(null);
    expect(categories.map((c) => c.id), [
      'economico',
      'confort',
      'txopela',
      'moto',
    ]);
    expect(categories.map((c) => c.label), [
      'Económico',
      'Confort',
      'Txopela',
      'Moto',
    ]);
  });

  test('remote rates survive old labels and missing categories', () {
    final categories = parseCarCategories({
      'moto': {
        'label': 'Motorizada',
        'order': 0,
        'multiplier': 0.5,
        'seats': 1,
      },
      'confort': {'multiplier': 1.6, 'seats': 4},
      'luxo': {'multiplier': 3},
    });
    expect(categories.length, 4);
    expect(categories.last.label, 'Moto');
    expect(categories.last.multiplier, 0.5);
    expect(categories[1].multiplier, 1.6);
    expect(categories[1].seats, 4);
    expect(categories[2].id, 'txopela');
  });

  test('malformed remote values use safe defaults', () {
    final categories = parseCarCategories({
      'economico': {'multiplier': -1, 'seats': 0},
      'confort': 'invalid',
      'moto': {'multiplier': double.nan},
    });
    expect(categories.first.multiplier, 1);
    expect(categories.first.seats, 5);
    expect(categories[1].multiplier, 1.35);
    expect(categories.last.multiplier.isFinite, isTrue);
  });
}
