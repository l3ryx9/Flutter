import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import '../utils/error_logger.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  ErrorLogger.log('FCM Background', 'Message received: ${message.messageId}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    await _localNotif.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create notification channel
    const channel = AndroidNotificationChannel(
      AppConstants.notifChannelId,
      AppConstants.notifChannelName,
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);
  }

  static Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      ErrorLogger.log('FCM getToken', e.toString());
      return null;
    }
  }

  static Future<void> saveTokenToSupabase() async {
    final token = await getToken();
    if (token == null) return;
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await SupabaseService.client.from(SupabaseKeys.deviceTokens).upsert({
      'user_id': userId,
      'fcm_token': token,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelId,
          AppConstants.notifChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static void _handleMessageOpened(RemoteMessage message) {
    // Navigate based on data
    ErrorLogger.log('FCM Opened', 'Data: ${message.data}');
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelId,
          AppConstants.notifChannelName,
          importance: Importance.high,
        ),
      ),
      payload: payload,
    );
  }
}
