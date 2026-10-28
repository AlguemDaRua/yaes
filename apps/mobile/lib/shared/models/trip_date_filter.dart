import 'package:intl/intl.dart';

enum TripDateFilterType { today, lastSevenDays, custom }

/// A local-calendar date range with inclusive start and end days.
class TripDateFilter {
  const TripDateFilter({
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  final TripDateFilterType type;
  final DateTime startDate;
  final DateTime endDate;

  factory TripDateFilter.today({DateTime? referenceDate}) {
    final today = _localDay(referenceDate ?? DateTime.now());
    return TripDateFilter(
      type: TripDateFilterType.today,
      startDate: today,
      endDate: today,
    );
  }

  factory TripDateFilter.lastSevenDays({DateTime? referenceDate}) {
    final today = _localDay(referenceDate ?? DateTime.now());
    return TripDateFilter(
      type: TripDateFilterType.lastSevenDays,
      startDate: DateTime(today.year, today.month, today.day - 6),
      endDate: today,
    );
  }

  factory TripDateFilter.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = _localDay(startDate);
    final end = _localDay(endDate);
    if (end.isBefore(start)) {
      throw ArgumentError('A data final não pode anteceder a data inicial.');
    }
    return TripDateFilter(
      type: TripDateFilterType.custom,
      startDate: start,
      endDate: end,
    );
  }

  bool includes(DateTime? date) {
    if (date == null) return false;
    final localDate = date.toLocal();
    final firstIncluded = startDate;
    final firstExcluded = DateTime(
      endDate.year,
      endDate.month,
      endDate.day + 1,
    );
    return !localDate.isBefore(firstIncluded) &&
        localDate.isBefore(firstExcluded);
  }

  String get label => switch (type) {
    TripDateFilterType.today => 'Hoje',
    TripDateFilterType.lastSevenDays => 'Últimos 7 dias',
    TripDateFilterType.custom =>
      '${_formatDay(startDate)} – ${_formatDay(endDate)}',
  };

  static DateTime _localDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String _formatDay(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);
}

class TripDateFilterResult {
  const TripDateFilterResult(this.filter);

  final TripDateFilter? filter;
}
