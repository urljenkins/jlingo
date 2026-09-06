import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing application settings
class SettingsProvider extends ChangeNotifier {
  static const String _streakMonitoringEnabledKey =
      'settings_streak_monitoring_enabled';
  static const String _notificationsEnabledKey = 'wod_notifications_enabled';
  static const String _speechRateKey = 'settings_tts_speech_rate';

  bool _streakMonitoringEnabled = true;
  bool _notificationsEnabled = true;
  double _speechRate = 0.5;
  bool _isLoading = true;

  bool get streakMonitoringEnabled => _streakMonitoringEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  double get speechRate => _speechRate;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    // loadSettings can be invoked or awaited as needed
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _streakMonitoringEnabled =
          prefs.getBool(_streakMonitoringEnabledKey) ?? true;
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _speechRate = prefs.getDouble(_speechRateKey) ?? 0.5;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setStreakMonitoringEnabled(bool enabled) async {
    if (_streakMonitoringEnabled == enabled) return;
    _streakMonitoringEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_streakMonitoringEnabledKey, enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<void> setSpeechRate(double rate) async {
    final clamped = rate.clamp(0.2, 1.0);
    if (_speechRate == clamped) return;
    _speechRate = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, clamped);
  }
}
