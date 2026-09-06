import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _androidChannel = AndroidNotificationChannel(
  'default',
  'General notifications',
  description: 'SOS confirmations, quest achievements, and level-ups.',
  importance: Importance.high,
);

/// Wraps FirebaseMessaging + flutter_local_notifications: requests
/// permission, fetches the device token, and displays a heads-up
/// notification when a push arrives while the app is foregrounded (FCM does
/// not do this automatically on either platform — background/terminated
/// messages are shown by the OS itself from the payload's `notification`
/// block, so no local-notification call is needed for that path).
class FcmService {
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Sets up the foreground listener and the local-notifications plugin.
  /// Safe to call once at app startup, before any user is signed in.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(_androidChannel.id, _androidChannel.name),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  /// Prompts for notification permission (required on iOS; a no-op that
  /// resolves granted on most Android versions). Returns whether the app is
  /// allowed to show notifications.
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;
}

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());
