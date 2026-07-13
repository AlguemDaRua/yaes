import 'package:cloud_functions/cloud_functions.dart';

/// Result of starting a digital collection: the created payment id and its
/// initial status (`pending` until the PSP confirms via the webhook).
class PaymentInit {
  const PaymentInit({required this.paymentId, required this.status});

  final String paymentId;
  final String status;
}

/// Thin wrapper over the `initiatePayment` Cloud Function. The gateway
/// (M-Pesa / e-Mola / sandbox) is selected server-side from Secret Manager, so
/// no credentials live in the app.
class PaymentService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Starts a C2B collection for [tripId] via [method] ('mpesa' | 'emola').
  static Future<PaymentInit> initiate({
    required String tripId,
    required String method,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('initiatePayment');
    final HttpsCallableResult<dynamic> result = await callable.call<dynamic>({
      'tripId': tripId,
      'method': method,
    });
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(result.data as Map);
    return PaymentInit(
      paymentId: data['paymentId'] as String,
      status: data['status'] as String,
    );
  }
}
