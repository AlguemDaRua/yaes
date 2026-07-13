import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';

/// Uma linha do extracto da carteira de comissão do motorista.
/// Espelha /driverWallets/{partnerId}/{driverId}/entries/{id} (ver
/// functions/src/wallet.ts): negativo = comissão devida, positivo = crédito.
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.type,
    required this.amountMtn,
    required this.createdAt,
    this.reference,
  });

  final String id;
  final String type; // commission | topup | adjustment
  final int amountMtn;
  final DateTime createdAt;
  final String? reference; // tripId | mpesaRef | note

  factory WalletEntry.fromMap(String id, Map<dynamic, dynamic> map) {
    return WalletEntry(
      id: id,
      type: map['type']?.toString() ?? 'adjustment',
      amountMtn: (map['amountMtn'] as num?)?.round() ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      reference: (map['tripId'] ?? map['mpesaRef'] ?? map['note'])?.toString(),
    );
  }
}

/// Carteira de comissão do motorista (operação directa "YA Direct").
/// Saldo negativo = dívida de comissão à YA; quando ultrapassa o limite do
/// parceiro o backend marca `blockedAt` e o motorista não pode ficar online.
class DriverWallet {
  const DriverWallet({
    required this.balance,
    required this.entries,
    this.blockedAt,
  });

  final int balance;
  final DateTime? blockedAt;
  final List<WalletEntry> entries; // mais recentes primeiro

  bool get isBlocked => blockedAt != null;

  factory DriverWallet.fromMap(Map<dynamic, dynamic> map) {
    final entriesMap = map['entries'];
    final entries = <WalletEntry>[
      if (entriesMap is Map)
        for (final e in entriesMap.entries)
          if (e.value is Map)
            WalletEntry.fromMap(e.key.toString(), e.value as Map),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return DriverWallet(
      balance: (map['balance'] as num?)?.round() ?? 0,
      blockedAt: DateTime.tryParse(map['blockedAt']?.toString() ?? ''),
      entries: entries,
    );
  }
}

/// Acesso à carteira: stream em tempo real + recarga via Cloud Function.
/// Segue o padrão de PaymentService (gateway seleccionado server-side).
class WalletService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Observa /driverWallets/{partnerId}/{driverId}; null se não existir
  /// (parceiro sem liquidação por carteira, ou sem movimentos ainda).
  static Stream<DriverWallet?> watch(String partnerId, String driverId) {
    return _db
        .ref('driverWallets/$partnerId/$driverId')
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return null;
      return DriverWallet.fromMap(value);
    });
  }

  /// Inicia uma recarga C2B ('mpesa' | 'emola'); o crédito entra na carteira
  /// via webhook do PSP, reflectido no stream. Devolve o status inicial.
  static Future<String> topup({
    required int amountMtn,
    required String method,
  }) async {
    final HttpsCallable callable =
        _functions.httpsCallable('initiateWalletTopup');
    final result = await callable.call<dynamic>({
      'amountMtn': amountMtn,
      'method': method,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['status']?.toString() ?? 'pending';
  }
}
