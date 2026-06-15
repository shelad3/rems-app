import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {},
    );

    _initialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rent_reminders',
      'Rent Reminders',
      channelDescription: 'Notifications for upcoming rent payments',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleRentReminders() async {
    final db = DatabaseHelper.instance;
    final leases = await db.getActiveLeasesWithDetails();

    for (final lease in leases) {
      final endDate =
          DateTime.parse(lease['end_date'] as String);
      final daysUntilEnd = DateTime.now().difference(endDate).inDays;

      if (daysUntilEnd <= 0 && daysUntilEnd >= -5) {
        final tenantName = lease['tenant_name'] as String? ?? 'Tenant';
        final propertyName =
            lease['property_name'] as String? ?? 'Property';
        final rentAmount =
            (lease['rent_amount'] as num?)?.toDouble() ?? 0;

        await showNotification(
          id: lease['id'] as int,
          title: 'Rent Reminder',
          body: '$tenantName - \$${rentAmount.toStringAsFixed(0)} due for $propertyName',
        );
      }
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
