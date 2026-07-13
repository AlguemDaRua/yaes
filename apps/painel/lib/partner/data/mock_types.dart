enum MockDriverStatus {
  active,
  pending,
  suspended,
}

enum MockVehicleStatus {
  available,
  busy,
  maintenance,
}

enum MockTripStatus {
  pending,
  accepted,
  started,
  completed,
  cancelled,
}

enum MockDocumentOwnerType {
  partner,
  driver,
  vehicle,
}

enum MockDocumentStatus {
  ok,
  expiringSoon,
  expired,
  missing,
}

enum MockAlertSeverity {
  critical,
  warning,
  info,
}

enum MockTransactionStatus {
  paid,
  pending,
  failed,
}

enum MockIncentiveStatus {
  active,
  scheduled,
  ended,
}

extension MockDriverStatusKey on MockDriverStatus {
  String get key => switch (this) {
        MockDriverStatus.active => 'active',
        MockDriverStatus.pending => 'pending',
        MockDriverStatus.suspended => 'suspended',
      };
}

extension MockVehicleStatusKey on MockVehicleStatus {
  String get key => switch (this) {
        MockVehicleStatus.available => 'available',
        MockVehicleStatus.busy => 'busy',
        MockVehicleStatus.maintenance => 'maintenance',
      };
}

extension MockTripStatusKey on MockTripStatus {
  String get key => switch (this) {
        MockTripStatus.pending => 'pending',
        MockTripStatus.accepted => 'accepted',
        MockTripStatus.started => 'started',
        MockTripStatus.completed => 'completed',
        MockTripStatus.cancelled => 'cancelled',
      };
}

extension MockDocumentStatusKey on MockDocumentStatus {
  String get key => switch (this) {
        MockDocumentStatus.ok => 'ok',
        MockDocumentStatus.expiringSoon => 'expiring_soon',
        MockDocumentStatus.expired => 'expired',
        MockDocumentStatus.missing => 'missing',
      };
}

extension MockTransactionStatusKey on MockTransactionStatus {
  String get key => switch (this) {
        MockTransactionStatus.paid => 'paid',
        MockTransactionStatus.pending => 'pending',
        MockTransactionStatus.failed => 'failed',
      };
}
