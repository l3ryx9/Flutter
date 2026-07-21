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
  // SÉCURITÉ : ne jamais loguer le contenu des messages en background
  // (les données FCM peuvent contenir des informations sensibles)
  ErrorLogger.log('FCM Background', 'Message received');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  /// Global navigator key — doit être défini dans YouMeApp.
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

    // Créer le canal de notification Android
    const channel = AndroidNotificationChannel(
      AppConstants.notifChannelId,
      AppConstants.notifChannelName,
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Écouter les messages en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Écouter les taps de notification quand l'app était en background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Gérer le tap de notification quand l'app était terminée
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
      // SÉCURITÉ : ne pas loguer l'erreur complète (peut contenir des infos device)
      ErrorLogger.log('FCM getToken', 'Token retrieval failed');
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
      ErrorLogger.log('FCM saveToken', 'Token save failed');
    }
  }

  static String _platform() {
    try {
      if (const bool.fromEnvironment('dart.library.html')) return 'web';
      return 'android';
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
    // SÉCURITÉ : ne jamais loguer message.data (contenu potentiellement sensible)
    ErrorLogger.log('FCM Opened', 'Notification tapped');
    _navigateFromData(message.data);
  }

  /// Appelé quand l'utilisateur tape sur une notification locale
  static void _onLocalNotifTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final parts = payload.split(':');
    if (parts.length >= 2) {
      _navigateTo(parts[0], parts[1]);
    }
  }

  /// Construit un payload string depuis les données FCM
  static String? _payloadFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final conversationId = data['conversation_id'] as String?;
    if (type != null && conversationId != null) {
      return '$type:$conversationId';
    }
    return null;
  }

  /// Navigation basée sur les données FCM
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
