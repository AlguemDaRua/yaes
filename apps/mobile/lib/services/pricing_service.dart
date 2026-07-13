import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';

enum TripType { regular, scheduled, airport, event }

enum SurgeLevel { normal, moderate, high, extreme, maximum }

class PricingResult {
  final String tripType;
  final double baseFare;
  final double distanceAmount;
  final double timeAmount;
  final double subtotal;
  final double surgeMultiplier;
  final double totalAmount;
  final double minimumFare;
  final bool minimumFareApplied;
  final double commissionRate;
  final double commissionAmount;
  final double netAmount;
  final bool isFallback;

  const PricingResult({
    required this.tripType,
    required this.baseFare,
    required this.distanceAmount,
    required this.timeAmount,
    required this.subtotal,
    required this.surgeMultiplier,
    required this.totalAmount,
    required this.minimumFare,
    required this.minimumFareApplied,
    required this.commissionRate,
    required this.commissionAmount,
    required this.netAmount,
    this.isFallback = false,
  });

  factory PricingResult.fromMap(Map<String, dynamic> map) {
    return PricingResult(
      tripType: map['tripType'] as String,
      baseFare: (map['baseFare'] as num).toDouble(),
      distanceAmount: (map['distanceAmount'] as num).toDouble(),
      timeAmount: (map['timeAmount'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      surgeMultiplier: (map['surgeMultiplier'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      minimumFare: (map['minimumFare'] as num).toDouble(),
      minimumFareApplied: map['minimumFareApplied'] as bool,
      commissionRate: (map['commissionRate'] as num).toDouble(),
      commissionAmount: (map['commissionAmount'] as num).toDouble(),
      netAmount: (map['netAmount'] as num).toDouble(),
    );
  }
}

/// Client-side fare tables. MUST match functions/src/pricing.ts — kept in sync
/// as a best-effort fallback when the Cloud Function is unreachable.
class _Fare {
  final double baseFare;
  final double perKm;
  final double perMinute;
  final double perHour;
  final double minimumHours;
  final double minimumFare;
  final double commission;
  final bool surgeAllowed;

  const _Fare({
    required this.baseFare,
    required this.perKm,
    required this.perMinute,
    required this.perHour,
    required this.minimumHours,
    required this.minimumFare,
    required this.commission,
    required this.surgeAllowed,
  });
}

const Map<TripType, _Fare> _fares = {
  TripType.regular: _Fare(
    baseFare: 150,
    perKm: 35,
    perMinute: 5,
    perHour: 0,
    minimumHours: 0,
    minimumFare: 250,
    commission: 0.12,
    surgeAllowed: true,
  ),
  TripType.scheduled: _Fare(
    baseFare: 165,
    perKm: 35,
    perMinute: 5,
    perHour: 0,
    minimumHours: 0,
    minimumFare: 275,
    commission: 0.10,
    surgeAllowed: true,
  ),
  TripType.airport: _Fare(
    baseFare: 500,
    perKm: 30,
    perMinute: 0,
    perHour: 0,
    minimumHours: 0,
    minimumFare: 500,
    commission: 0.15,
    surgeAllowed: false,
  ),
  TripType.event: _Fare(
    baseFare: 500,
    perKm: 20,
    perMinute: 0,
    perHour: 800,
    minimumHours: 2,
    minimumFare: 2100,
    commission: 0.10,
    surgeAllowed: false,
  ),
};

const Map<SurgeLevel, double> _surgeMultipliers = {
  SurgeLevel.normal: 1.0,
  SurgeLevel.moderate: 1.3,
  SurgeLevel.high: 1.5,
  SurgeLevel.extreme: 1.8,
  SurgeLevel.maximum: 2.0,
};

double _round2(double v) => (v * 100).roundToDouble() / 100;

/// Car category shown in the showcase — mirrors /config/pricing/categories.
class CarCategory {
  final String id;
  final String label;
  final double multiplier;
  final int seats;
  final int order;

  const CarCategory({
    required this.id,
    required this.label,
    required this.multiplier,
    required this.seats,
    required this.order,
  });
}

/// Fallback quando /config/pricing/categories não existe ou está inacessível.
/// Espelha a operação real (Nampula): só moto + económico. Outras categorias
/// (sedan, SUV, …) só aparecem se a operação as activar no painel — o config
/// é a fonte da verdade, nunca este fallback.
const List<CarCategory> kDefaultCategories = [
  // multiplier deriva do preço real da gasolina (93,86 MT/L, jun/2026): ~15 MT
  // bandeirada + ~7,5 MT/km sobre a tarifa regular (150 base + 35/km) = 0,214x
  // — ver Downloads/YA-Plano-Fecho.md B2.3.
  CarCategory(
    id: 'moto',
    label: 'Moto',
    multiplier: 0.214,
    seats: 1,
    order: 0,
  ),
  CarCategory(
    id: 'txopela',
    label: 'Txopela',
    multiplier: 0.7,
    seats: 3,
    order: 1,
  ),
  CarCategory(
    id: 'economico',
    label: 'Económico',
    multiplier: 1.0,
    seats: 5,
    order: 2,
  ),
];

class PricingService {
  static final _functions = FirebaseFunctions.instance;

  static List<CarCategory>? _cachedCategories;
  static DateTime? _categoriesFetchedAt;

  /// Reads /config/pricing/categories with a 10-minute in-memory cache.
  /// Falls back to [kDefaultCategories] when absent or unreachable.
  static Future<List<CarCategory>> fetchCategories() async {
    final cached = _cachedCategories;
    final at = _categoriesFetchedAt;
    if (cached != null &&
        at != null &&
        DateTime.now().difference(at) < const Duration(minutes: 10)) {
      return cached;
    }
    try {
      final snap = await FirebaseDatabase.instance
          .ref('config/pricing/categories')
          .get();
      final value = snap.value;
      if (value is Map && value.isNotEmpty) {
        final categories = <CarCategory>[];
        value.forEach((key, raw) {
          if (raw is! Map) return;
          final m = raw['multiplier'];
          categories.add(
            CarCategory(
              id: key.toString(),
              label: (raw['label'] ?? key).toString(),
              multiplier: m is num && m > 0 ? m.toDouble() : 1.0,
              seats: raw['seats'] is num ? (raw['seats'] as num).toInt() : 4,
              order: raw['order'] is num ? (raw['order'] as num).toInt() : 99,
            ),
          );
        });
        categories.sort((a, b) => a.order.compareTo(b.order));
        _cachedCategories = categories;
        _categoriesFetchedAt = DateTime.now();
        return categories;
      }
    } catch (_) {
      // unreachable → fallback below
    }
    return kDefaultCategories;
  }

  /// Multiplier for a category id, using the cache/defaults (no await needed
  /// for the local estimate path).
  static double categoryMultiplier(String? category) {
    if (category == null) return 1.0;
    final source = _cachedCategories ?? kDefaultCategories;
    for (final c in source) {
      if (c.id == category) return c.multiplier;
    }
    return 1.0;
  }

  /// Calls the calculatePrice Cloud Function and returns the server-validated price.
  /// [tripType] — trip type: regular, scheduled, airport, event
  /// [distanceKm] — distance calculated by Mapbox
  /// [durationMinutes] — estimated duration
  /// [surge] — surge pricing level (default: normal)
  /// [hours] — required for event trip type
  static Future<PricingResult> calculate({
    required TripType tripType,
    required double distanceKm,
    required double durationMinutes,
    SurgeLevel surge = SurgeLevel.normal,
    double? hours,
    String? category,
  }) async {
    final callable = _functions.httpsCallable('calculatePrice');

    final result = await callable.call({
      'tripType': tripType.name,
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'surge': surge.name,
      if (hours != null) 'hours': hours,
      if (category != null) 'category': category,
    });

    return PricingResult.fromMap(Map<String, dynamic>.from(result.data as Map));
  }

  /// Client-side fallback — same formula as the Cloud Function. Used when
  /// the server is unreachable so the UI can show a plausible estimate.
  /// The resulting [PricingResult.isFallback] is true.
  static PricingResult computeLocal({
    required TripType tripType,
    required double distanceKm,
    required double durationMinutes,
    SurgeLevel surge = SurgeLevel.normal,
    double? hours,
    String? category,
  }) {
    final fare = _fares[tripType]!;
    final surgeMultiplier = fare.surgeAllowed
        ? (_surgeMultipliers[surge] ?? 1.0)
        : 1.0;
    final catMultiplier = categoryMultiplier(category);

    final distanceAmount = distanceKm * fare.perKm;
    double timeAmount;
    if (tripType == TripType.event) {
      final effectiveHours = ((hours ?? 0) < fare.minimumHours)
          ? fare.minimumHours
          : (hours ?? 0);
      timeAmount = effectiveHours * fare.perHour;
    } else {
      timeAmount = durationMinutes * fare.perMinute;
    }

    final subtotal = fare.baseFare + distanceAmount + timeAmount;
    // The category multiplier scales the whole fare, minimum included —
    // mirrors functions/src/pricing.ts.
    final subtotalWithSurge = subtotal * surgeMultiplier * catMultiplier;
    final minimumFare = _round2(fare.minimumFare * catMultiplier);
    final minimumFareApplied = subtotalWithSurge < minimumFare;
    final totalAmount = _round2(
      subtotalWithSurge < minimumFare ? minimumFare : subtotalWithSurge,
    );
    final commissionAmount = _round2(totalAmount * fare.commission);
    final netAmount = _round2(totalAmount - commissionAmount);

    return PricingResult(
      tripType: tripType.name,
      baseFare: fare.baseFare,
      distanceAmount: _round2(distanceAmount),
      timeAmount: _round2(timeAmount),
      subtotal: _round2(subtotal),
      surgeMultiplier: surgeMultiplier,
      totalAmount: totalAmount,
      minimumFare: minimumFare,
      minimumFareApplied: minimumFareApplied,
      commissionRate: fare.commission,
      commissionAmount: commissionAmount,
      netAmount: netAmount,
      isFallback: true,
    );
  }
}
