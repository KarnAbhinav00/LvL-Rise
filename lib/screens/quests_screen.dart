import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

// ── Glowing Progress Bar Painter ───────────────────────────────────────────
class _GlowingProgressBarPainter extends CustomPainter {
  final double progress;
  final Color glowColor;

  _GlowingProgressBarPainter({required this.progress, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Track background
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, trackPaint);

    if (progress > 0) {
      final width = size.width * progress;
      final progressRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, size.height),
        const Radius.circular(4),
      );

      // Glow backdrop
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawRRect(progressRect, glowPaint);

      // Main gradient bar
      final progressPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            glowColor.withValues(alpha: 0.7),
            glowColor,
          ],
        ).createShader(Rect.fromLTWH(0, 0, width, size.height))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(progressRect, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowingProgressBarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.glowColor != glowColor;
}

// ── Pulsing Streak Day Widget ─────────────────────────────────────────────
class _PulsingStreakDay extends StatefulWidget {
  final int dayNum;
  final bool isCompleted;
  final bool isToday;

  const _PulsingStreakDay({
    required this.dayNum,
    required this.isCompleted,
    required this.isToday,
  });

  @override
  State<_PulsingStreakDay> createState() => _PulsingStreakDayState();
}

class _PulsingStreakDayState extends State<_PulsingStreakDay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isToday) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderGlowColor = widget.isCompleted
        ? AppColors.primary
        : widget.isToday
            ? AppColors.secondary
            : Colors.white.withValues(alpha: 0.1);

    final bgFillColor = widget.isCompleted
        ? AppColors.primary.withValues(alpha: 0.25)
        : widget.isToday
            ? AppColors.secondary.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.03);

    final iconColor = widget.isCompleted
        ? AppColors.primaryLight
        : widget.isToday
            ? AppColors.secondary
            : Colors.white.withValues(alpha: 0.2);

    Widget innerCircle = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgFillColor,
        border: Border.all(
          color: borderGlowColor,
          width: 1.5,
        ),
        boxShadow: [
          if (widget.isCompleted || widget.isToday)
            BoxShadow(
              color: borderGlowColor.withValues(alpha: 0.25),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Center(
        child: Icon(
          widget.isCompleted ? Icons.check_rounded : Icons.bolt_rounded,
          size: 16,
          color: iconColor,
        ),
      ),
    );

    if (widget.isToday) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: innerCircle,
      );
    }

    return innerCircle;
  }
}

// ── Quests Screen ─────────────────────────────────────────────────────────
class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Local state for quest simulation
  final List<Map<String, dynamic>> _mockQuests = [
    {
      'id': 'run_2km',
      'title': 'Daily Run challenge',
      'subtitle': 'Run 2km to level up endurance',
      'target': 2.0,
      'current': 0.0,
      'unit': 'km',
      'xpReward': 150,
      'goldReward': 200,
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'id': 'pushups_20',
      'title': 'Calisthenics Grind',
      'subtitle': 'Do 20 pushups to boost strength',
      'target': 20.0,
      'current': 0.0,
      'unit': 'reps',
      'xpReward': 100,
      'goldReward': 100,
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'id': 'yoga_10',
      'title': 'Mindful Flow',
      'subtitle': '10 minutes of yoga or flexibility stretch',
      'target': 10.0,
      'current': 0.0,
      'unit': 'min',
      'xpReward': 100,
      'goldReward': 100,
      'isCompleted': false,
      'isClaimed': false,
    }
  ];

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.userProfileStream(_user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final currentStreak = userData?['currentStreak'] ?? 0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Quests',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reset in 14 hours 22 minutes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Streak Tracking Row (Glassmorphic) ───────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Colors.orangeAccent,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$currentStreak Day Streak',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'x${(1.0 + (currentStreak * 0.05)).toStringAsFixed(2)} Mult',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (index) {
                              final dayNum = index + 1;
                              final isCompleted = currentStreak >= dayNum;
                              final isToday = (currentStreak % 7) == index;

                              return Column(
                                children: [
                                  _PulsingStreakDay(
                                    dayNum: dayNum,
                                    isCompleted: isCompleted,
                                    isToday: isToday,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Day $dayNum',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isToday
                                          ? AppColors.secondary
                                          : Colors.white.withValues(alpha: 0.4),
                                      fontWeight: isToday
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Quests List ─────────────────────────────────────────────
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _mockQuests.length,
                  itemBuilder: (context, index) {
                    final quest = _mockQuests[index];
                    final progressPercent =
                        (quest['current'] / quest['target']).clamp(0.0, 1.0);
                    final isDone = progressPercent >= 1.0;
                    final isClaimed = quest['isClaimed'];

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 80)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    isDone
                                        ? AppColors.primary.withValues(alpha: 0.08)
                                        : Colors.white.withValues(alpha: 0.04),
                                    Colors.white.withValues(alpha: 0.01),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDone
                                      ? AppColors.primary.withValues(alpha: 0.35)
                                      : Colors.white.withValues(alpha: 0.06),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              quest['title'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              quest['subtitle'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withValues(alpha: 0.45),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Gold reward badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.amber.withValues(alpha: 0.25),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.monetization_on_rounded,
                                              color: Colors.amber,
                                              size: 13,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '+${quest['goldReward']}',
                                              style: const TextStyle(
                                                color: Colors.amber,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Glowing progress bar
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 7,
                                          child: CustomPaint(
                                            painter: _GlowingProgressBarPainter(
                                              progress: progressPercent,
                                              glowColor: isDone
                                                  ? AppColors.secondary
                                                  : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${quest['current'].toStringAsFixed(0)}/${quest['target'].toStringAsFixed(0)} ${quest['unit']}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Action row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isDone ? 'COMPLETED' : 'IN PROGRESS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isDone
                                              ? AppColors.secondary
                                              : AppColors.primaryLight,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      if (!isDone)
                                        OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              quest['current'] = quest['target'];
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.3),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 0),
                                            minimumSize: const Size(0, 32),
                                          ),
                                          child: const Text(
                                            'Simulate Progress',
                                            style: TextStyle(
                                                fontSize: 11, color: Colors.white70),
                                          ),
                                        )
                                      else if (isDone && !isClaimed)
                                        ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              quest['isClaimed'] = true;
                                            });
                                            await _firestore.completeQuest(
                                              uid: _user.uid,
                                              questId: quest['id'],
                                              xpEarned: quest['xpReward'],
                                              goldEarned: quest['goldReward'],
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Claimed ${quest['goldReward']} GOLD & ${quest['xpReward']} XP!',
                                                  ),
                                                  backgroundColor:
                                                      AppColors.primary,
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.secondary,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 0),
                                            minimumSize: const Size(0, 32),
                                          ),
                                          child: const Text(
                                            'Claim Rewards',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11),
                                          ),
                                        )
                                      else
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline_rounded,
                                              color: AppColors.secondary,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Claimed',
                                              style: TextStyle(
                                                color: AppColors.secondary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
