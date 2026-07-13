class AdminPartner {
  const AdminPartner({
    required this.id,
    required this.name,
    required this.city,
    required this.status,
    required this.createdAt,
    this.nuit,
    this.driversCount = 0,
    this.vehiclesCount = 0,
    this.requiresWalletSettlement = false,
    this.commissionFloatMtn = 500,
  });

  final String id;
  final String name;
  final String city;
  final String status;
  final DateTime createdAt;
  final String? nuit;
  final int driversCount;
  final int vehiclesCount;

  /// true para operações de motorista directo (ex.: "YA Direct" em Nampula)
  /// que liquidam comissão via carteira do motorista em vez do fluxo normal.
  final bool requiresWalletSettlement;

  /// Limite (em MTn) a partir do qual o motorista é bloqueado por dívida.
  final int commissionFloatMtn;
}

class AdminDriver {
  const AdminDriver({
    required this.id,
    required this.name,
    required this.status,
    required this.partnerId,
    required this.online,
    this.phone,
    this.email,
    this.vehicleId,
    this.rating = 0,
    this.tripsCount = 0,
  });

  final String id;
  final String name;
  final String status;
  final String? partnerId;
  final bool online;
  final String? phone;
  final String? email;
  final String? vehicleId;
  final double rating;
  final int tripsCount;
}

class AdminVehicle {
  const AdminVehicle({
    required this.id,
    required this.partnerId,
    required this.plate,
    required this.model,
    required this.type,
    required this.status,
    this.driverId,
    this.year,
    this.category,
    this.seats,
    this.photoUrl,
    this.color,
  });

  final String id;
  final String partnerId;
  final String plate;
  final String model;
  final String type;
  final String status;
  final String? driverId;
  final int? year;

  /// Categoria de preço (economico/conforto/premium/van) — liga o veículo
  /// ao tarifário e ao que o passageiro escolhe.
  final String? category;
  final int? seats;
  final String? photoUrl;
  final String? color;
}

class AdminTrip {
  const AdminTrip({
    required this.id,
    required this.status,
    required this.createdAt,
    this.partnerId,
    this.driverId,
    this.vehicleId,
    this.passengerId,
    this.origin,
    this.destination,
    this.amountMtn = 0,
    this.distanceKm,
    this.originLat,
    this.originLng,
    this.destLat,
    this.destLng,
    this.offeredAt,
    this.acceptedAt,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final String? partnerId;
  final String? driverId;
  final String? vehicleId;
  final String? passengerId;
  final String? origin;
  final String? destination;
  final int amountMtn;
  final double? distanceKm;
  final double? originLat;
  final double? originLng;
  final double? destLat;
  final double? destLng;

  /// Quando a viagem ficou disponível para motoristas (pode ser depois de
  /// [createdAt] em viagens digitais, que só ficam 'pending' após o
  /// pagamento confirmar). Usado para taxa de aceitação / tempo até aceite.
  final DateTime? offeredAt;
  final DateTime? acceptedAt;

  bool get hasRoute =>
      originLat != null &&
      originLng != null &&
      destLat != null &&
      destLng != null;
}

class AdminDriverLocation {
  const AdminDriverLocation({
    required this.driverId,
    required this.lat,
    required this.lng,
    required this.online,
    this.angle,
    this.updatedAt,
  });

  final String driverId;
  final double lat;
  final double lng;
  final bool online;
  final double? angle;
  final DateTime? updatedAt;
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.type,
    required this.createdAt,
    this.name,
    this.email,
    this.phone,
    this.partnerId,
    this.status,
  });

  final String id;
  final String type;
  final DateTime createdAt;
  final String? name;
  final String? email;
  final String? phone;
  final String? partnerId;
  final String? status;
}

class AdminFleet {
  const AdminFleet({
    required this.id,
    required this.partnerId,
    required this.name,
    this.driversCount = 0,
    this.vehiclesCount = 0,
  });

  final String id;
  final String partnerId;
  final String name;
  final int driversCount;
  final int vehiclesCount;
}

class AdminDocument {
  const AdminDocument({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.type,
    required this.status,
    this.url,
    this.expiresAt,
  });

  final String id;
  final String ownerType;
  final String ownerId;
  final String type;
  final String status;
  final String? url;
  final DateTime? expiresAt;
}

class AdminAlert {
  const AdminAlert({
    required this.id,
    required this.title,
    required this.severity,
    required this.createdAt,
    this.partnerId,
    this.description,
    this.resolved = false,
  });

  final String id;
  final String title;
  final String severity;
  final DateTime createdAt;
  final String? partnerId;
  final String? description;
  final bool resolved;
}

class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.createdAt,
    this.targetPath,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String actorUid;
  final String action;
  final DateTime createdAt;
  final String? targetPath;
  final Map<String, Object?> metadata;
}

class AdminCommission {
  const AdminCommission({
    required this.id,
    required this.partnerId,
    required this.rate,
    required this.createdAt,
    this.status = 'active',
  });

  final String id;
  final String partnerId;
  final double rate;
  final DateTime createdAt;
  final String status;
}

class AdminBroadcast {
  const AdminBroadcast({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.status,
    required this.createdAt,
    this.sentBy,
  });

  final String id;
  final String title;
  final String body;
  final String audience;
  final String status;
  final DateTime createdAt;
  final String? sentBy;
}

class AdminPayout {
  const AdminPayout({
    required this.id,
    required this.partnerId,
    required this.amountMtn,
    required this.method,
    required this.status,
    required this.createdAt,
    this.label,
    this.reference,
  });

  final String id;
  final String partnerId;
  final int amountMtn;
  final String method;
  final String status;
  final DateTime createdAt;
  final String? label;
  final String? reference;
}

/// Carteira de comissão de um motorista (operação "YA Direct").
class AdminDriverWallet {
  const AdminDriverWallet({
    required this.partnerId,
    required this.driverId,
    required this.balance,
    required this.blockedAt,
    required this.entries,
  });

  final String partnerId;
  final String driverId;

  /// Saldo em MTn; negativo = motorista em dívida com a YA.
  final int balance;
  final DateTime? blockedAt;
  final List<AdminWalletEntry> entries;
}

class AdminWalletEntry {
  const AdminWalletEntry({
    required this.id,
    required this.type,
    required this.amountMtn,
    required this.createdAt,
    this.tripId,
    this.mpesaRef,
    this.adminId,
    this.note,
  });

  final String id;

  /// 'commission' | 'topup' | 'adjustment'
  final String type;
  final int amountMtn;
  final DateTime createdAt;
  final String? tripId;
  final String? mpesaRef;
  final String? adminId;
  final String? note;
}

class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.tripId,
    required this.passenger,
    required this.method,
    required this.amountMtn,
    required this.status,
    required this.createdAt,
    this.pspRef,
    this.gateway,
  });

  final String id;
  final String tripId;
  final String passenger;
  final String method;
  final int amountMtn;
  final String status;
  final DateTime createdAt;
  final String? pspRef;
  final String? gateway;
}
