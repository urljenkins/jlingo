import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              _buildSectionHeader('Learning & Habits'),
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Streak Monitoring',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Track consecutive study days and show streak indicators on your home bar.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  activeThumbColor: const Color(0xFF00FF85),
                  value: settings.streakMonitoringEnabled,
                  onChanged: (value) {
                    unawaited(settings.setStreakMonitoringEnabled(value));
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Audio & Pronunciation'),
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D9FF)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.speed,
                              color: Color(0xFF00D9FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TTS Speech Speed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Adjust how fast spoken exercises and words are pronounced.',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Slow',
                              style: TextStyle(color: Colors.white54)),
                          Expanded(
                            child: Slider(
                              value: settings.speechRate,
                              min: 0.2,
                              divisions: 8,
                              label:
                                  '${(settings.speechRate * 2).toStringAsFixed(1)}x',
                              activeColor: const Color(0xFF00D9FF),
                              onChanged: (value) {
                                unawaited(settings.setSpeechRate(value));
                                unawaited(AudioService().setSpeechRate(value));
                              },
                            ),
                          ),
                          const Text('Fast',
                              style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Notifications'),
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Daily Reminders',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    NotificationService().isDeliverySupported
                        ? 'Receive Word of the Day and daily practice '
                            'reminders.'
                        : 'Word of the Day and practice reminders are coming '
                            'soon; your preference is saved for then.',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF85).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF00FF85),
                    ),
                  ),
                  activeThumbColor: const Color(0xFF00FF85),
                  value: settings.notificationsEnabled,
                  onChanged: (value) {
                    unawaited(settings.setNotificationsEnabled(value));
                    unawaited(
                        NotificationService().setNotificationsEnabled(value));
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('About'),
              Card(
                color: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.white70),
                  title: Text('Lingua Sprint',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Version 1.0.0 • Hyper-efficient language learning',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Colors.white54,
        ),
      ),
    );
  }
}
