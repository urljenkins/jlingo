import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing application settings
class SettingsProvider extends ChangeNotifier {
  /// Gates every form of progress tracking: streaks, XP, levels, daily
  /// targets and mastery percentages. Off by default — the app is a library
  /// first, and scoring is opt-in.
  static const String _progressTrackingEnabledKey =
      'settings_progress_tracking_enabled';

  /// Superseded by [_progressTrackingEnabledKey]. Read once so existing
  /// users who had opted into streaks keep tracking switched on.
  static const String _legacyStreakMonitoringEnabledKey =
      'settings_streak_monitoring_enabled';
  static const String _notificationsEnabledKey = 'wod_notifications_enabled';
  static const String _speechRateKey = 'settings_tts_speech_rate';

  bool _progressTrackingEnabled = false;
  bool _notificationsEnabled = true;
  double _speechRate = 0.5;
  bool _isLoading = true;

  bool get progressTrackingEnabled => _progressTrackingEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  double get speechRate => _speechRate;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _progressTrackingEnabled = prefs.getBool(_progressTrackingEnabledKey) ??
          await _migrateLegacyStreakSetting(prefs);
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _speechRate = prefs.getDouble(_speechRateKey) ?? 0.5;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Carries a pre-existing streak preference over to the new key, so the
  /// rename does not silently flip tracking off for someone who wanted it.
  /// Absent that preference, tracking starts off.
  Future<bool> _migrateLegacyStreakSetting(SharedPreferences prefs) async {
    final legacy = prefs.getBool(_legacyStreakMonitoringEnabledKey);
    if (legacy == null) return false;

    await prefs.setBool(_progressTrackingEnabledKey, legacy);
    await prefs.remove(_legacyStreakMonitoringEnabledKey);
    return legacy;
  }

  Future<void> setProgressTrackingEnabled(bool enabled) async {
    if (_progressTrackingEnabled == enabled) return;
    _progressTrackingEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_progressTrackingEnabledKey, enabled);
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
