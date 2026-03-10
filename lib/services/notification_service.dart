import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_of_day.dart';

/// Service for managing Word of the Day notifications
///
/// Note: For actual push notifications, you would need to integrate
/// platform-specific notification packages like:
/// - flutter_local_notifications (for local notifications)
/// - firebase_messaging (for push notifications)
///
/// This service provides the infrastructure and can be extended
/// to integrate with those packages.
class NotificationService {
  static const String _notificationEnabledKey = 'wod_notifications_enabled';
  static const String _notificationTimeKey = 'wod_notification_time';
  static const int _defaultNotificationHour = 9; // 9 AM
  static const int _defaultNotificationMinute = 0;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? true;
  }

  /// Enable or disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);

    if (enabled) {
      await scheduleWordOfDayNotification();
    } else {
      await cancelWordOfDayNotification();
    }
  }

  /// Get the scheduled notification time
  Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('${_notificationTimeKey}_hour') ??
        _defaultNotificationHour;
    final minute = prefs.getInt('${_notificationTimeKey}_minute') ??
        _defaultNotificationMinute;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Set the notification time
  Future<void> setNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_notificationTimeKey}_hour', time.hour);
    await prefs.setInt('${_notificationTimeKey}_minute', time.minute);

    // Reschedule with new time
    await scheduleWordOfDayNotification();
  }

  /// Schedule the Word of the Day notification
  ///
  /// This method should be called on app startup and when settings change.
  /// To implement actual notifications, integrate with flutter_local_notifications:
  ///
  /// ```dart
  /// await flutterLocalNotificationsPlugin.zonedSchedule(
  ///   0,
  ///   'Word of the Day',
  ///   'Tap to learn today\'s new word!',
  ///   _nextInstanceOfTime(notificationTime),
  ///   notificationDetails,
  ///   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  ///   uiLocalNotificationDateInterpretation:
  ///       UILocalNotificationDateInterpretation.absoluteTime,
  ///   matchDateTimeComponents: DateTimeComponents.time,
  /// );
  /// ```
  Future<void> scheduleWordOfDayNotification() async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final time = await getNotificationTime();

    if (kDebugMode) {
      print(
          '📅 Word of Day notification scheduled for ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    }

    // TODO: Implement actual notification scheduling
    // This requires adding flutter_local_notifications package
  }

  /// Cancel the Word of the Day notification
  Future<void> cancelWordOfDayNotification() async {
    if (kDebugMode) {
      print('🔕 Word of Day notification cancelled');
    }

    // TODO: Implement actual notification cancellation
    // await flutterLocalNotificationsPlugin.cancel(0);
  }

  /// Show an immediate notification (for testing)
  Future<void> showTestNotification(WordOfDay word) async {
    if (kDebugMode) {
      print('🔔 Test notification: ${word.word} - ${word.translation}');
    }

    // TODO: Implement actual notification display
    // await flutterLocalNotificationsPlugin.show(
    //   0,
    //   'Word of the Day: ${word.word}',
    //   word.translation,
    //   notificationDetails,
    // );
  }

  /// Initialize the notification service
  ///
  /// Call this on app startup to set up notification channels and permissions.
  Future<void> initialize() async {
    // Request notification permissions if needed
    // Set up notification channels for Android
    // Initialize flutter_local_notifications plugin

    if (kDebugMode) {
      print('📱 Notification service initialized');
    }

    // Schedule notification if enabled
    await scheduleWordOfDayNotification();
  }
}

/// TimeOfDay class for notification scheduling
/// Using a simple class since we're not importing material.dart in services
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
