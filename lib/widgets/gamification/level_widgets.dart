import 'package:flutter/material.dart';
import '../../models/gamification.dart';

/// Level badge with title and animated effects
class LevelBadge extends StatelessWidget {
  final UserLevel userLevel;
  final double size;
  final bool showTitle;
  final bool compact;

  const LevelBadge({
    super.key,
    required this.userLevel,
    this.size = 80,
    this.showTitle = true,
    this.compact = false,
  });

  Color _getLevelColor(int level) {
    if (level >= 25) return const Color(0xFFFFD700); // Gold
    if (level >= 20) return const Color(0xFFE040FB); // Purple
    if (level >= 15) return const Color(0xFFFF4081); // Pink
    if (level >= 10) return const Color(0xFF00E5FF); // Cyan
    if (level >= 5) return const Color(0xFF00E676); // Green
    return const Color(0xFF90A4AE); // Grey-blue
  }

  IconData _getLevelIcon(int level) {
    if (level >= 25) return Icons.diamond;
    if (level >= 20) return Icons.auto_awesome;
    if (level >= 15) return Icons.workspace_premium;
    if (level >= 10) return Icons.stars;
    if (level >= 5) return Icons.shield;
    return Icons.school;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor(userLevel.level);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getLevelIcon(userLevel.level),
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Lv.${userLevel.level}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Badge background
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: color,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getLevelIcon(userLevel.level),
                    color: color,
                    size: size * 0.35,
                  ),
                  Text(
                    '${userLevel.level}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showTitle) ...[
          const SizedBox(height: 8),
          Text(
            userLevel.title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

/// Level up celebration overlay
class LevelUpCelebration extends StatefulWidget {
  final int newLevel;
  final String newTitle;
  final VoidCallback? onDismiss;

  const LevelUpCelebration({
    super.key,
    required this.newLevel,
    required this.newTitle,
    this.onDismiss,
  });

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _scaleController.forward();
    _particleController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rays effect
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _particleController,
                            builder: (context, _) {
                              return Transform.rotate(
                                angle: _particleController.value * 2 * 3.14159,
                                child: CustomPaint(
                                  size: const Size(200, 200),
                                  painter: _RaysPainter(
                                    color: const Color(0xFF00D9FF),
                                    progress: _particleController.value,
                                  ),
                                ),
                              );
                            },
                          ),
                          LevelBadge(
                            userLevel: UserLevel(
                              level: widget.newLevel,
                              title: widget.newTitle,
                              currentXP: 0,
                              xpForNextLevel: 0,
                              progress: 0,
                            ),
                            size: 120,
                            showTitle: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00D9FF),
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.newTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton(
                        onPressed: widget.onDismiss,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00D9FF)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'CONTINUE',
                          style: TextStyle(
                            color: Color(0xFF00D9FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final Color color;
  final double progress;

  _RaysPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * 3.14159;
      const innerRadius = 70.0;
      const outerRadius = 100.0;

      final start = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );
      final end = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) =>
      oldDelegate.progress != progress;

  double cos(double x) =>
      x < 3.14159 / 2 ? 1 - (x * x / 2) : -sin(x - 3.14159 / 2);

  double sin(double x) {
    x = x % (2 * 3.14159);
    if (x < 0) x += 2 * 3.14159;
    if (x < 3.14159 / 2) return x - x * x * x / 6;
    if (x < 3.14159) return sin(3.14159 - x);
    if (x < 3 * 3.14159 / 2) return -sin(x - 3.14159);
    return -sin(2 * 3.14159 - x);
  }
}

/// Skill tree node widget
class SkillTreeNode extends StatelessWidget {
  final SkillNode skill;
  final bool isSelected;
  final VoidCallback? onTap;

  const SkillTreeNode({
    super.key,
    required this.skill,
    this.isSelected = false,
    this.onTap,
  });

  Color _getNodeColor() {
    if (skill.isCompleted) return const Color(0xFF00FF85);
    if (!skill.isUnlocked) return Colors.grey.shade700;
    if (skill.mastery > 0) return const Color(0xFF00D9FF);
    return Colors.white.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getNodeColor();

    return GestureDetector(
      onTap: skill.isUnlocked ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: skill.mastery,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              // Node circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skill.isUnlocked
                      ? color.withValues(alpha: 0.15)
                      : Colors.grey.shade900,
                  border: Border.all(
                    color: color,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: skill.isCompleted
                      ? Icon(
                          Icons.check,
                          color: color,
                          size: 24,
                        )
                      : skill.isUnlocked
                          ? Text(
                              '${(skill.mastery * 100).round()}%',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Icon(
                              Icons.lock,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              skill.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: skill.isUnlocked ? Colors.white : Colors.grey.shade600,
                fontWeight:
                    skill.isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full skill tree visualization
class SkillTreeView extends StatelessWidget {
  final List<ProgressionPath> paths;
  final Function(String skillId)? onSkillTap;
  final String? selectedSkillId;

  const SkillTreeView({
    super.key,
    required this.paths,
    this.onSkillTap,
    this.selectedSkillId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paths.length,
      itemBuilder: (context, pathIndex) {
        final path = paths[pathIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Path header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      path.name,
                      style: const TextStyle(
                        color: Color(0xFF00D9FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${path.completedSkills}/${path.totalSkills}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: path.totalProgress,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF00D9FF),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Skills row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < path.skills.length; i++) ...[
                    SkillTreeNode(
                      skill: path.skills[i],
                      isSelected: path.skills[i].skillId == selectedSkillId,
                      onTap: () => onSkillTap?.call(path.skills[i].skillId),
                    ),
                    if (i < path.skills.length - 1)
                      Container(
                        width: 24,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: BoxDecoration(
                          color: path.skills[i].isCompleted
                              ? const Color(0xFF00FF85)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
