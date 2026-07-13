import 'package:flutter_test/flutter_test.dart';
import 'package:ya_painel/data/mock/mock_support_data_repository.dart';
import 'package:ya_painel/support/data/mock_support_data.dart';
import 'package:ya_painel/support/data/mock_types.dart';

void main() {
  const repo = MockSupportDataRepository();

  test('returns support collection data', () async {
    expect(await repo.listTickets(), isNotEmpty);
    expect(await repo.activeTickets(), isNotEmpty);
    expect(await repo.listDisputes(), isNotEmpty);
    expect(await repo.chatThreads(), isNotEmpty);
    expect(await repo.leaderboard(), isNotEmpty);
  });

  test('resolves tickets and disputes by id', () async {
    final ticket = (await repo.listTickets()).first;
    final dispute = (await repo.listDisputes()).first;

    expect(await repo.ticketById(ticket.id), same(ticket));
    expect(await repo.disputeByTripId(dispute.tripId), same(dispute));
  });

  test('quickSearch returns all results for empty query', () async {
    final results = await repo.quickSearch('');

    expect(results, MockSupport.quickResults);
  });

  test('quickSearch filters by title and subtitle', () async {
    final titleMatch = await repo.quickSearch('Celso');
    final subtitleMatch = await repo.quickSearch('online');
    final noMatch = await repo.quickSearch('zzzzzz');

    expect(
      titleMatch.map((SupportQuickResult result) => result.id),
      contains('USR-1142'),
    );
    expect(
      subtitleMatch.map((SupportQuickResult result) => result.id),
      contains('DRV-001'),
    );
    expect(noMatch, isEmpty);
  });
}
