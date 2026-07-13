import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../constants/ya_constants.dart';

/// Formatters YA — foundations §7.5.
///
/// Garantem consistência de output em toda a UI. **Nunca** formatar
/// inline com `${value} MTn`; usar sempre estes helpers.
abstract class YaFormat {
  /// Inicializar locale pt_PT em timeago. Chamar uma vez em main().
  static void init() {
    timeago.setLocaleMessages('pt_PT', timeago.PtBrMessages());
    timeago.setDefaultLocale('pt_PT');
  }

  // === Moeda ===

  /// `1234` → `"1 234 MTn"`
  /// `1234567` → `"1 234 567 MTn"`
  /// `1250000` → `"1,25M MTn"` (se compact=true)
  static String currency(num value, {bool compact = false}) {
    if (compact && value.abs() >= 1000000) {
      final inMillions = value / 1000000;
      final formatted = NumberFormat('#,##0.##', 'pt_PT').format(inMillions);
      return '${formatted}M ${YaConstants.currencySuffix}';
    }
    if (compact && value.abs() >= 10000) {
      final inThousands = value / 1000;
      final formatted = NumberFormat('#,##0', 'pt_PT').format(inThousands);
      return '${formatted}K ${YaConstants.currencySuffix}';
    }
    final formatted = NumberFormat('#,##0', 'pt_PT').format(value);
    // pt_PT usa "." como milhares; substituímos por espaço para alinhar com spec
    final withSpaces = _normalizeThousands(formatted);
    return '$withSpaces ${YaConstants.currencySuffix}';
  }

  /// Versão sem sufixo, útil em colunas de tabela com header "MTn"
  static String currencyNoSuffix(num value) {
    final formatted = NumberFormat('#,##0', 'pt_PT').format(value);
    return _normalizeThousands(formatted);
  }

  // === Telefone ===

  /// `'841234567'` → `"+258 84 123 4567"`
  /// `'+258841234567'` → `"+258 84 123 4567"`
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final national = digits.startsWith('258') ? digits.substring(3) : digits;
    if (national.length != 9) return raw; // fallback se inválido
    return '${YaConstants.countryCode} ${national.substring(0, 2)} '
        '${national.substring(2, 5)} ${national.substring(5)}';
  }

  // === NUIT ===

  /// `'400123456'` → `"400 123 456"`
  static String nuit(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != YaConstants.nuitLength) return raw;
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} '
        '${digits.substring(6)}';
  }

  // === Matrícula ===

  /// `'AAA123MP'` → `"AAA-123-MP"`
  static String licensePlate(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (clean.length < 6) return raw;
    // Formato esperado: 3 letras + 3 dígitos + 2 letras
    return '${clean.substring(0, 3)}-${clean.substring(3, 6)}-'
        '${clean.length >= 8 ? clean.substring(6, 8) : clean.substring(6)}';
  }

  // === Datas ===

  static final _shortDate = DateFormat('dd/MM/yyyy', 'pt_PT');
  static final _longDate = DateFormat("d 'de' MMMM 'de' yyyy", 'pt_PT');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_PT');
  static final _timeOnly = DateFormat('HH:mm', 'pt_PT');

  /// `"03/05/2026"`
  static String dateShort(DateTime date) => _shortDate.format(date);

  /// `"3 de Maio de 2026"`
  static String dateLong(DateTime date) => _longDate.format(date);

  /// `"03/05/2026 14:32"`
  static String dateTime(DateTime date) => _dateTime.format(date);

  /// `"14:32"`
  static String timeOnly(DateTime date) => _timeOnly.format(date);

  /// `"há 5 minutos"` / `"há 2 horas"` / `"ontem"`
  static String relative(DateTime date) =>
      timeago.format(date, locale: 'pt_PT');

  // === Distância e duração ===

  /// `12.4` → `"12,4 km"`
  static String distance(double km) {
    final formatted = NumberFormat('#,##0.0', 'pt_PT').format(km);
    return '$formatted km';
  }

  /// `25` → `"25 min"`; `75` → `"1h 15min"`
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}min';
  }

  // === Rating ===

  /// `4.8` → `"4,8 ★"`
  static String rating(double value) {
    final formatted = NumberFormat('#,##0.0', 'pt_PT').format(value);
    return '$formatted ★';
  }

  // === Percentagem ===

  /// `12` → `"12%"`; `12.5` → `"12,5%"`
  static String percent(num value) {
    if (value == value.truncate()) return '${value.toInt()}%';
    return '${NumberFormat('#,##0.0', 'pt_PT').format(value)}%';
  }

  /// Útil para diff de comissão (ex: 12% → 10%)
  static String percentChange(num from, num to) {
    return '${percent(from)} → ${percent(to)}';
  }

  // === Counts compactos ===

  /// `0` → `"—"`; `1234` → `"1 234"`
  static String count(num? value) {
    if (value == null || value == 0) return '—';
    final formatted = NumberFormat('#,##0', 'pt_PT').format(value);
    return _normalizeThousands(formatted);
  }

  static String _normalizeThousands(String value) {
    return value
        .replaceAll('.', ' ')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u202F', ' ');
  }
}
