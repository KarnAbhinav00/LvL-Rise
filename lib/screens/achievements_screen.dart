import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.userProfileStream(user.uid),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final level = userData?['level'] ?? 1;
          final quests = userData?['questsCompleted'] ?? 0;
          final currentStreak = userData?['currentStreak'] ?? 0;
          final List<dynamic> rawMonsters = userData?['monsters'] ?? [];
          final monstersCount = rawMonsters.length;

          // Compute stats
          final List<Map<String, dynamic>> achievements = [
            {
              'title': 'First Steps',
              'desc': 'Log your first workout or running activity',
              'progress': quests > 0 ? 1.0 : 0.0,
              'target': 1,
              'current': quests,
              'icon': Icons.bolt_rounded,
              'color': AppColors.secondary,
            },
            {
              'title': 'Consistency Grind',
              'desc': 'Complete 10 fitness quests',
              'progress': (quests / 10).clamp(0.0, 1.0),
              'target': 10,
              'current': quests,
              'icon': Icons.check_circle_rounded,
              'color': AppColors.primaryLight,
            },
            {
              'title': 'Streak Master',
              'desc': 'Achieve a 7-day workout streak',
              'progress': (currentStreak / 7).clamp(0.0, 1.0),
              'target': 7,
              'current': currentStreak,
              'icon': Icons.local_fire_department_rounded,
              'color': Colors.orangeAccent,
            },
            {
              'title': 'Monster Collector',
              'desc': 'Catch 10 unique RPG monsters',
              'progress': (monstersCount / 10).clamp(0.0, 1.0),
              'target': 10,
              'current': monstersCount,
              'icon': Icons.catching_pokemon_rounded,
              'color': Colors.greenAccent,
            },
            {
              'title': 'Ascension Tier',
              'desc': 'Reach Level 10 on your fitness character',
              'progress': (level / 10).clamp(0.0, 1.0),
              'target': 10,
              'current': level,
              'icon': Icons.workspace_premium_rounded,
              'color': Colors.amber,
            },
            {
              'title': 'Iron Warrior',
              'desc': 'Complete 50 strength training sets',
              'progress': (quests / 50).clamp(0.0, 1.0),
              'target': 50,
              'current': quests,
              'icon': Icons.fitness_center_rounded,
              'color': Colors.redAccent,
            },
          ];

          final unlockedCount = achievements.where((a) => a['progress'] >= 1.0).length;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Badges & Achievements',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Summary stats header
                  Text(
                    'Unlocked $unlockedCount of ${achievements.length} Badges',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: ListView.builder(
                      itemCount: achievements.length,
                      itemBuilder: (context, index) {
                        final ach = achievements[index];
                        final isUnlocked = ach['progress'] >= 1.0;
                        final color = ach['color'] as Color;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isUnlocked
                                  ? color.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.04),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge Icon
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isUnlocked
                                      ? color.withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isUnlocked
                                        ? color
                                        : Colors.white.withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                  boxShadow: isUnlocked
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.2),
                                            blurRadius: 12,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  ach['icon'],
                                  color: isUnlocked ? color : Colors.white24,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Text details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          ach['title'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isUnlocked ? Colors.white : Colors.white60,
                                          ),
                                        ),
                                        if (isUnlocked)
                                          const Text(
                                            'UNLOCKED',
                                            style: TextStyle(
                                              color: AppColors.secondary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      ach['desc'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.45),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: ach['progress'],
                                              minHeight: 6,
                                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isUnlocked ? color : AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${ach['current']}/${ach['target']}',
                                          style: TextStyle(
                                            color: isUnlocked ? color : Colors.white30,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
