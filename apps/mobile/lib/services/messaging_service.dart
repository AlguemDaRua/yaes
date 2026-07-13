import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:limousineexecutive/repositories/firebase_trip_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';

/// Parsed shape of a notification payload. Payloads are serialised as JSON so
/// we carry both the message [type] (e.g. `new_trip`, `trip_accepted`) and the
/// [tripId] through every delivery path (foreground local notification, FCM
/// background tap, cold-start).
class NotificationPayload {
  final String type;
  final String? tripId;

  const NotificationPayload({required this.type, this.tripId});

  String encode() => jsonEncode({'type': type, 'tripId': tripId});

  static NotificationPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['type'] is String) {
        return NotificationPayload(
          type: decoded['type'] as String,
          tripId: decoded['tripId'] as String?,
        );
      }
    } catch (_) {
      // Legacy payloads were a bare type string — accept them as a fallback.
      return NotificationPayload(type: raw);
    }
    return null;
  }

  static NotificationPayload? fromRemoteMessage(RemoteMessage message) {
    final type = message.data['type'];
    if (type is! String) return null;
    return NotificationPayload(
      type: type,
      tripId: message.data['tripId'] as String?,
    );
  }
}

// Background/terminated message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by Flutter — no need to re-initialize
  _showLocalNotification(message);
}

void _showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  if (notification == null) return;

  final payload = NotificationPayload.fromRemoteMessage(message);

  MessagingService.localNotifications.show(
    notification.hashCode,
    notification.title,
    notification.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'trips',
        'Viagens',
        channelDescription: 'Notificacoes de viagens',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: payload?.encode(),
  );
}

class MessagingService {
  static final localNotifications = FlutterLocalNotificationsPlugin();
  static final _messaging = FirebaseMessaging.instance;
  static final ITripRepository _tripRepo = FirebaseTripRepository();

  /// Callback invoked whenever a notification is tapped (regardless of app state).
  /// Set by `main.dart` so navigation can happen via the global `navigatorKey`.
  static void Function(NotificationPayload payload)? onNotificationTap;

  /// Callback specifically for when a new trip request is received in the foreground.
  static void Function(String tripId)? onNewTripReceived;

  /// Initialize FCM: request permission, get token, configure handlers
  static Future<void> initialize() async {
    // Request permission (iOS and Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Background/terminated message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final payload = NotificationPayload.fromRemoteMessage(message);

      // If it's a new trip request, trigger the special foreground handler
      if (payload?.type == 'new_trip' && payload?.tripId != null) {
        onNewTripReceived?.call(payload!.tripId!);
      } else {
        // Otherwise, show as a standard local notification
        _showLocalNotification(message);
      }
    });

    // User tapped an FCM notification while the app was in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final payload = NotificationPayload.fromRemoteMessage(message);
      if (payload != null) onNotificationTap?.call(payload);
    });

    // App was launched by tapping an FCM notification while terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final payload = NotificationPayload.fromRemoteMessage(initialMessage);
      if (payload != null) {
        // Defer until the first frame so the navigator is ready.
        Future.microtask(() => onNotificationTap?.call(payload));
      }
    }

    // Save initial token and listen for Auth changes to handle late logins
    await _saveToken();
    await _subscribeTopics();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _saveToken();
        _subscribeTopics();
      }
    });

    // Refresh token when renewed by Firebase
    _messaging.onTokenRefresh.listen((newToken) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _tripRepo.saveFcmToken(uid, newToken);
      }
    });
  }

  /// Save the current user's FCM token to Firebase
  static Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await _tripRepo.saveFcmToken(uid, token);
    }
  }

  /// Subscribe to broadcast topics: every user gets `all`, plus
  /// `drivers`/`passengers` by account type. Used by the panel's
  /// sendBroadcast callable (FCM topics). A driver whose partner opted the
  /// fleet out (`/partners/{id}/notificationPrefs/broadcastsEnabled == false`)
  /// is kept unsubscribed from both instead.
  static Future<void> _subscribeTopics() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final profile = await _tripRepo.watchProfile(uid).first;
      final type = profile?['type']?.toString();
      if (type == 'driver') {
        final partnerId = profile?['partnerId']?.toString();
        final bool broadcastsEnabled = partnerId == null
            ? true
            : await _partnerBroadcastsEnabled(partnerId);
        if (broadcastsEnabled) {
          await _messaging.subscribeToTopic('all');
          await _messaging.subscribeToTopic('drivers');
        } else {
          await _messaging.unsubscribeFromTopic('all');
          await _messaging.unsubscribeFromTopic('drivers');
        }
        await _messaging.unsubscribeFromTopic('passengers');
      } else {
        await _messaging.subscribeToTopic('all');
        await _messaging.subscribeToTopic('passengers');
        await _messaging.unsubscribeFromTopic('drivers');
      }
    } catch (_) {
      // Sem rede ou perfil ainda inexistente: tenta de novo no próximo login.
    }
  }

  static Future<bool> _partnerBroadcastsEnabled(String partnerId) async {
    final snap = await FirebaseDatabase.instance
        .ref('partners/$partnerId/notificationPrefs/broadcastsEnabled')
        .get();
    return snap.value == null ? true : snap.value == true;
  }

  /// Call after successful login to ensure token is saved.
  /// Best-effort: o registo de push NUNCA pode bloquear o login (ex.: web sem
  /// permissão de notificações, ou utilizador que recusou no telemóvel).
  static Future<void> onLogin() async {
    try {
      await _saveToken();
      await _subscribeTopics();
    } catch (e) {
      debugPrint('FCM onLogin falhou (ignorado): $e');
    }
  }
}
