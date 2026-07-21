import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../router/app_router.dart';
import '../utils/error_logger.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  ErrorLogger.log('FCM Background', 'Message received: ${message.messageId}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  /// Global navigator key — must be set in main app (YouMeApp).
  static GlobalKey<NavigatorState>? navigatorKey;

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
      onDidReceiveNotificationResponse: _onLocalNotifTap,
    );

    // Create notification channel
    const channel = AndroidNotificationChannel(
      AppConstants.notifChannelId,
      AppConstants.notifChannelName,
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Handle notification tap when app was terminated
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _navigateFromData(initial.data);
    }
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

    try {
      await SupabaseService.client.from(SupabaseKeys.deviceTokens).upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': _platform(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ErrorLogger.log('FCM saveToken', e.toString());
    }
  }

  static String _platform() {
    try {
      if (const bool.fromEnvironment('dart.library.html')) return 'web';
      return 'android'; // fallback; real detection via Platform.isIOS
    } catch (_) {
      return 'android';
    }
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
      payload: _payloadFromData(message.data),
    );
  }

  static void _handleMessageOpened(RemoteMessage message) {
    ErrorLogger.log('FCM Opened', 'Data: ${message.data}');
    _navigateFromData(message.data);
  }

  /// Called when user taps a local notification
  static void _onLocalNotifTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    // payload format: "type:conversationId"
    final parts = payload.split(':');
    if (parts.length >= 2) {
      _navigateTo(parts[0], parts[1]);
    }
  }

  /// Build a payload string from FCM data map
  static String? _payloadFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final conversationId = data['conversation_id'] as String?;
    if (type != null && conversationId != null) {
      return '$type:$conversationId';
    }
    return null;
  }

  /// Navigate based on FCM data payload
  static void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final conversationId = data['conversation_id'] as String?;
    if (type == null) return;
    _navigateTo(type, conversationId ?? '');
  }

  static void _navigateTo(String type, String conversationId) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;

    switch (type) {
      case 'message':
        if (conversationId.isNotEmpty) {
          context.go('/home/chat/$conversationId');
        } else {
          context.go(AppRoutes.home);
        }
        break;
      case 'contact_request':
        context.go('/home/invitations');
        break;
      case 'ai_insight':
        if (conversationId.isNotEmpty) {
          context.go('/home/chat/$conversationId/ai-insights');
        }
        break;
      case 'flag':
        if (conversationId.isNotEmpty) {
          context.go('/home/chat/$conversationId/flags');
        }
        break;
      case 'location':
        if (conversationId.isNotEmpty) {
          context.go('/home/chat/$conversationId/live-location');
        }
        break;
      default:
        context.go(AppRoutes.home);
    }
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
