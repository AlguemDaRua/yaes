import '../../admin/data/types.dart';

abstract class AdminDataRepository {
  Future<List<AdminPartner>> listPartners();
  Future<List<AdminDriver>> listDrivers();
  Future<List<AdminVehicle>> listVehicles();
  Future<List<AdminTrip>> listTrips();
  Future<List<AdminUser>> listUsers();
  Future<List<AdminFleet>> listFleets();
  Future<List<AdminDocument>> listDocuments();
  Future<List<AdminAlert>> listAlerts();
  Future<List<AdminAuditLog>> listAuditLogs();
  Future<List<AdminCommission>> listCommissions();
  Future<List<AdminPayment>> listPayments();
  Future<List<AdminPayout>> listPayouts();
  Future<List<AdminBroadcast>> listBroadcasts();

  Future<AdminPartner?> partnerById(String id);
  Future<AdminDriver?> driverById(String id);
  Future<AdminVehicle?> vehicleById(String id);
  Future<AdminTrip?> tripById(String id);
  Future<AdminUser?> userById(String id);
  Future<AdminFleet?> fleetById(String id);

  Stream<List<AdminTrip>> watchActiveTripsForMap();
  Stream<List<AdminDriverLocation>> watchDriverLocations();

  /// Marca um alerta como resolvido (write staff via regras).
  Future<void> resolveAlert(String id);

  /// Lê uma secção de `/config/{section}` (ex.: 'pricing', 'platform').
  Future<Map<String, dynamic>> getConfig(String section);

  /// Substitui `/config/{section}` pelo mapa dado (write admin-only via regras).
  Future<void> setConfig(String section, Map<String, Object?> value);

  /// Remove `/config/{section}` (ex.: 'webhooks/abc123').
  Future<void> removeConfig(String section);

  /// Atualiza campos de um veículo em `/partners/{pid}/vehicles/{vid}`.
  Future<void> updateVehicle(
    String partnerId,
    String vehicleId,
    Map<String, Object?> fields,
  );

  /// Cria um veículo em `/partners/{pid}/vehicles` e devolve o id gerado.
  Future<String> createVehicle(String partnerId, Map<String, Object?> fields);

  Future<void> writeAuditLog(AdminAuditLog log);

  /// Lê a carteira de comissão de um motorista em `/driverWallets/{partnerId}/{driverId}`.
  /// Devolve null se o nó não existir (motorista sem carteira ainda).
  Future<AdminDriverWallet?> driverWallet(String partnerId, String driverId);
}
