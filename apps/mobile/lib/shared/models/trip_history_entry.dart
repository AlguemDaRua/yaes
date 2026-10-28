import 'package:intl/intl.dart';

/// Safe, display-ready view of a trip stored in the Realtime Database.
///
/// The database keeps its existing field names and status codes; this model
/// normalizes optional/legacy values for the passenger and driver histories.
class TripHistoryEntry {
  const TripHistoryEntry({
    required this.id,
    required this.status,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.tripType,
    required this.vehicleCategory,
    required this.createdAt,
    required this.passengerName,
    required this.driverName,
    required this.amountMtn,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.distanceKm,
    required this.durationMinutes,
    required this.cancelledBy,
    required this.cancellationReason,
    required this.cancelledAt,
  });

  final String id;
  final String status;
  final String origin;
  final String destination;
  final List<String> stops;
  final String tripType;
  final String vehicleCategory;
  final DateTime? createdAt;
  final String? passengerName;
  final String? driverName;
  final num? amountMtn;
  final String paymentMethod;
  final String paymentStatus;
  final double? distanceKm;
  final double? durationMinutes;
  final String cancelledBy;
  final String cancellationReason;
  final DateTime? cancelledAt;

  bool get isCancelled => status == 'cancelled';

  String get statusLabel => switch (status) {
    'pending' => 'Pendente',
    'awaiting_payment' => 'A aguardar pagamento',
    'accepted' => 'Aceite',
    'started' => 'Em andamento',
    'completed' => 'Concluída',
    'cancelled' => 'Cancelada',
    'no_driver_available' => 'Sem motorista disponível',
    _ => status.isEmpty ? 'Estado não informado' : status,
  };

  String get tripTypeLabel => switch (tripType) {
    'regular' => 'Regular',
    'scheduled' => 'Agendada',
    'airport' => 'Aeroporto',
    'event' => 'Evento',
    _ => tripType.isEmpty ? 'Não informado' : tripType,
  };

  String get amountLabel {
    final amount = amountMtn;
    if (amount == null) return 'Não registado';
    return '${NumberFormat('#,##0.##', 'pt_BR').format(amount)} MT';
  }

  String get createdAtLabel => _formatDateTime(createdAt);

  String get cancelledAtLabel => _formatDateTime(cancelledAt);

  String? get distanceLabel {
    final distance = distanceKm;
    if (distance == null || distance <= 0) return null;
    return '${distance.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  String? get durationLabel {
    final duration = durationMinutes;
    if (duration == null || duration <= 0) return null;
    return '${duration.round()} min';
  }

  factory TripHistoryEntry.fromMap(Map<String, dynamic> trip) {
    final timestamps = _asStringMap(trip['timestamps']);
    final rawCategory = _text(trip['carCategory']) ??
        _text(trip['vehicleCategory']) ??
        '';
    final rawCancelledBy = _text(trip['cancelledBy'])?.toLowerCase();
    final rawPaymentMethod = _text(trip['paymentMethod'])?.toLowerCase();
    final rawPaymentStatus = _text(trip['paymentStatus'])?.toLowerCase();
    final rawStatus = _text(trip['status'])?.toLowerCase() ?? '';

    return TripHistoryEntry(
      id: _text(trip['id']) ?? '',
      status: rawStatus,
      origin: _locationLabel(trip['origin'], 'Local de recolha'),
      destination: _locationLabel(trip['destination'], 'Destino'),
      stops: _stopLabels(trip['stops']),
      tripType: (_text(trip['tripType']) ?? _text(trip['tipo']) ?? '')
          .toLowerCase(),
      vehicleCategory: _vehicleCategoryLabel(rawCategory),
      createdAt: _parseDate(timestamps?['created']) ??
          _parseDate(trip['createdAt']),
      passengerName: _text(trip['passengerName']),
      driverName: _text(trip['driverName']),
      amountMtn: _number(trip['finalPrice']) ??
          _number(trip['amountMtn']) ??
          _number(trip['estimatedPrice']),
      paymentMethod: _paymentMethodLabel(rawPaymentMethod),
      paymentStatus: _paymentStatusLabel(rawPaymentStatus),
      distanceKm: _number(trip['distanceKm'])?.toDouble(),
      durationMinutes: _number(trip['durationMinutes'])?.toDouble(),
      cancelledBy: _cancelledByLabel(rawCancelledBy),
      cancellationReason:
          _text(trip['cancellationReason']) ?? 'Motivo não informado',
      cancelledAt: _parseDate(trip['cancelledAt']) ??
          _parseDate(timestamps?['cancelled']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value.toLocal();
    final raw = _text(value);
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.toLocal();
    final numeric = int.tryParse(raw);
    if (numeric == null) return null;
    final milliseconds = numeric.abs() < 100000000000
        ? numeric * 1000
        : numeric;
    return DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
      isUtc: true,
    ).toLocal();
  }

  static String _formatDateTime(DateTime? date) {
    if (date == null) return 'Data não disponível';
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  static Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is! Map) return null;
    return <String, dynamic>{
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
  }

  static String? _text(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static num? _number(dynamic value) {
    if (value is num) return value;
    final raw = _text(value);
    if (raw == null) return null;
    return num.tryParse(raw.replaceAll(',', '.'));
  }

  static String _locationLabel(dynamic value, String fallback) {
    final location = _asStringMap(value);
    if (location != null) {
      return _text(location['name']) ??
          _text(location['fullName']) ??
          fallback;
    }
    return _text(value) ?? fallback;
  }

  static List<String> _stopLabels(dynamic value) {
    if (value is List) {
      return List<String>.unmodifiable(value.map(_stopLabel));
    }
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return List<String>.unmodifiable(
        entries.map((entry) => _stopLabel(entry.value)),
      );
    }
    return const <String>[];
  }

  static String _stopLabel(dynamic value) {
    final stop = _asStringMap(value);
    if (stop != null) {
      return _text(stop['name']) ?? _text(stop['fullName']) ?? 'Paragem';
    }
    return _text(value) ?? 'Paragem';
  }

  static String _vehicleCategoryLabel(String category) => switch (category) {
    'economico' => 'Económico',
    'confort' => 'Confort',
    'txopela' => 'Txopela',
    'moto' => 'Moto',
    _ => category.isEmpty ? 'Não informada' : category,
  };

  static String _paymentMethodLabel(String? method) => switch (method) {
    'cash' || 'dinheiro' => 'Dinheiro',
    'mpesa' || 'm-pesa' => 'M-Pesa',
    'emola' || 'e-mola' => 'e-Mola',
    'cartao' || 'cartão' || 'card' || 'credit_card' => 'Cartão',
    null => 'Não registado',
    _ => method ?? 'Não registado',
  };

  static String _paymentStatusLabel(String? status) => switch (status) {
    'pending' => 'Pendente',
    'paid' => 'Pago',
    'failed' => 'Falhou',
    'refunded' => 'Reembolsado',
    'processing' => 'Em processamento',
    null => 'Não registado',
    _ => status ?? 'Não registado',
  };

  static String _cancelledByLabel(String? actor) => switch (actor) {
    'passenger' => 'Passageiro',
    'driver' => 'Motorista',
    'system' => 'Sistema',
    _ => 'Não informado',
  };
}
