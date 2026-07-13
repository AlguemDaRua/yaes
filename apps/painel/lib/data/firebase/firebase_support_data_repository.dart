import 'package:firebase_database/firebase_database.dart';

import '../../support/data/mock_types.dart';
import '../repositories/support_data_repository.dart';

class FirebaseSupportDataRepository implements SupportDataRepository {
  FirebaseSupportDataRepository();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  @override
  Future<List<SupportTicket>> listTickets() async {
    final DataSnapshot snap = await _db.child('tickets').get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _ticketFromMap(entry.key, entry.value);
    }).toList()
      ..sort(
        (SupportTicket a, SupportTicket b) =>
            b.lastMessageAt.compareTo(a.lastMessageAt),
      );
  }

  @override
  Future<List<SupportTicket>> activeTickets() async {
    final List<SupportTicket> tickets = await listTickets();
    return tickets
        .where(
          (SupportTicket ticket) =>
              ticket.status == SupportTicketStatus.open ||
              ticket.status == SupportTicketStatus.inProgress,
        )
        .toList();
  }

  @override
  Future<SupportTicket?> ticketById(String id) async {
    final DataSnapshot snap = await _db.child('tickets/$id').get();
    if (!snap.exists) return null;
    return _ticketFromMap(id, _snapshotValueMap(snap));
  }

  @override
  Future<List<SupportDispute>> listDisputes() async {
    final DataSnapshot snap = await _db.child('disputes').get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _disputeFromMap(entry.key, entry.value);
    }).toList()
      ..sort(
        (SupportDispute a, SupportDispute b) =>
            b.createdAt.compareTo(a.createdAt),
      );
  }

  @override
  Future<SupportDispute?> disputeByTripId(String tripId) async {
    final DataSnapshot snap = await _db.child('disputes/$tripId').get();
    if (snap.exists) return _disputeFromMap(tripId, _snapshotValueMap(snap));

    final DataSnapshot byTrip = await _db
        .child('disputes')
        .orderByChild('tripId')
        .equalTo(tripId)
        .get();
    final List<MapEntry<String, Map<String, dynamic>>> entries =
        _snapshotEntries(byTrip);
    if (entries.isEmpty) return null;
    return _disputeFromMap(entries.first.key, entries.first.value);
  }

  @override
  Future<List<SupportChatThread>> chatThreads() async {
    final DataSnapshot snap = await _db.child('messages').get();
    return _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _threadFromMap(entry.key, entry.value);
    }).toList()
      ..sort(
        (SupportChatThread a, SupportChatThread b) =>
            b.lastMessageAt.compareTo(a.lastMessageAt),
      );
  }

  @override
  Future<void> sendChatMessage(
    String threadId,
    String text,
    String author,
  ) async {
    final String now = DateTime.now().toIso8601String();
    final String key =
        _db.child('messages/$threadId/messages').push().key ?? now;
    await _db.child('messages/$threadId').update(<String, dynamic>{
      'messages/$key': <String, dynamic>{
        'from': author,
        'to': '',
        'text': text,
        'timestamp': now,
        'role': 'support',
      },
      'lastMessage': text,
      'updatedAt': now,
      'status': 'active',
    });
  }

  @override
  Future<void> updateChatThread(
    String threadId,
    Map<String, dynamic> fields,
  ) async {
    await _db.child('messages/$threadId').update(<String, dynamic>{
      ...fields,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<SupportAgentPerformance>> leaderboard() async {
    final DataSnapshot snap = await _db.child('support/leaderboard').get();
    final List<SupportAgentPerformance> rows = _snapshotEntries(snap)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _leaderboardFromMap(entry.key, entry.value);
    }).toList()
      ..sort(
        (SupportAgentPerformance a, SupportAgentPerformance b) =>
            a.position.compareTo(b.position),
      );
    return rows;
  }

  @override
  Future<List<SupportQuickResult>> quickSearch(String query) async {
    final String normalized = query.trim().toLowerCase();
    final List<SupportQuickResult> results = <SupportQuickResult>[];

    for (final SupportTicket ticket in await listTickets()) {
      if (_matches(normalized, <String>[
        ticket.id,
        ticket.subject,
        ticket.authorName,
        ticket.authorPhone,
      ])) {
        results.add(
          SupportQuickResult(
            id: ticket.id,
            title: ticket.subject,
            subtitle: '${ticket.authorName} / ${ticket.status.name}',
            type: SupportQuickResultType.trip,
            route: '/support/tickets/${ticket.id}',
          ),
        );
      }
    }

    for (final SupportChatThread thread in await chatThreads()) {
      if (_matches(normalized, <String>[
        thread.id,
        thread.contactName,
        thread.contactPhone,
      ])) {
        results.add(
          SupportQuickResult(
            id: thread.id,
            title: thread.contactName,
            subtitle: thread.contactPhone,
            type: _quickTypeForRole(thread.role),
            route: '/support/chat',
          ),
        );
      }
    }

    return results.take(10).toList();
  }

  SupportTicket _ticketFromMap(String id, Map<String, dynamic> map) {
    final List<SupportMessage> messages = _messagesFromMap(map['messages']);
    final DateTime createdAt = _date(map['createdAt']) ?? DateTime.now();
    final DateTime lastMessageAt = _date(map['lastMessageAt']) ??
        _date(map['updatedAt']) ??
        (messages.isEmpty ? createdAt : messages.last.createdAt);
    final String preview = _string(map, 'preview') ??
        _string(map, 'description') ??
        (messages.isEmpty ? '' : messages.last.text);

    return SupportTicket(
      id: id,
      subject: _string(map, 'subject') ?? _string(map, 'title') ?? id,
      preview: preview,
      authorName: _string(map, 'authorName') ?? _string(map, 'author') ?? '',
      authorEmail: _string(map, 'authorEmail') ?? '',
      authorPhone: _string(map, 'authorPhone') ?? '',
      role: _actorRole(_string(map, 'role') ?? _string(map, 'authorRole')),
      priority: _priority(_string(map, 'priority')),
      status: _ticketStatus(_string(map, 'status')),
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      messages: messages,
      assignee: _string(map, 'assignedTo') ?? _string(map, 'assignee'),
      tripId: _string(map, 'tripId'),
      amount: _int(map, 'amount') ?? _int(map, 'amountMtn'),
      internalNotes: _string(map, 'internalNotes'),
    );
  }

  SupportDispute _disputeFromMap(String id, Map<String, dynamic> map) {
    final String from = _placeName(map['from']);
    final String to = _placeName(map['to']);
    return SupportDispute(
      tripId: _string(map, 'tripId') ?? id,
      from: from.isNotEmpty ? from : _placeName(map['origin']),
      to: to.isNotEmpty ? to : _placeName(map['destination']),
      passengerName: _string(map, 'passengerName') ?? '',
      driverName: _string(map, 'driverName') ?? '',
      rating: _int(map, 'rating') ?? 0,
      comment: _string(map, 'comment') ?? '',
      status: _disputeStatus(_string(map, 'status')),
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      amount: _int(map, 'amount') ?? _int(map, 'amountMtn') ?? 0,
    );
  }

  SupportChatThread _threadFromMap(String id, Map<String, dynamic> map) {
    final List<SupportMessage> messages = _messagesFromThread(map);
    final DateTime startedAt = _date(map['startedAt']) ??
        _date(map['createdAt']) ??
        (messages.isEmpty ? DateTime.now() : messages.first.createdAt);
    return SupportChatThread(
      id: id,
      contactName:
          _string(map, 'contactName') ?? _string(map, 'participant') ?? '',
      contactPhone: _string(map, 'contactPhone') ?? '',
      role: _actorRole(_string(map, 'role')),
      priority: _priority(_string(map, 'priority')),
      status: _chatStatus(_string(map, 'status')),
      startedAt: startedAt,
      messages: messages.isEmpty
          ? <SupportMessage>[
              SupportMessage(
                author: _string(map, 'contactName') ?? 'Contacto',
                text: _string(map, 'lastMessage') ?? '',
                createdAt: startedAt,
              ),
            ]
          : messages,
      unread: _int(map, 'unread') ?? _int(map, 'unreadCount') ?? 0,
      tripId: _string(map, 'tripId'),
      tripFrom: _string(map, 'tripFrom'),
      tripTo: _string(map, 'tripTo'),
      tripAmount: _int(map, 'tripAmount'),
      recentTickets: _stringList(map['recentTickets']),
    );
  }

  SupportAgentPerformance _leaderboardFromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SupportAgentPerformance(
      position: _int(map, 'position') ?? 999,
      name: _string(map, 'name') ?? id,
      email: _string(map, 'email') ?? '',
      resolved: _int(map, 'resolved') ?? 0,
      csat: _double(map, 'csat') ?? 0,
      averageResponse: _string(map, 'averageResponse') ?? '--',
      trend: _doubleList(map['trend']),
      current: _bool(map, 'current') ?? false,
    );
  }

  List<SupportMessage> _messagesFromThread(Map<String, dynamic> map) {
    final List<SupportMessage> messages = _messagesFromMap(map['messages']);
    if (messages.isNotEmpty) return messages;
    return _snapshotLikeEntries(map)
        .where((MapEntry<String, Map<String, dynamic>> entry) {
      return entry.value.containsKey('text') ||
          entry.value.containsKey('timestamp');
    }).map((MapEntry<String, Map<String, dynamic>> entry) {
      return _messageFromMap(entry.value);
    }).toList()
      ..sort((SupportMessage a, SupportMessage b) {
        return a.createdAt.compareTo(b.createdAt);
      });
  }

  List<SupportMessage> _messagesFromMap(Object? value) {
    final Map<String, dynamic>? map = _mapValue(value);
    if (map == null) return <SupportMessage>[];
    return _snapshotLikeEntries(map)
        .map((MapEntry<String, Map<String, dynamic>> entry) {
      return _messageFromMap(entry.value);
    }).toList()
      ..sort((SupportMessage a, SupportMessage b) {
        return a.createdAt.compareTo(b.createdAt);
      });
  }

  SupportMessage _messageFromMap(Map<String, dynamic> map) {
    final String author = _string(map, 'author') ?? _string(map, 'from') ?? '';
    final SupportActorRole role = _actorRole(_string(map, 'role'));
    return SupportMessage(
      author: author,
      text: _string(map, 'text') ?? '',
      createdAt:
          _date(map['createdAt']) ?? _date(map['timestamp']) ?? DateTime.now(),
      role: role,
      agent: _bool(map, 'agent') ?? role == SupportActorRole.agent,
      attachmentLabel: _string(map, 'attachmentLabel'),
      internal: _bool(map, 'internal') ?? false,
    );
  }

  List<MapEntry<String, Map<String, dynamic>>> _snapshotEntries(
    DataSnapshot snapshot,
  ) {
    return _snapshotLikeEntries(_snapshotValueMap(snapshot));
  }

  List<MapEntry<String, Map<String, dynamic>>> _snapshotLikeEntries(
    Map<String, dynamic> map,
  ) {
    return map.entries.map((MapEntry<String, dynamic> entry) {
      return MapEntry<String, Map<String, dynamic>>(
        entry.key,
        _mapValue(entry.value) ?? <String, dynamic>{},
      );
    }).toList();
  }

  Map<String, dynamic> _snapshotValueMap(DataSnapshot snapshot) {
    return _mapValue(snapshot.value) ?? <String, dynamic>{};
  }

  Map<String, dynamic>? _mapValue(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  String? _string(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    return value is String ? value : null;
  }

  bool? _bool(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    return value is bool ? value : null;
  }

  int? _int(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _double(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  DateTime? _date(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is num) {
      final int raw = value.toInt();
      final int millis = raw < 100000000000 ? raw * 1000 : raw;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }

  String _placeName(Object? value) {
    final Map<String, dynamic>? map = _mapValue(value);
    if (map != null) {
      return _string(map, 'name') ??
          _string(map, 'address') ??
          _string(map, 'label') ??
          '';
    }
    return value is String ? value : '';
  }

  List<String> _stringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    final Map<String, dynamic>? map = _mapValue(value);
    if (map == null) return <String>[];
    return map.values.whereType<String>().toList();
  }

  List<double> _doubleList(Object? value) {
    if (value is List) {
      return value.whereType<num>().map((num n) => n.toDouble()).toList();
    }
    final Map<String, dynamic>? map = _mapValue(value);
    if (map == null) return <double>[];
    return map.values.whereType<num>().map((num n) => n.toDouble()).toList();
  }

  bool _matches(String query, List<String> values) {
    if (query.isEmpty) return true;
    return values.any((String value) => value.toLowerCase().contains(query));
  }

  SupportQuickResultType _quickTypeForRole(SupportActorRole role) {
    return switch (role) {
      SupportActorRole.driver => SupportQuickResultType.driver,
      SupportActorRole.partner => SupportQuickResultType.partner,
      _ => SupportQuickResultType.passenger,
    };
  }

  SupportTicketPriority _priority(String? raw) {
    return switch (raw) {
      'urgent' => SupportTicketPriority.urgent,
      'high' => SupportTicketPriority.high,
      'low' => SupportTicketPriority.low,
      _ => SupportTicketPriority.medium,
    };
  }

  SupportTicketStatus _ticketStatus(String? raw) {
    return switch (raw) {
      'in_progress' || 'inProgress' => SupportTicketStatus.inProgress,
      'resolved' => SupportTicketStatus.resolved,
      'closed' => SupportTicketStatus.closed,
      _ => SupportTicketStatus.open,
    };
  }

  SupportActorRole _actorRole(String? raw) {
    return switch (raw) {
      'driver' => SupportActorRole.driver,
      'partner' ||
      'partner_owner' ||
      'partner_staff' =>
        SupportActorRole.partner,
      'agent' || 'support' => SupportActorRole.agent,
      _ => SupportActorRole.passenger,
    };
  }

  SupportDisputeStatus _disputeStatus(String? raw) {
    return switch (raw) {
      'investigating' => SupportDisputeStatus.investigating,
      'resolved' => SupportDisputeStatus.resolved,
      _ => SupportDisputeStatus.open,
    };
  }

  SupportChatStatus _chatStatus(String? raw) {
    return switch (raw) {
      'waiting' => SupportChatStatus.waiting,
      'typing' => SupportChatStatus.typing,
      'closed' => SupportChatStatus.closed,
      _ => SupportChatStatus.active,
    };
  }
}
