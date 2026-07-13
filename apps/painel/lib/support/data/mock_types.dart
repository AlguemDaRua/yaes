enum SupportTicketPriority { urgent, high, medium, low }

enum SupportTicketStatus { open, inProgress, resolved, closed }

enum SupportActorRole { passenger, driver, partner, agent }

enum SupportDisputeStatus { open, investigating, resolved }

enum SupportQuickResultType { passenger, driver, partner, trip }

class SupportMessage {
  const SupportMessage({
    required this.author,
    required this.text,
    required this.createdAt,
    this.role = SupportActorRole.passenger,
    this.agent = false,
    this.attachmentLabel,
    this.internal = false,
  });

  final String author;
  final String text;
  final DateTime createdAt;
  final SupportActorRole role;
  final bool agent;
  final String? attachmentLabel;
  final bool internal;
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.preview,
    required this.authorName,
    required this.authorEmail,
    required this.authorPhone,
    required this.role,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
    this.assignee,
    this.tripId,
    this.amount,
    this.internalNotes,
  });

  final String id;
  final String subject;
  final String preview;
  final String authorName;
  final String authorEmail;
  final String authorPhone;
  final SupportActorRole role;
  final SupportTicketPriority priority;
  final SupportTicketStatus status;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? assignee;
  final String? tripId;
  final int? amount;
  final List<SupportMessage> messages;
  final String? internalNotes;

  SupportTicket copyWith({
    SupportTicketStatus? status,
    String? assignee,
    List<SupportMessage>? messages,
    String? internalNotes,
  }) {
    return SupportTicket(
      id: id,
      subject: subject,
      preview: preview,
      authorName: authorName,
      authorEmail: authorEmail,
      authorPhone: authorPhone,
      role: role,
      priority: priority,
      status: status ?? this.status,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      assignee: assignee ?? this.assignee,
      tripId: tripId,
      amount: amount,
      messages: messages ?? this.messages,
      internalNotes: internalNotes ?? this.internalNotes,
    );
  }
}

class SupportDispute {
  const SupportDispute({
    required this.tripId,
    required this.from,
    required this.to,
    required this.passengerName,
    required this.driverName,
    required this.rating,
    required this.comment,
    required this.status,
    required this.createdAt,
    required this.amount,
  });

  final String tripId;
  final String from;
  final String to;
  final String passengerName;
  final String driverName;
  final int rating;
  final String comment;
  final SupportDisputeStatus status;
  final DateTime createdAt;
  final int amount;
}

class SupportQuickResult {
  const SupportQuickResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.route,
  });

  final String id;
  final String title;
  final String subtitle;
  final SupportQuickResultType type;
  final String? route;
}

enum SupportChatStatus { active, waiting, typing, closed }

class SupportChatThread {
  SupportChatThread({
    required this.id,
    required this.contactName,
    required this.contactPhone,
    required this.role,
    required this.priority,
    required this.status,
    required this.startedAt,
    required this.messages,
    required this.unread,
    this.tripId,
    this.tripFrom,
    this.tripTo,
    this.tripAmount,
    this.recentTickets = const <String>[],
  });

  final String id;
  final String contactName;
  final String contactPhone;
  final SupportActorRole role;
  final SupportTicketPriority priority;
  SupportChatStatus status;
  final DateTime startedAt;
  final List<SupportMessage> messages;
  int unread;
  final String? tripId;
  final String? tripFrom;
  final String? tripTo;
  final int? tripAmount;
  final List<String> recentTickets;

  SupportMessage get lastMessage => messages.last;
  DateTime get lastMessageAt => messages.last.createdAt;
}

class SupportAgentPerformance {
  const SupportAgentPerformance({
    required this.position,
    required this.name,
    required this.email,
    required this.resolved,
    required this.csat,
    required this.averageResponse,
    required this.trend,
    this.current = false,
  });

  final int position;
  final String name;
  final String email;
  final int resolved;
  final double csat;
  final String averageResponse;
  final List<double> trend;
  final bool current;
}
