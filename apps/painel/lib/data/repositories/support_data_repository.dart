import '../../support/data/mock_types.dart';

/// Repositório abstracto para dados support (tickets, disputes, chat threads,
/// performance, quick results). Esta interface aproveita os tipos já
/// existentes em `lib/support/data/mock_types.dart` (que são bem definidos).
abstract class SupportDataRepository {
  Future<List<SupportTicket>> listTickets();
  Future<List<SupportTicket>> activeTickets();
  Future<SupportTicket?> ticketById(String id);

  Future<List<SupportDispute>> listDisputes();
  Future<SupportDispute?> disputeByTripId(String tripId);

  Future<List<SupportChatThread>> chatThreads();

  /// Envia uma mensagem do agente numa conversa de chat.
  Future<void> sendChatMessage(String threadId, String text, String author);

  /// Actualiza campos de uma conversa (ex.: status, assignedTo).
  Future<void> updateChatThread(String threadId, Map<String, dynamic> fields);

  Future<List<SupportAgentPerformance>> leaderboard();

  Future<List<SupportQuickResult>> quickSearch(String query);
}
