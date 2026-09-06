import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Shared audio service for TTS and native audio playback
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal() {
    // Subscribe once: this is a singleton, so subscribing per playback call
    // would accumulate listeners for the lifetime of the app.
    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
    });
  }

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final StreamSubscription<void> _completeSubscription;

  bool _isPlaying = false;
  double _speechRate = 0.5;

  bool get isPlaying => _isPlaying;

  /// Initialize TTS with a specific language
  Future<void> initializeTts({
    required String language,
    double speechRate = 0.5,
    double volume = 1.0,
    double pitch = 1.0,
  }) async {
    _speechRate = speechRate;

    await _tts.setLanguage(language);
    await _tts.setSpeechRate(speechRate);
    await _tts.setVolume(volume);
    await _tts.setPitch(pitch);
  }

  /// Set speech rate for TTS (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _tts.setSpeechRate(_speechRate);
  }

  /// Get current speech rate
  double get speechRate => _speechRate;

  /// Speak text using TTS
  Future<void> speak(String text, {String? language}) async {
    if (language != null) {
      await _tts.setLanguage(language);
    }
    _isPlaying = true;
    await _tts.speak(text);
    _isPlaying = false;
  }

  /// Play native audio from assets
  Future<void> playAssetAudio(String assetPath) async {
    _isPlaying = true;
    await _audioPlayer.play(AssetSource(assetPath));
  }

  /// Play native audio from URL
  Future<void> playUrlAudio(String url) async {
    _isPlaying = true;
    await _audioPlayer.play(UrlSource(url));
  }

  /// Pause audio playback
  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  /// Resume audio playback
  Future<void> resume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
  }

  /// Stop all audio playback
  Future<void> stop() async {
    await _tts.stop();
    await _audioPlayer.stop();
    _isPlaying = false;
  }

  /// Get audio duration (for native audio)
  Future<Duration?> getDuration() async {
    return await _audioPlayer.getDuration();
  }

  /// Get current position (for native audio)
  Future<Duration?> getCurrentPosition() async {
    return await _audioPlayer.getCurrentPosition();
  }

  /// Seek to position (for native audio)
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Set playback speed for native audio
  Future<void> setPlaybackRate(double rate) async {
    await _audioPlayer.setPlaybackRate(rate);
  }

  /// Stream of player state changes
  Stream<PlayerState> get onPlayerStateChanged =>
      _audioPlayer.onPlayerStateChanged;

  /// Stream of position changes
  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;

  /// Dispose resources
  Future<void> dispose() async {
    await _completeSubscription.cancel();
    await _tts.stop();
    await _audioPlayer.dispose();
  }
}
