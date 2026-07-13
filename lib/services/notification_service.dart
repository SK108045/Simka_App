import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/client.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Call once at app startup
  static Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return; // flutter_local_notifications not supported on web
    }

    tz.initializeTimeZones();
    // Try to set to Nairobi timezone (EAT, UTC+3)
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Nairobi'));
    } catch (_) {
      // Fallback to UTC
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to relevant client screen via global navigator key
  }

  static AndroidNotificationDetails get _androidDetails =>
      const AndroidNotificationDetails(
        'simka_fire_services',
        'SIMKA Fire Services',
        channelDescription: 'Reminders for fire service appointments',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFE53935),
        enableLights: true,
        ledColor: Color(0xFFE53935),
        ledOnMs: 1000,
        ledOffMs: 500,
        playSound: true,
        enableVibration: true,
      );

  /// Schedule 3 notifications per client:
  ///  - 7 days before
  ///  - 1 day before
  ///  - On the day (8 AM)
  static Future<void> scheduleServiceNotifications(Client client) async {
    if (kIsWeb) return; // Notifications not supported on web

    final serviceDate = client.nextServiceDate;
    final now = tz.TZDateTime.now(tz.local);

    // IDs: base, base+1, base+2
    final ids = [
      client.notificationId,
      client.notificationId + 1,
      client.notificationId + 2,
    ];

    final scheduleTimes = [
      _tzAt(serviceDate.subtract(const Duration(days: 7)), 8),
      _tzAt(serviceDate.subtract(const Duration(days: 1)), 8),
      _tzAt(serviceDate, 8),
    ];

    final bodies = [
      '${client.name} is due for ${client.serviceType} in 7 days.',
      '${client.name} is due for ${client.serviceType} TOMORROW!',
      'TODAY: ${client.name} — ${client.serviceType} service at ${client.address}.',
    ];

    for (int i = 0; i < 3; i++) {
      if (scheduleTimes[i].isAfter(now)) {
        await _plugin.zonedSchedule(
          ids[i],
          '🔥 SIMKA Fire Service Reminder',
          bodies[i],
          scheduleTimes[i],
          NotificationDetails(android: _androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Cancel all notifications for a client (base, base+1, base+2)
  static Future<void> cancelClientNotifications(Client client) async {
    if (kIsWeb) return;
    await _plugin.cancel(client.notificationId);
    await _plugin.cancel(client.notificationId + 1);
    await _plugin.cancel(client.notificationId + 2);
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  /// Helper: build a TZDateTime at a specific date and hour
  static tz.TZDateTime _tzAt(DateTime date, int hour) {
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
    );
  }
}
