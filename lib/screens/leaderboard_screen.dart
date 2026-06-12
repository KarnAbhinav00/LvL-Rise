import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  String _selectedMetric = 'totalXp'; // totalXp, distance, workouts
  String _timeFilter = 'Weekly'; // Weekly, Monthly, All-Time

  // Mock global leaderboard values if database has no other users
  final List<Map<String, dynamic>> _mockLeaderboard = [
    {'displayName': 'XtremeFit', 'totalXp': 34500, 'distance': 84.5, 'workouts': 28},
    {'displayName': 'IronSpike', 'totalXp': 29100, 'distance': 64.2, 'workouts': 22},
    {'displayName': 'GluteForce', 'totalXp': 25000, 'distance': 45.1, 'workouts': 19},
    {'displayName': 'ZenFlex', 'totalXp': 19200, 'distance': 35.8, 'workouts': 15},
    {'displayName': 'CardioKing', 'totalXp': 18700, 'distance': 92.4, 'workouts': 14},
    {'displayName': 'HyperSlayer', 'totalXp': 14100, 'distance': 25.0, 'workouts': 11},
    {'displayName': 'AeroSprint', 'totalXp': 12000, 'distance': 48.2, 'workouts': 9},
    {'displayName': 'ActiveDave', 'totalXp': 9500, 'distance': 15.6, 'workouts': 8},
    {'displayName': 'GymBunny', 'totalXp': 8200, 'distance': 10.2, 'workouts': 6},
  ];

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.userProfileStream(_user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final myName = userData?['displayName'] ?? 'You';
        final myXp = userData?['totalXp'] ?? userData?['xp'] ?? 0;
        final myQuests = userData?['questsCompleted'] ?? 0;

        // Fetching leaderboard list
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _firestore.getLeaderboard(_selectedMetric),
          builder: (context, boardSnapshot) {
            List<Map<String, dynamic>> rankings = [];

            if (boardSnapshot.hasData && boardSnapshot.data!.isNotEmpty) {
              rankings = boardSnapshot.data!;
            } else {
              // Populate mock with user own stats to make it feel alive
              rankings = List.from(_mockLeaderboard);
              rankings.add({
                'displayName': '$myName (You)',
                'totalXp': myXp,
                'distance': (myQuests * 1.5).toDouble(), // mock distance
                'workouts': myQuests,
              });
            }

            // Sort rankings
            if (_selectedMetric == 'totalXp') {
              rankings.sort((a, b) => b['totalXp'].compareTo(a['totalXp']));
            } else if (_selectedMetric == 'distance') {
              rankings.sort((a, b) => b['distance'].compareTo(a['distance']));
            } else if (_selectedMetric == 'workouts') {
              rankings.sort((a, b) => b['workouts'].compareTo(a['workouts']));
            }

            // Select Top 10
            rankings = rankings.take(10).toList();

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Global Rankings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Time Filter Header ───────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['Weekly', 'Monthly', 'All-Time'].map((filter) {
                        final isSelected = _timeFilter == filter;
                        return GestureDetector(
                          onTap: () => setState(() => _timeFilter = filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.03),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.white12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Metric Type Filter ───────────────────
                    Row(
                      children: [
                        _buildMetricTab('XP Points', 'totalXp'),
                        const SizedBox(width: 12),
                        _buildMetricTab('Distance', 'distance'),
                        const SizedBox(width: 12),
                        _buildMetricTab('Workouts', 'workouts'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Leaderboard Table ────────────────────
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: ListView.builder(
                          itemCount: rankings.length,
                          itemBuilder: (context, index) {
                            final row = rankings[index];
                            final rank = index + 1;
                            final isMe = row['displayName'].toString().contains('(You)') ||
                                row['displayName'] == myName;

                            String valueStr = '';
                            if (_selectedMetric == 'totalXp') {
                              valueStr = '${row['totalXp']} XP';
                            } else if (_selectedMetric == 'distance') {
                              valueStr = '${row['distance'].toStringAsFixed(1)} km';
                            } else if (_selectedMetric == 'workouts') {
                              valueStr = '${row['workouts']} sets';
                            }

                            Color rankColor = Colors.white54;
                            if (rank == 1) rankColor = Colors.amber;
                            if (rank == 2) rankColor = const Color(0xFFC0C0C0);
                            if (rank == 3) rankColor = const Color(0xFFCD7F32);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  // Rank Number
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '#$rank',
                                      style: TextStyle(
                                        color: rankColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: rank <= 3 ? 16 : 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // User name
                                  Expanded(
                                    child: Text(
                                      row['displayName'],
                                      style: TextStyle(
                                        color: isMe ? AppColors.secondary : Colors.white,
                                        fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  // Score Value
                                  Text(
                                    valueStr,
                                    style: TextStyle(
                                      color: isMe ? AppColors.secondary : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricTab(String label, String metric) {
    final isSelected = _selectedMetric == metric;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMetric = metric),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.secondary : Colors.white10,
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.secondary : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
