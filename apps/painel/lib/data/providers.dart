import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_provider.dart';
import '../core/auth/auth_user.dart';
import '../core/config.dart';
import '../admin/data/types.dart';
import 'firebase/cloud_functions_service.dart';
import 'firebase/firebase_admin_data_repository.dart';
import '../partner/data/mock_partner_data.dart';
import '../support/data/mock_types.dart';
import 'firebase/firebase_partner_data_repository.dart';
import 'firebase/firebase_support_data_repository.dart';
import 'firebase/storage_service.dart';
import 'mock/mock_admin_data_repository.dart';
import 'mock/mock_partner_data_repository.dart';
import 'mock/mock_support_data_repository.dart';
import 'repositories/admin_data_repository.dart';
import 'repositories/partner_data_repository.dart';
import 'repositories/support_data_repository.dart';

/// Provedor do [PartnerDataRepository]. Devolve a implementação adequada
/// consoante a configuração (mock por defeito; Firebase quando ligado na Fase D).
///
/// O `partnerId` é obtido do utilizador autenticado quando o role é partner;
/// caso contrário (admin/support) usa o mock por omissão para suportar dev sem
/// login.
final Provider<PartnerDataRepository> partnerDataRepositoryProvider =
    Provider<PartnerDataRepository>((Ref ref) {
  final AuthUser? user = ref.watch(authStateProvider);
  final String partnerId =
      (user?.role == UserRole.partner ? user?.partnerId : null) ??
          MockPartner.id;
  if (kUseFirebase && authNotifier.usesFirebase) {
    return FirebasePartnerDataRepository(partnerId: partnerId);
  }
  return MockPartnerDataRepository(partnerId: partnerId);
});

/// Perfil do partner actual (nome, cidade, NUIT, contactos, frota).
final FutureProvider<MockPartnerProfile> partnerProfileProvider =
    FutureProvider<MockPartnerProfile>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).partnerProfile();
});

/// Lista da equipa (contas de login) do partner actual.
final FutureProvider<List<MockPartnerStaff>> staffProvider =
    FutureProvider<List<MockPartnerStaff>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).listStaff();
});

/// Lista de drivers do partner actual.
final FutureProvider<List<MockDriver>> driversProvider =
    FutureProvider<List<MockDriver>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).listDrivers();
});

/// Stream-based: drivers que actualiza em tempo real.
final StreamProvider<List<MockDriver>> driversStreamProvider =
    StreamProvider<List<MockDriver>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).watchDrivers();
});

final driverByIdProvider =
    FutureProvider.family<MockDriver?, String>((Ref ref, String id) {
  return ref.watch(partnerDataRepositoryProvider).driverById(id);
});

final FutureProvider<List<MockVehicle>> vehiclesProvider =
    FutureProvider<List<MockVehicle>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).listVehicles();
});

final StreamProvider<List<MockVehicle>> vehiclesStreamProvider =
    StreamProvider<List<MockVehicle>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).watchVehicles();
});

final vehicleByIdProvider =
    FutureProvider.family<MockVehicle?, String>((Ref ref, String id) {
  return ref.watch(partnerDataRepositoryProvider).vehicleById(id);
});

final FutureProvider<List<MockTrip>> tripsProvider =
    FutureProvider<List<MockTrip>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).listTrips();
});

final tripsByDriverProvider =
    FutureProvider.family<List<MockTrip>, String>((Ref ref, String driverId) {
  return ref.watch(partnerDataRepositoryProvider).tripsByDriver(driverId);
});

final tripsByVehicleProvider =
    FutureProvider.family<List<MockTrip>, String>((Ref ref, String vehicleId) {
  return ref.watch(partnerDataRepositoryProvider).tripsByVehicle(vehicleId);
});

final FutureProvider<List<MockAlert>> alertsProvider =
    FutureProvider<List<MockAlert>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).listAlerts();
});

final FutureProvider<List<MockAlert>> criticalAlertsProvider =
    FutureProvider<List<MockAlert>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).criticalAlerts();
});

final FutureProvider<List<MockEarningsTransaction>>
    earningsTransactionsProvider =
    FutureProvider<List<MockEarningsTransaction>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).earningsTransactions();
});

final FutureProvider<List<MockIncentive>> incentivesProvider =
    FutureProvider<List<MockIncentive>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).incentives();
});

final FutureProvider<List<MockMessageThread>> messageThreadsProvider =
    FutureProvider<List<MockMessageThread>>((Ref ref) {
  return ref.watch(partnerDataRepositoryProvider).messageThreads();
});

final partnerThreadMessagesProvider =
    StreamProvider.family<List<MockChatMessage>, String>(
  (Ref ref, String threadId) {
    return ref
        .watch(partnerDataRepositoryProvider)
        .watchThreadMessages(threadId);
  },
);

final maintenancesByVehicleProvider =
    FutureProvider.family<List<MockMaintenance>, String>(
  (Ref ref, String vehicleId) {
    return ref
        .watch(partnerDataRepositoryProvider)
        .maintenancesByVehicle(vehicleId);
  },
);

final ratingsByDriverProvider =
    FutureProvider.family<List<MockRating>, String>((Ref ref, String driverId) {
  return ref.watch(partnerDataRepositoryProvider).ratingsByDriver(driverId);
});

// ─── Firebase services (functions + storage) ────────────────────────────────

final Provider<CloudFunctionsService> cloudFunctionsServiceProvider =
    Provider<CloudFunctionsService>((Ref ref) => CloudFunctionsService());

final Provider<StorageService> storageServiceProvider =
    Provider<StorageService>((Ref ref) => StorageService());

// ─── Support providers ──────────────────────────────────────────────────────

// ─── Admin providers ─────────────────────────────────────────────────────────

final Provider<AdminDataRepository> adminDataRepositoryProvider =
    Provider<AdminDataRepository>((Ref ref) {
  if (kUseFirebase && authNotifier.usesFirebase) {
    return FirebaseAdminDataRepository();
  }
  return const MockAdminDataRepository();
});

final FutureProvider<List<AdminPartner>> adminPartnersProvider =
    FutureProvider<List<AdminPartner>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listPartners();
});

final FutureProvider<List<AdminDriver>> adminDriversProvider =
    FutureProvider<List<AdminDriver>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listDrivers();
});

final FutureProvider<List<AdminVehicle>> adminVehiclesProvider =
    FutureProvider<List<AdminVehicle>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listVehicles();
});

final FutureProvider<List<AdminTrip>> adminTripsProvider =
    FutureProvider<List<AdminTrip>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listTrips();
});

final FutureProvider<List<AdminUser>> adminUsersProvider =
    FutureProvider<List<AdminUser>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listUsers();
});

final FutureProvider<List<AdminFleet>> adminFleetsProvider =
    FutureProvider<List<AdminFleet>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listFleets();
});

final FutureProvider<List<AdminDocument>> adminDocumentsProvider =
    FutureProvider<List<AdminDocument>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listDocuments();
});

final FutureProvider<List<AdminAlert>> adminAlertsProvider =
    FutureProvider<List<AdminAlert>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listAlerts();
});

final FutureProvider<List<AdminAuditLog>> adminAuditLogsProvider =
    FutureProvider<List<AdminAuditLog>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listAuditLogs();
});

final FutureProvider<List<AdminCommission>> adminCommissionsProvider =
    FutureProvider<List<AdminCommission>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listCommissions();
});

final FutureProvider<List<AdminPayment>> adminPaymentsProvider =
    FutureProvider<List<AdminPayment>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listPayments();
});

final FutureProvider<List<AdminPayout>> adminPayoutsProvider =
    FutureProvider<List<AdminPayout>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listPayouts();
});

final FutureProvider<List<AdminBroadcast>> adminBroadcastsProvider =
    FutureProvider<List<AdminBroadcast>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).listBroadcasts();
});

final adminConfigProvider = FutureProvider.family<Map<String, dynamic>, String>(
    (Ref ref, String section) {
  return ref.watch(adminDataRepositoryProvider).getConfig(section);
});

final adminPartnerByIdProvider =
    FutureProvider.family<AdminPartner?, String>((Ref ref, String id) {
  return ref.watch(adminDataRepositoryProvider).partnerById(id);
});

final adminDriverByIdProvider =
    FutureProvider.family<AdminDriver?, String>((Ref ref, String id) {
  return ref.watch(adminDataRepositoryProvider).driverById(id);
});

final adminVehicleByIdProvider =
    FutureProvider.family<AdminVehicle?, String>((Ref ref, String id) {
  return ref.watch(adminDataRepositoryProvider).vehicleById(id);
});

final adminTripByIdProvider =
    FutureProvider.family<AdminTrip?, String>((Ref ref, String id) {
  return ref.watch(adminDataRepositoryProvider).tripById(id);
});

final adminUserByIdProvider =
    FutureProvider.family<AdminUser?, String>((Ref ref, String id) {
  return ref.watch(adminDataRepositoryProvider).userById(id);
});

final adminFleetByIdProvider =
    FutureProvider.family<AdminFleet?, String>((Ref ref, String id) {
  return ref.watch(adminDataRepositoryProvider).fleetById(id);
});

final adminDriverWalletProvider = FutureProvider.family<AdminDriverWallet?,
    ({String partnerId, String driverId})>((Ref ref, key) {
  return ref
      .watch(adminDataRepositoryProvider)
      .driverWallet(key.partnerId, key.driverId);
});

final StreamProvider<List<AdminTrip>> adminActiveTripsForMapProvider =
    StreamProvider<List<AdminTrip>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).watchActiveTripsForMap();
});

final StreamProvider<List<AdminDriverLocation>> adminDriverLocationsProvider =
    StreamProvider<List<AdminDriverLocation>>((Ref ref) {
  return ref.watch(adminDataRepositoryProvider).watchDriverLocations();
});

final Provider<SupportDataRepository> supportDataRepositoryProvider =
    Provider<SupportDataRepository>((Ref ref) {
  if (kUseFirebase && authNotifier.usesFirebase) {
    return FirebaseSupportDataRepository();
  }
  return const MockSupportDataRepository();
});

final FutureProvider<List<SupportTicket>> supportTicketsProvider =
    FutureProvider<List<SupportTicket>>((Ref ref) {
  return ref.watch(supportDataRepositoryProvider).listTickets();
});

final FutureProvider<List<SupportTicket>> supportActiveTicketsProvider =
    FutureProvider<List<SupportTicket>>((Ref ref) {
  return ref.watch(supportDataRepositoryProvider).activeTickets();
});

final supportTicketByIdProvider =
    FutureProvider.family<SupportTicket?, String>((Ref ref, String id) {
  return ref.watch(supportDataRepositoryProvider).ticketById(id);
});

final FutureProvider<List<SupportDispute>> supportDisputesProvider =
    FutureProvider<List<SupportDispute>>((Ref ref) {
  return ref.watch(supportDataRepositoryProvider).listDisputes();
});

final FutureProvider<List<SupportChatThread>> supportChatThreadsProvider =
    FutureProvider<List<SupportChatThread>>((Ref ref) {
  return ref.watch(supportDataRepositoryProvider).chatThreads();
});

final FutureProvider<List<SupportAgentPerformance>> supportLeaderboardProvider =
    FutureProvider<List<SupportAgentPerformance>>((Ref ref) {
  return ref.watch(supportDataRepositoryProvider).leaderboard();
});

final supportQuickSearchProvider =
    FutureProvider.family<List<SupportQuickResult>, String>(
  (Ref ref, String query) {
    return ref.watch(supportDataRepositoryProvider).quickSearch(query);
  },
);
