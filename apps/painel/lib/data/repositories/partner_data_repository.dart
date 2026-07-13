import '../../partner/data/mock_partner_data.dart';

/// Repositório abstracto para dados de um partner (drivers, viaturas, viagens,
/// documentos, alertas, etc.). Cada método devolve um Future ou Stream para
/// permitir implementações async (Firebase, REST). A implementação mock devolve
/// dados síncronos via Future.value.
///
/// Filtragem por partnerId é responsabilidade da implementação — partners nunca
/// vêem dados de outros partners.
abstract class PartnerDataRepository {
  String get partnerId;

  /// Perfil do partner actual (nome, cidade, NUIT, contactos, frota).
  Future<MockPartnerProfile> partnerProfile();

  Future<List<MockPartnerStaff>> listStaff();

  Future<List<MockDriver>> listDrivers();
  Stream<List<MockDriver>> watchDrivers();
  Future<MockDriver?> driverById(String id);

  Future<List<MockVehicle>> listVehicles();
  Stream<List<MockVehicle>> watchVehicles();
  Future<MockVehicle?> vehicleById(String id);

  /// Cria um veículo na frota do partner. Devolve o id gerado.
  Future<String> createVehicle({
    required String plate,
    required String model,
    required String type,
    required int year,
    required int seats,
  });

  /// Actualiza o perfil do partner (ex.: name, city, email, phone).
  Future<void> updateProfile(Map<String, dynamic> fields);

  /// Actualiza campos de um veículo (ex.: status, plate, model, year, seats).
  Future<void> updateVehicle(String id, Map<String, dynamic> fields);

  /// Remove um veículo da frota.
  Future<void> deleteVehicle(String id);

  Future<List<MockTrip>> listTrips();
  Future<List<MockTrip>> tripsByDriver(String driverId);
  Future<List<MockTrip>> tripsByVehicle(String vehicleId);
  Future<MockTrip?> tripById(String id);

  Future<List<MockAlert>> listAlerts();
  Future<List<MockAlert>> criticalAlerts();

  Future<List<MockDocument>> listDocuments();
  Future<List<MockMaintenance>> maintenancesByVehicle(String vehicleId);
  Future<List<MockRating>> ratingsByDriver(String driverId);
  Future<List<MockEarningsTransaction>> earningsTransactions();
  Future<List<MockIncentive>> incentives();
  Future<List<MockMessageThread>> messageThreads();

  /// Mensagens de uma conversa, em tempo real.
  Stream<List<MockChatMessage>> watchThreadMessages(String threadId);

  /// Envia uma mensagem do partner numa conversa.
  Future<void> sendThreadMessage(String threadId, String text);
}
