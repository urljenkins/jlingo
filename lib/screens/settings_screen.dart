import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              _buildSectionHeader('Learning & Habits'),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Progress Tracking',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Show streaks, XP, levels and daily targets. Off by '
                    'default — lessons and your place in the course work '
                    'either way.',
                    style: AppTypography.caption,
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: settings.progressTrackingEnabled,
                  onChanged: (value) {
                    unawaited(settings.setProgressTrackingEnabled(value));
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Audio & Pronunciation'),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
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
                              color: AppColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.speed,
                              color: AppColors.textSecondary,
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
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Slow', style: AppTypography.caption),
                          Expanded(
                            child: Slider(
                              value: settings.speechRate,
                              min: 0.2,
                              divisions: 8,
                              label:
                                  '${(settings.speechRate * 2).toStringAsFixed(1)}x',
                              onChanged: (value) {
                                unawaited(settings.setSpeechRate(value));
                                unawaited(AudioService().setSpeechRate(value));
                              },
                            ),
                          ),
                          const Text('Fast', style: AppTypography.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Notifications'),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
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
                    style: AppTypography.caption,
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
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
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const ListTile(
                  leading:
                      Icon(Icons.info_outline, color: AppColors.textSecondary),
                  title: Text('Lingua Sprint',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Version 1.0.0 • Hyper-efficient language learning',
                      style: AppTypography.caption),
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
        style: AppTypography.sectionLabel,
      ),
    );
  }
}
