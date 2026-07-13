import 'package:cloud_functions/cloud_functions.dart';

/// Thin wrapper over the `createTicket` Cloud Function. Self-service: the
/// caller always opens the ticket in their own name (see
/// functions/src/support.ts createTicketCore).
class SupportService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<String> createTicket({
    required String subject,
    String? text,
    String? tripId,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('createTicket');
    final result = await callable.call<dynamic>({
      'subject': subject,
      if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
      if (tripId != null) 'tripId': tripId,
    });
    return (result.data as Map)['ticketId'].toString();
  }
}
