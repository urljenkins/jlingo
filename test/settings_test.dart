import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingua_sprint/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initializes with default values', () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      expect(provider.progressTrackingEnabled, isFalse);
      expect(provider.notificationsEnabled, isTrue);
      expect(provider.speechRate, 0.5);
    });

    test('updates and persists progress tracking setting', () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      await provider.setProgressTrackingEnabled(true);
      expect(provider.progressTrackingEnabled, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_progress_tracking_enabled'), isTrue);

      // Re-load into fresh provider
      final freshProvider = SettingsProvider();
      await freshProvider.loadSettings();
      expect(freshProvider.progressTrackingEnabled, isTrue);
    });

    test('updates notifications and speech rate', () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      await provider.setNotificationsEnabled(false);
      expect(provider.notificationsEnabled, isFalse);

      await provider.setSpeechRate(0.8);
      expect(provider.speechRate, 0.8);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('wod_notifications_enabled'), isFalse);
      expect(prefs.getDouble('settings_tts_speech_rate'), 0.8);
    });
  });
}
