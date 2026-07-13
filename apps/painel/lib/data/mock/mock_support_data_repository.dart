import '../../support/data/mock_support_data.dart';
import '../../support/data/mock_types.dart';
import '../repositories/support_data_repository.dart';

class MockSupportDataRepository implements SupportDataRepository {
  const MockSupportDataRepository();

  @override
  Future<List<SupportTicket>> listTickets() async => MockSupport.tickets;

  @override
  Future<List<SupportTicket>> activeTickets() async =>
      MockSupport.activeTickets;

  @override
  Future<SupportTicket?> ticketById(String id) async {
    try {
      return MockSupport.ticketById(id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SupportDispute>> listDisputes() async => MockSupport.disputes;

  @override
  Future<SupportDispute?> disputeByTripId(String tripId) async {
    try {
      return MockSupport.disputeByTripId(tripId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SupportChatThread>> chatThreads() async =>
      MockSupport.chatThreads;

  @override
  Future<void> sendChatMessage(
    String threadId,
    String text,
    String author,
  ) async {}

  @override
  Future<void> updateChatThread(
    String threadId,
    Map<String, dynamic> fields,
  ) async {}

  @override
  Future<List<SupportAgentPerformance>> leaderboard() async =>
      MockSupport.leaderboard;

  @override
  Future<List<SupportQuickResult>> quickSearch(String query) async {
    if (query.isEmpty) return MockSupport.quickResults;
    final String q = query.toLowerCase();
    return MockSupport.quickResults
        .where((SupportQuickResult r) =>
            r.title.toLowerCase().contains(q) ||
            r.subtitle.toLowerCase().contains(q),)
        .toList();
  }
}
