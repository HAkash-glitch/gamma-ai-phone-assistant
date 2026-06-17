import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(initSettings);

    await Permission.notification.request();

    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    const androidChannel = AndroidNotificationChannel(
      'gamma_reminders',
      'Gamma Reminders',
      description: 'Reminder notifications from Gamma Assistant',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  static Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'Gamma Test',
      'Notifications are working!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gamma_reminders',
          'Gamma Reminders',
          channelDescription: 'Reminder notifications from Gamma Assistant',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  static Future<void> scheduleDelayedReminder({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    Future.delayed(delay, () async {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gamma_reminders',
            'Gamma Reminders',
            channelDescription: 'Reminder notifications from Gamma Assistant',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    });
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    final scheduledTime = tz.TZDateTime.from(dateTime, tz.local);

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      throw Exception("Scheduled time is in the past");
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gamma_reminders',
          'Gamma Reminders',
          channelDescription: 'Reminder notifications from Gamma Assistant',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}