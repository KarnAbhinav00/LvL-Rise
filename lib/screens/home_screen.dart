import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui'; // for ImageFilter backdrop blur
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

// Page imports
import 'quests_screen.dart';
import 'run_tracker_screen.dart';
import 'workout_logger_screen.dart';
import 'monster_collection_screen.dart';
import 'battle_arena_screen.dart';
import 'marketplace_screen.dart';
import 'friends_screen.dart';
import 'leaderboard_screen.dart';
import 'achievements_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Sub-tab indices
  int _activityHubIndex = 0; // 0 = Run, 1 = Workout
  int _nexusHubIndex = 0;    // 0 = Marketplace, 1 = Friends, 2 = Leaderboard

  final FirestoreService _firestore = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Premium Radial Glow Backgrounds ───────────
          Positioned(
            top: -100,
            left: -100,
            child: _GlowOrb(radius: 300, color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _GlowOrb(radius: 350, color: AppColors.secondary.withValues(alpha: 0.12)),
          ),

          // ── Main Content Area ─────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: _getPage(user.uid),
                ),
                const SizedBox(height: 90), // Space for bottom bar
              ],
            ),
          ),

          // ── Floating Glassmorphism Bottom Navigation ──
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavBarItem(0, Icons.dashboard_rounded, 'Dashboard'),
                      _buildNavBarItem(1, Icons.fitness_center_rounded, 'Activity'),
                      _buildNavBarItem(2, Icons.flash_on_rounded, 'Combat'),
                      _buildNavBarItem(3, Icons.catching_pokemon_rounded, 'Cards'),
                      _buildNavBarItem(4, Icons.language_rounded, 'Nexus'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.secondary : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.secondary : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  // Returns the active screen according to tab selection
  Widget _getPage(String uid) {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard(uid);
      case 1:
        return _buildActivityHub();
      case 2:
        return const BattleArenaScreen();
      case 3:
        return const MonsterCollectionScreen();
      case 4:
        return _buildNexusHub();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Tab 0: Dashboard Screen ─────────────────────────
  Widget _buildDashboard(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.userProfileStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final displayName = data?['displayName'] ?? 'Adventurer';
        final email = data?['email'] ?? '';
        final level = data?['level'] ?? 1;
        final xp = data?['xp'] ?? 0;
        final gold = data?['gold'] ?? 500;
        final questsCompleted = data?['questsCompleted'] ?? 0;
        final currentStreak = data?['currentStreak'] ?? 0;
        final photoUrl = data?['photoUrl'];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGlowShadow,
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              photoUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $displayName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _authService.signOut(),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Level & Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.surfaceDeep, AppColors.surfaceDark],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatChip(
                          icon: Icons.flash_on_rounded,
                          label: 'Level $level',
                        ),
                        _StatChip(
                          icon: Icons.monetization_on_rounded,
                          label: '$gold GOLD',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (xp % (level * 1000)) / (level * 1000),
                        minHeight: 10,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(level * 1000) - (xp % (level * 1000))} XP to next level',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Quests Done',
                      value: '$questsCompleted',
                      color: AppColors.primarySubtle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Day Streak',
                      value: '$currentStreak',
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Daily Quests summary button card
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.assignment_rounded, color: AppColors.secondary, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'View Daily Quests',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '3 challenges available today',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Achievements entry card
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: AppColors.background,
                        appBar: AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          iconTheme: const IconThemeData(color: Colors.white),
                        ),
                        body: const AchievementsScreen(),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unlocked Badges',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Show off your workout milestones',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 1: Activity Hub ─────────────────────────────
  Widget _buildActivityHub() {
    return Column(
      children: [
        // Sub tabs
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTab(
                    label: 'GPS Running',
                    isSelected: _activityHubIndex == 0,
                    onTap: () => setState(() => _activityHubIndex = 0),
                  ),
                ),
                Expanded(
                  child: _buildSubTab(
                    label: 'Daily Quests',
                    isSelected: _activityHubIndex == 1,
                    onTap: () => setState(() => _activityHubIndex = 1),
                  ),
                ),
                Expanded(
                  child: _buildSubTab(
                    label: 'Workout Logger',
                    isSelected: _activityHubIndex == 2,
                    onTap: () => setState(() => _activityHubIndex = 2),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: IndexedStack(
            index: _activityHubIndex,
            children: const [
              RunTrackerScreen(),
              QuestsScreen(),
              WorkoutLoggerScreen(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 4: Nexus Hub ────────────────────────────────
  Widget _buildNexusHub() {
    return Column(
      children: [
        // Sub tabs
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTab(
                    label: 'Marketplace',
                    isSelected: _nexusHubIndex == 0,
                    onTap: () => setState(() => _nexusHubIndex = 0),
                  ),
                ),
                Expanded(
                  child: _buildSubTab(
                    label: 'Friends List',
                    isSelected: _nexusHubIndex == 1,
                    onTap: () => setState(() => _nexusHubIndex = 1),
                  ),
                ),
                Expanded(
                  child: _buildSubTab(
                    label: 'Leaderboard',
                    isSelected: _nexusHubIndex == 2,
                    onTap: () => setState(() => _nexusHubIndex = 2),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: IndexedStack(
            index: _nexusHubIndex,
            children: const [
              MarketplaceScreen(),
              FriendsScreen(),
              LeaderboardScreen(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.secondary : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    this.color = AppColors.primaryLight,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.chipDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
