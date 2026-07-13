import 'package:cloud_functions/cloud_functions.dart';

/// Thin wrapper over the `submitRating` Cloud Function. The server resolves
/// and verifies the trip's driver/passenger/status — the client only ever
/// asserts a tripId, never a driverId (see functions/src/ratings.ts).
class RatingService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<void> submit({
    required String tripId,
    required double value,
    String? comment,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('submitRating');
    await callable.call<dynamic>({
      'tripId': tripId,
      'value': value,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
  }
}
