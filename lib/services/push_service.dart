import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

class PushService {
  static final PushService instance = PushService._();
  PushService._();

  final _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    await _requestPermission();
    _fcmToken = await _messaging.getToken();
    _messaging.onTokenRefresh.listen((token) => _fcmToken = token);

    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onBackgroundMessage(_handleBackground);
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _handleForeground(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? '';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    if (title.isNotEmpty && body.isNotEmpty) {
      NotificationService.instance.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackground(RemoteMessage message) async {
  final title = message.notification?.title ?? message.data['title'] ?? '';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  if (title.isNotEmpty && body.isNotEmpty) {
    NotificationService.instance.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
    );
  }
}
