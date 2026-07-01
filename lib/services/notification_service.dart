import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String reminderEnabledKey = 'reminder_enabled';
  static const String reminderTimeKey = 'reminder_time';
  static const String reminderDaysKey = 'reminder_days';

  static Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    // Android 13+ requires requesting permissions
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to quiz screen
    // This will be handled in main.dart or home screen
  }

  // Check if reminders are enabled
  static bool isReminderEnabled() {
    // We'll check this from SharedPreferences in the app
    return true;
  }

  // Schedule 4 daily reminders (6 AM, 12 PM, 6 PM, 12 AM)
  static Future<void> scheduleReminders() async {
    // Cancel existing reminders first
    await cancelAllReminders();

    // Get stored preference
    // Default times: 6:00, 12:00, 18:00, 00:00
    final times = [6, 12, 18, 0];

    for (int i = 0; i < times.length; i++) {
      final hour = times[i];
      await _scheduleDailyNotification(
        id: i,
        hour: hour,
        minute: 0,
        title: '📚 Time for a Quick Test!',
        body:
            'Challenge yourself with ${20} questions and boost your exam preparation!',
      );
    }
  }

  static Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'quiz_reminder_channel',
      'Quiz Reminders',
      channelDescription: 'Daily quiz reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Show immediate notification (for testing)
  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'quiz_reminder_channel',
      'Quiz Reminders',
      channelDescription: 'Daily quiz reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '📚 Time for a Quick Test!',
      'Challenge yourself with ${20} questions and boost your exam preparation!',
      details,
    );
  }

  // Cancel all scheduled notifications
  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
