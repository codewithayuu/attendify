import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/subject.dart';
import '../models/attendance_record.dart';
import '../models/app_settings.dart';
import 'hive_service.dart';

class NotificationService {
  static const String _channelId = 'attendance_reminders';
  static const String _channelName = 'Attendance Reminders';
  static const String _channelDescription =
      'Daily reminders to mark attendance';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permission
    await _requestPermission();
  }

  // Request notification permission
  static Future<bool> _requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? granted =
        await androidImplementation?.requestNotificationsPermission();
    return granted ?? false;
  }

  // Schedule daily reminder
  static Future<void> scheduleDailyReminder(AppSettings settings) async {
    if (!settings.enableNotifications) {
      await cancelDailyReminder();
      return;
    }

    final timeParts = settings.notificationTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    await _notifications.zonedSchedule(
      1,
      'Attendance Reminder',
      'Don\'t forget to mark your attendance today!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel daily reminder
  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(1);
  }

  // Send low attendance warning
  static Future<void> sendLowAttendanceWarning(Subject subject) async {
    final settings = HiveService.getSettings();
    if (!settings.enableNotifications) return;

    await _notifications.show(
      2,
      'Low Attendance Warning',
      '${subject.name} attendance is ${subject.attendancePercentage.toStringAsFixed(1)}% (below ${settings.attendanceThreshold}%)',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.red,
        ),
      ),
    );
  }

  // Send attendance marked confirmation
  static Future<void> sendAttendanceMarkedConfirmation(
      Subject subject, AttendanceStatus status) async {
    final settings = HiveService.getSettings();
    if (!settings.enableNotifications) return;

    await _notifications.show(
      3,
      'Attendance Marked',
      '${subject.name}: ${status.displayName} ${status.emoji}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: status.countsAsPresent ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  // Send subject added confirmation
  static Future<void> sendSubjectAddedConfirmation(Subject subject) async {
    final settings = HiveService.getSettings();
    if (!settings.enableNotifications) return;

    await _notifications.show(
      4,
      'Subject Added',
      '${subject.name} has been added to your attendance tracker',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Colors.blue,
        ),
      ),
    );
  }

  // Send weekly summary
  static Future<void> sendWeeklySummary() async {
    final settings = HiveService.getSettings();
    if (!settings.enableNotifications) return;

    final subjects = HiveService.getAllSubjects();
    if (subjects.isEmpty) return;

    final lowAttendanceSubjects = subjects
        .where((s) => s.attendancePercentage < settings.attendanceThreshold)
        .toList();

    String body;
    if (lowAttendanceSubjects.isEmpty) {
      body =
          'Great job! All your subjects are above ${settings.attendanceThreshold}% attendance.';
    } else {
      body =
          '${lowAttendanceSubjects.length} subject(s) below ${settings.attendanceThreshold}%: ';
      body += lowAttendanceSubjects.map((s) => s.name).join(', ');
    }

    await _notifications.show(
      5,
      'Weekly Attendance Summary',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: lowAttendanceSubjects.isEmpty ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  // Send monthly summary
  static Future<void> sendMonthlySummary() async {
    final settings = HiveService.getSettings();
    if (!settings.enableNotifications) return;

    final subjects = HiveService.getAllSubjects();
    if (subjects.isEmpty) return;

    final totalClasses = subjects.fold(0, (sum, s) => sum + s.totalClasses);
    final totalAttended = subjects.fold(0, (sum, s) => sum + s.attendedClasses);
    final overallPercentage =
        totalClasses > 0 ? (totalAttended / totalClasses) * 100 : 0.0;

    await _notifications.show(
      6,
      'Monthly Attendance Summary',
      'Overall attendance: ${overallPercentage.toStringAsFixed(1)}% ($totalAttended/$totalClasses classes)',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: overallPercentage >= settings.attendanceThreshold
              ? Colors.green
              : Colors.orange,
        ),
      ),
    );
  }

  // Check and send low attendance warnings
  static Future<void> checkAndSendLowAttendanceWarnings() async {
    final settings = HiveService.getSettings();
    if (!settings.enableNotifications) return;

    final subjects = HiveService.getAllSubjects();
    for (final subject in subjects) {
      if (subject.attendancePercentage < settings.attendanceThreshold) {
        await sendLowAttendanceWarning(subject);
      }
    }
  }

  // Schedule weekly summary (every Sunday at 6 PM)
  static Future<void> scheduleWeeklySummary() async {
    final settings = HiveService.getSettings();
    if (!settings.enableNotifications) return;

    await _notifications.zonedSchedule(
      5,
      'Weekly Attendance Summary',
      'Check your weekly attendance summary',
      _nextInstanceOfDayOfWeek(DateTime.sunday, 18, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // Schedule monthly summary (1st of every month at 9 AM)
  static Future<void> scheduleMonthlySummary() async {
    final settings = HiveService.getSettings();
    if (!settings.enableNotifications) return;

    await _notifications.zonedSchedule(
      6,
      'Monthly Attendance Summary',
      'Check your monthly attendance summary',
      _nextInstanceOfDayOfMonth(1, 9, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  // Cancel all scheduled notifications
  static Future<void> cancelAllScheduledNotifications() async {
    await _notifications.cancelAll();
  }

  // Get notification history
  static Future<List<PendingNotificationRequest>>
      getNotificationHistory() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    return await androidImplementation?.areNotificationsEnabled() ?? false;
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    return await _requestPermission();
  }

  // Update notification settings
  static Future<void> updateNotificationSettings(AppSettings settings) async {
    if (settings.enableNotifications) {
      await scheduleDailyReminder(settings);
      await scheduleWeeklySummary();
      await scheduleMonthlySummary();
    } else {
      await cancelAllScheduledNotifications();
    }
  }

  // Helper methods for scheduling
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfDayOfWeek(
      int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfDayOfMonth(
      int dayOfMonth, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, dayOfMonth, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
          tz.local, now.year, now.month + 1, dayOfMonth, hour, minute);
    }

    return scheduledDate;
  }
}
