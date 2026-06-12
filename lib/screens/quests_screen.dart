import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Local state for quest simulation if offline or dev testing
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Daily Quests',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reset in 14 hours 22 minutes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Streak Tracking Row ───────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryBorder.withValues(alpha: 0.3),
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
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$currentStreak Day Streak',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Streak Multiplier: ${(1.0 + (currentStreak * 0.05)).toStringAsFixed(2)}x',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final dayNum = index + 1;
                          final isCompleted = currentStreak >= dayNum;
                          final isToday = (currentStreak % 7) == index;

                          return Column(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : isToday
                                          ? AppColors.secondary.withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.04),
                                  border: Border.all(
                                    color: isCompleted
                                        ? AppColors.primary
                                        : isToday
                                            ? AppColors.secondary
                                            : Colors.white.withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    isCompleted
                                        ? Icons.check_rounded
                                        : Icons.bolt_rounded,
                                    size: 16,
                                    color: isCompleted
                                        ? AppColors.primaryLight
                                        : isToday
                                            ? AppColors.secondary
                                            : Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Day $dayNum',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isToday
                                      ? AppColors.secondary
                                      : Colors.white.withValues(alpha: 0.4),
                                  fontWeight:
                                      isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Quests List ───────────────────────────
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDone
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.05),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quest['title'],
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDone ? Colors.white : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      quest['subtitle'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.monetization_on_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+${quest['goldReward']}',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progressPercent,
                                    minHeight: 8,
                                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDone ? AppColors.secondary : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                '${quest['current'].toStringAsFixed(0)}/${quest['target'].toStringAsFixed(0)} ${quest['unit']}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isDone ? 'COMPLETED' : 'IN PROGRESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDone ? AppColors.secondary : AppColors.primaryLight,
                                  letterSpacing: 1.0,
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
                                      color: AppColors.primary.withValues(alpha: 0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Simulate Progress',
                                    style: TextStyle(fontSize: 12, color: Colors.white),
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
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Claimed ${quest['goldReward']} GOLD & ${quest['xpReward']} XP!',
                                          ),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Claim Rewards',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: AppColors.secondary,
                                      size: 18,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Claimed',
                                      style: TextStyle(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
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
