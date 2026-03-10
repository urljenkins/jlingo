import 'package:flutter/material.dart';
import '../../models/gamification.dart';

/// Streak flame indicator
class StreakFlame extends StatelessWidget {
  final int streakDays;
  final bool isActive;
  final double size;
  final bool showLabel;

  const StreakFlame({
    super.key,
    required this.streakDays,
    required this.isActive,
    this.size = 32,
    this.showLabel = true,
  });

  Color _getFlameColor() {
    if (!isActive) return Colors.grey;
    if (streakDays >= 30) return const Color(0xFFFFD700); // Gold
    if (streakDays >= 14) return const Color(0xFFFF6B35); // Orange
    if (streakDays >= 7) return const Color(0xFFFF4757); // Red
    return const Color(0xFFFF9F43); // Light orange
  }

  @override
  Widget build(BuildContext context) {
    final color = _getFlameColor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect for active streak
            if (isActive && streakDays > 0)
              Container(
                width: size * 1.5,
                height: size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            Icon(
              Icons.local_fire_department,
              color: color,
              size: size,
            ),
          ],
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            streakDays > 0 ? 'Day $streakDays' : 'No streak',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Streak calendar showing last 7 days
class StreakCalendar extends StatelessWidget {
  final StreakInfo streakInfo;
  final int daysToShow;

  const StreakCalendar({
    super.key,
    required this.streakInfo,
    this.daysToShow = 7,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(daysToShow, (i) {
      return now.subtract(Duration(days: daysToShow - 1 - i));
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  StreakFlame(
                    streakDays: streakInfo.currentStreak,
                    isActive: streakInfo.isActiveToday,
                    size: 24,
                    showLabel: false,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Weekly Streak',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (streakInfo.longestStreak > 0)
                Text(
                  'Best: ${streakInfo.longestStreak} days',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((day) {
              final isStudied = _hasStudiedOnDay(day);
              final isToday = _isSameDay(day, now);

              return _DayIndicator(
                day: day,
                isStudied: isStudied,
                isToday: isToday,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _hasStudiedOnDay(DateTime day) {
    return streakInfo.studyHistory
        .any((studyDate) => _isSameDay(studyDate, day));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayIndicator extends StatelessWidget {
  final DateTime day;
  final bool isStudied;
  final bool isToday;

  const _DayIndicator({
    required this.day,
    required this.isStudied,
    required this.isToday,
  });

  String _getDayName() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[day.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _getDayName(),
          style: TextStyle(
            color: isToday ? const Color(0xFF00D9FF) : Colors.white54,
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isStudied
                ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isToday
                  ? const Color(0xFF00D9FF)
                  : isStudied
                      ? const Color(0xFFFF6B35)
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: isStudied
                ? const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFFF6B35),
                    size: 20,
                  )
                : Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isToday ? const Color(0xFF00D9FF) : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Streak milestone badge
class StreakMilestoneBadge extends StatelessWidget {
  final int milestone;
  final bool isAchieved;

  const StreakMilestoneBadge({
    super.key,
    required this.milestone,
    required this.isAchieved,
  });

  String _getMilestoneIcon() {
    if (milestone >= 365) return '🏆';
    if (milestone >= 180) return '💎';
    if (milestone >= 100) return '🌟';
    if (milestone >= 60) return '🔥';
    if (milestone >= 30) return '⚡';
    if (milestone >= 14) return '🎯';
    if (milestone >= 7) return '💪';
    return '✨';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAchieved
            ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAchieved
              ? const Color(0xFFFF6B35)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getMilestoneIcon(),
            style: TextStyle(
              fontSize: 16,
              color: isAchieved ? null : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$milestone days',
            style: TextStyle(
              color: isAchieved ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (isAchieved) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_circle,
              color: Color(0xFF00FF85),
              size: 16,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full streak panel with calendar and milestones
class StreakPanel extends StatelessWidget {
  final StreakInfo streakInfo;

  const StreakPanel({
    super.key,
    required this.streakInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with streak flame
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreakFlame(
                streakDays: streakInfo.currentStreak,
                isActive: streakInfo.isActiveToday,
                size: 48,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${streakInfo.currentStreak}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const Text(
                    'day streak',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Streak multiplier
          if (streakInfo.currentStreak > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withValues(alpha: 0.2),
                    const Color(0xFFFFD700).withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: Color(0xFFFFD700),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${streakInfo.multiplier.toStringAsFixed(1)}x XP Bonus',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Warning if streak is at risk
          if (streakInfo.atRisk) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4757).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF4757),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Color(0xFFFF4757),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your streak is at risk! Practice today to keep it going.',
                      style: TextStyle(
                        color: Color(0xFFFF4757),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Calendar
          StreakCalendar(streakInfo: streakInfo),
          const SizedBox(height: 20),

          // Milestones
          const Text(
            'Milestones',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StreakConfig.milestones.map((milestone) {
              return StreakMilestoneBadge(
                milestone: milestone,
                isAchieved: streakInfo.currentStreak >= milestone ||
                    streakInfo.longestStreak >= milestone,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Compact streak indicator for top bar
class CompactStreakIndicator extends StatelessWidget {
  final StreakInfo streakInfo;
  final VoidCallback? onTap;

  const CompactStreakIndicator({
    super.key,
    required this.streakInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: streakInfo.isActiveToday
              ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: streakInfo.atRisk
                ? const Color(0xFFFF4757)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              color: streakInfo.isActiveToday
                  ? const Color(0xFFFF6B35)
                  : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${streakInfo.currentStreak}',
              style: TextStyle(
                color: streakInfo.isActiveToday ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (streakInfo.atRisk) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.warning_amber,
                color: Color(0xFFFF4757),
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
