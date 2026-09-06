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

    // Not yet implemented: scheduling needs flutter_local_notifications.
    // The preference is persisted, so enabling this later will pick up the
    // user's existing choice and time.
    debugPrint('Word of Day notification requested for $time '
        '(scheduling not implemented)');
  }

  /// Cancel the Word of the Day notification
  Future<void> cancelWordOfDayNotification() async {
    debugPrint('Word of Day notification cancelled '
        '(scheduling not implemented)');
  }

  /// Show an immediate notification (for testing)
  Future<void> showTestNotification(WordOfDay word) async {
    debugPrint('Test notification: ${word.word} - ${word.translation} '
        '(display not implemented)');
  }

  /// Initialize the notification service
  ///
  /// Call this on app startup to set up notification channels and permissions.
  Future<void> initialize() async {
    // Once flutter_local_notifications is added, this is where permissions
    // and the Android notification channel are set up.
    await scheduleWordOfDayNotification();
  }

  /// Whether notifications can actually be delivered on this build.
  ///
  /// Scheduling is not wired up yet, so the settings toggle only records a
  /// preference. Callers should use this to avoid promising delivery.
  bool get isDeliverySupported => false;
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
