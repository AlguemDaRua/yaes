import 'package:flutter/material.dart';

import '../../theme/tokens/colors.dart';

/// Variante semântica de status — foundations §3.5 e §9.
///
/// Usado por [StatusBadge] e qualquer indicador de estado.
enum StatusVariant {
  success,
  warning,
  danger,
  info,
  neutral,
  brand,
}

/// Mapeamento canónico estado-de-domínio → variant + label pt-PT.
///
/// Cobre os estados de Partner, Driver, Vehicle, Trip, Document, Ticket,
/// Transaction. Garante que "Activo" é sempre verde, "Pendente" é sempre
/// laranja, etc., em **todos** os ecrãs.
class StatusMapping {
  const StatusMapping(this.variant, this.label);
  final StatusVariant variant;
  final String label;
}

abstract class YaStatus {
  // === Partner ===
  static const partnerActive =
      StatusMapping(StatusVariant.success, 'Activo');
  static const partnerPending =
      StatusMapping(StatusVariant.warning, 'Pendente');
  static const partnerSuspended =
      StatusMapping(StatusVariant.danger, 'Suspenso');

  // === Driver ===
  static const driverActiveOnline =
      StatusMapping(StatusVariant.success, 'Activo · online');
  static const driverActiveOffline =
      StatusMapping(StatusVariant.neutral, 'Activo · offline');
  static const driverPending =
      StatusMapping(StatusVariant.warning, 'Pendente');
  static const driverSuspended =
      StatusMapping(StatusVariant.danger, 'Suspenso');

  // === Vehicle ===
  static const vehicleAvailable =
      StatusMapping(StatusVariant.success, 'Disponível');
  static const vehicleBusy =
      StatusMapping(StatusVariant.warning, 'Em corrida');
  static const vehicleMaintenance =
      StatusMapping(StatusVariant.neutral, 'Em manutenção');

  // === Trip ===
  static const tripPending =
      StatusMapping(StatusVariant.warning, 'Pendente');
  static const tripAccepted = StatusMapping(StatusVariant.info, 'Aceite');
  static const tripStarted =
      StatusMapping(StatusVariant.warning, 'A decorrer');
  static const tripCompleted =
      StatusMapping(StatusVariant.success, 'Completa');
  static const tripCancelled =
      StatusMapping(StatusVariant.danger, 'Cancelada');

  // === Document ===
  static const docOk = StatusMapping(StatusVariant.success, 'OK');
  static const docExpiringSoon =
      StatusMapping(StatusVariant.warning, 'A expirar');
  static const docExpired = StatusMapping(StatusVariant.danger, 'Expirado');
  static const docMissing =
      StatusMapping(StatusVariant.neutral, 'Em falta');

  // === Ticket ===
  static const ticketOpen = StatusMapping(StatusVariant.warning, 'Aberto');
  static const ticketInProgress =
      StatusMapping(StatusVariant.info, 'Em atendimento');
  static const ticketResolved =
      StatusMapping(StatusVariant.success, 'Resolvido');
  static const ticketClosed =
      StatusMapping(StatusVariant.neutral, 'Fechado');

  // === Ticket Priority ===
  static const priorityUrgent =
      StatusMapping(StatusVariant.danger, 'Urgente');
  static const priorityHigh = StatusMapping(StatusVariant.warning, 'Alta');
  static const priorityMedium = StatusMapping(StatusVariant.info, 'Média');
  static const priorityLow = StatusMapping(StatusVariant.neutral, 'Baixa');

  // === Transaction ===
  static const transactionPaid =
      StatusMapping(StatusVariant.success, 'Pago');
  static const transactionPending =
      StatusMapping(StatusVariant.warning, 'Pendente');
  static const transactionFailed =
      StatusMapping(StatusVariant.danger, 'Falhou');

  // === Lookup helpers (para mapear strings vindas do backend) ===

  static StatusMapping fromPartnerStatus(String status) =>
      switch (status) {
        'active' => partnerActive,
        'pending' => partnerPending,
        'suspended' => partnerSuspended,
        _ => StatusMapping(StatusVariant.neutral, status),
      };

  static StatusMapping fromDriverStatus(String status, {bool online = false}) {
    return switch (status) {
      'active' => online ? driverActiveOnline : driverActiveOffline,
      'pending' => driverPending,
      'suspended' => driverSuspended,
      _ => StatusMapping(StatusVariant.neutral, status),
    };
  }

  static StatusMapping fromVehicleStatus(String status) =>
      switch (status) {
        'available' => vehicleAvailable,
        'busy' => vehicleBusy,
        'maintenance' => vehicleMaintenance,
        _ => StatusMapping(StatusVariant.neutral, status),
      };

  static StatusMapping fromTripStatus(String status) => switch (status) {
        'pending' => tripPending,
        'accepted' => tripAccepted,
        'started' => tripStarted,
        'completed' => tripCompleted,
        'cancelled' => tripCancelled,
        _ => StatusMapping(StatusVariant.neutral, status),
      };

  static StatusMapping fromDocStatus(String status) => switch (status) {
        'ok' => docOk,
        'expiring_soon' => docExpiringSoon,
        'expired' => docExpired,
        'missing' => docMissing,
        _ => StatusMapping(StatusVariant.neutral, status),
      };

  static StatusMapping fromTicketStatus(String status) => switch (status) {
        'open' => ticketOpen,
        'in_progress' => ticketInProgress,
        'resolved' => ticketResolved,
        'closed' => ticketClosed,
        _ => StatusMapping(StatusVariant.neutral, status),
      };

  static StatusMapping fromTicketPriority(String priority) =>
      switch (priority) {
        'urgent' => priorityUrgent,
        'high' => priorityHigh,
        'medium' => priorityMedium,
        'low' => priorityLow,
        _ => StatusMapping(StatusVariant.neutral, priority),
      };

  static StatusMapping fromTransactionStatus(String status) =>
      switch (status) {
        'paid' => transactionPaid,
        'pending' => transactionPending,
        'failed' => transactionFailed,
        _ => StatusMapping(StatusVariant.neutral, status),
      };
}

/// Helper para resolver cores (text/bg) a partir de [StatusVariant].
extension StatusVariantColors on StatusVariant {
  ({Color text, Color bg}) resolve(YaColors colors) {
    return switch (this) {
      StatusVariant.success => (text: colors.success, bg: colors.successSubtle),
      StatusVariant.warning => (text: colors.warning, bg: colors.warningSubtle),
      StatusVariant.danger => (text: colors.danger, bg: colors.dangerSubtle),
      StatusVariant.info => (text: colors.info, bg: colors.infoSubtle),
      StatusVariant.neutral => (text: colors.neutral, bg: colors.neutralSubtle),
      StatusVariant.brand => (text: colors.brand, bg: colors.brandSubtle),
    };
  }
}
