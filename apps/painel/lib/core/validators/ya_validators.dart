import '../constants/ya_constants.dart';

/// Validators YA — alinhados com os schemas Zod do documento de regras §8.
///
/// Cada validator devolve `null` se válido ou string com mensagem em pt-PT.
/// Compatível com TextFormField validators e reactive_forms.
abstract class YaValidators {
  // === Genéricos ===

  static String? required(String? value, [String fieldName = 'Campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  static String? Function(String?) minLength(int min, [String? fieldName]) {
    return (value) {
      if (value == null || value.trim().length < min) {
        return '${fieldName ?? 'Campo'} deve ter pelo menos $min caracteres';
      }
      return null;
    };
  }

  static String? Function(String?) maxLength(int max, [String? fieldName]) {
    return (value) {
      if (value != null && value.length > max) {
        return '${fieldName ?? 'Campo'} pode ter no máximo $max caracteres';
      }
      return null;
    };
  }

  // === Email ===

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email é obrigatório';
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Email inválido';
    }
    return null;
  }

  // === Telefone moçambicano ===

  /// Aceita formatos: 841234567, +258841234567, +258 84 123 4567
  /// Operadoras: 82, 83 (Tmcel), 84, 85 (Vodacom), 86, 87 (Movitel)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefone é obrigatório';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final national = digits.startsWith('258') ? digits.substring(3) : digits;
    if (national.length != YaConstants.phoneLengthAfterCc) {
      return 'Telefone deve ter 9 dígitos após +258';
    }
    final prefix = national.substring(0, 2);
    if (!['82', '83', '84', '85', '86', '87'].contains(prefix)) {
      return 'Prefixo $prefix não é válido em Moçambique';
    }
    return null;
  }

  // === NUIT (9 dígitos exactos) ===

  static String? nuit(String? value) {
    if (value == null || value.trim().isEmpty) return 'NUIT é obrigatório';
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != YaConstants.nuitLength) {
      return 'NUIT deve ter exactamente ${YaConstants.nuitLength} dígitos';
    }
    return null;
  }

  // === Matrícula moçambicana ===

  /// Formato esperado: AAA-123-MP (3 letras + 3 dígitos + 2 letras de província)
  /// Provinces: MP=Maputo Província, MC=Maputo Cidade, GZ=Gaza, IN=Inhambane,
  /// SF=Sofala, MN=Manica, TT=Tete, ZB=Zambézia, NP=Nampula, CD=Cabo Delgado,
  /// NS=Niassa
  static String? licensePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Matrícula é obrigatória';
    }
    final clean = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (clean.length < 7 || clean.length > 8) {
      return 'Matrícula deve ter formato AAA-123-MP';
    }
    final regex = RegExp(r'^[A-Z]{3}\d{3}[A-Z]{2}$');
    if (!regex.hasMatch(clean)) {
      return 'Formato inválido. Esperado AAA-123-MP';
    }
    return null;
  }

  // === Numéricos ===

  static String? Function(String?) numberInRange(
    num min,
    num max, [
    String? fieldName,
  ]) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '${fieldName ?? 'Valor'} é obrigatório';
      }
      final parsed = num.tryParse(value.replaceAll(',', '.'));
      if (parsed == null) return 'Valor numérico inválido';
      if (parsed < min || parsed > max) {
        return '${fieldName ?? 'Valor'} deve estar entre $min e $max';
      }
      return null;
    };
  }

  static String? commissionRate(String? value) =>
      numberInRange(0, 100, 'Comissão')(value);

  static String? vehicleSeats(String? value) =>
      numberInRange(1, 60, 'Lugares')(value);

  static String? vehicleYear(String? value) {
    final currentYear = DateTime.now().year;
    return numberInRange(2000, currentYear + 1, 'Ano')(value);
  }

  // === Datas ===

  /// Para datas de expiração de documentos: deve ser futura
  static String? Function(DateTime?) futureDate([String? fieldName]) {
    return (value) {
      if (value == null) return '${fieldName ?? 'Data'} é obrigatória';
      if (value.isBefore(DateTime.now())) {
        return '${fieldName ?? 'Data'} deve ser futura';
      }
      return null;
    };
  }

  /// Para data de expiração de carta — mín 30 dias futuros
  static String? licenseExpiry(DateTime? value) {
    if (value == null) return 'Data de expiração é obrigatória';
    final minDate = DateTime.now().add(const Duration(days: 30));
    if (value.isBefore(minDate)) {
      return 'Carta deve expirar em pelo menos 30 dias';
    }
    return null;
  }

  // === Composer ===

  /// Combina vários validators; devolve a primeira mensagem de erro encontrada.
  /// Uso: `validator: YaValidators.compose([Validators.required, Validators.email])`
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
