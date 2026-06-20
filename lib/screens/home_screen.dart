import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dart:math' as math;
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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Sub-tab indices
  int _activityHubIndex = 0; // 0 = Run, 1 = Quests, 2 = Workout
  int _nexusHubIndex = 0; // 0 = Marketplace, 1 = Friends, 2 = Leaderboard

  final FirestoreService _firestore = FirestoreService();
  final AuthService _authService = AuthService();

  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _navController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated Particle Background ───────────────
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticleBackgroundPainter(
                  progress: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // ── Premium Radial Glow Backgrounds ───────────
          Positioned(
            top: -120,
            left: -80,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: _GlowOrb(
                    radius: 280,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _GlowOrb(
              radius: 350,
              color: AppColors.secondary.withValues(alpha: 0.08),
            ),
          ),

          // ── Main Content Area ─────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: _getPage(user.uid),
                ),
                const SizedBox(height: 92),
              ],
            ),
          ),

          // ── Floating Glassmorphism Bottom Navigation ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.white.withValues(alpha: 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavBarItem(
                          0, Icons.dashboard_rounded, 'Dashboard'),
                      _buildNavBarItem(
                          1, Icons.fitness_center_rounded, 'Activity'),
                      _buildNavBarItem(2, Icons.flash_on_rounded, 'Combat'),
                      _buildNavBarItem(
                          3, Icons.catching_pokemon_rounded, 'Cards'),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    AppColors.secondary.withValues(alpha: 0.12),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? AppColors.secondary : Colors.white38,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 10 : 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.secondary : Colors.white30,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

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

  // ── Tab 0: Premium Dashboard Screen ─────────────────
  Widget _buildDashboard(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.userProfileStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading your adventure...',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
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

        final xpForLevel = level * 1000;
        final xpProgress = (xp % xpForLevel) / xpForLevel;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Premium Header ────────────────────────────
              Row(
                children: [
                  _buildAvatarRing(photoUrl, xpProgress),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryMedium],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'LVL $level',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildGlassButton(
                    icon: Icons.logout_rounded,
                    onTap: () => _authService.signOut(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── XP Progress Banner ────────────────────────
              _buildXPBanner(level, xp, xpForLevel, xpProgress),
              const SizedBox(height: 16),

              // ── Currency & Stats Row ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildGlassStatCard(
                      icon: Icons.monetization_on_rounded,
                      label: 'GOLD',
                      value: '$gold',
                      iconColor: Colors.amber,
                      glowColor: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGlassStatCard(
                      icon: Icons.local_fire_department_rounded,
                      label: 'STREAK',
                      value: '$currentStreak',
                      iconColor: Colors.orangeAccent,
                      glowColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGlassStatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'QUESTS',
                      value: '$questsCompleted',
                      iconColor: AppColors.secondary,
                      glowColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Quick Action Cards ────────────────────────
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),

              _buildQuickActionCard(
                icon: Icons.assignment_rounded,
                iconColor: AppColors.secondary,
                title: 'Daily Quests',
                subtitle: 'Complete challenges for XP & rewards',
                gradient: [
                  AppColors.secondary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
                onTap: () => setState(() {
                  _currentIndex = 1;
                  _activityHubIndex = 1;
                }),
              ),
              const SizedBox(height: 10),

              _buildQuickActionCard(
                icon: Icons.directions_run_rounded,
                iconColor: AppColors.primaryLight,
                title: 'GPS Running',
                subtitle: 'Track your run and earn XP per km',
                gradient: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primaryMedium.withValues(alpha: 0.04),
                ],
                onTap: () => setState(() {
                  _currentIndex = 1;
                  _activityHubIndex = 0;
                }),
              ),
              const SizedBox(height: 10),

              _buildQuickActionCard(
                icon: Icons.emoji_events_rounded,
                iconColor: Colors.amber,
                title: 'Achievements',
                subtitle: 'View your unlocked badges & milestones',
                gradient: [
                  Colors.amber.withValues(alpha: 0.06),
                  Colors.orange.withValues(alpha: 0.03),
                ],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: AppColors.background,
                        appBar: AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          iconTheme:
                              const IconThemeData(color: Colors.white),
                        ),
                        body: const AchievementsScreen(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              _buildQuickActionCard(
                icon: Icons.flash_on_rounded,
                iconColor: Colors.redAccent,
                title: 'Battle Arena',
                subtitle: 'Challenge monsters & other players',
                gradient: [
                  Colors.redAccent.withValues(alpha: 0.06),
                  Colors.deepOrange.withValues(alpha: 0.03),
                ],
                onTap: () => setState(() => _currentIndex = 2),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // Animated XP ring around the avatar
  Widget _buildAvatarRing(String? photoUrl, double xpProgress) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.2 + (_pulseController.value * 0.15),
                ),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _XPRingPainter(
              progress: xpProgress,
              color: AppColors.primary,
            ),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryMedium],
                  ),
                ),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildXPBanner(
      int level, int xp, int xpForLevel, double xpProgress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceDeep,
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryLight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Experience',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${xp % xpForLevel} / $xpForLevel XP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${(xpProgress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: xpProgress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${xpForLevel - (xp % xpForLevel)} XP to Level ${level + 1}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color glowColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: glowColor.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: glowColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: iconColor.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Activity Hub ─────────────────────────────
  Widget _buildActivityHub() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTab(
                    label: 'GPS Running',
                    icon: Icons.directions_run_rounded,
                    isSelected: _activityHubIndex == 0,
                    onTap: () => setState(() => _activityHubIndex = 0),
                  ),
                ),
                Expanded(
                  child: _buildSubTab(
                    label: 'Daily Quests',
                    icon: Icons.assignment_rounded,
                    isSelected: _activityHubIndex == 1,
                    onTap: () => setState(() => _activityHubIndex = 1),
                  ),
                ),
                Expanded(
                  child: _buildSubTab(
                    label: 'Workout',
                    icon: Icons.fitness_center_rounded,
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTab(
                    label: 'Market',
                    icon: Icons.storefront_rounded,
                    isSelected: _nexusHubIndex == 0,
                    onTap: () => setState(() => _nexusHubIndex = 0),
                  ),
                ),
                Expanded(
                  child: _buildSubTab(
                    label: 'Friends',
                    icon: Icons.people_rounded,
                    isSelected: _nexusHubIndex == 1,
                    onTap: () => setState(() => _nexusHubIndex = 1),
                  ),
                ),
                Expanded(
                  child: _buildSubTab(
                    label: 'Rankings',
                    icon: Icons.leaderboard_rounded,
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
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.secondary.withValues(alpha: 0.08),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.secondary : Colors.white38,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.secondary : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated Particle Background Painter ──────────────
class _ParticleBackgroundPainter extends CustomPainter {
  final double progress;
  _ParticleBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final y = (baseY - progress * size.height * speed) % size.height;
      final radius = 1.0 + rng.nextDouble() * 2.0;
      final alpha = 0.05 + rng.nextDouble() * 0.12;

      final isPurple = rng.nextBool();
      paint.color = isPurple
          ? AppColors.primary.withValues(alpha: alpha)
          : AppColors.secondary.withValues(alpha: alpha * 0.6);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── XP Ring Painter ───────────────────────────────────
class _XPRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _XPRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [color, AppColors.secondary, color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _XPRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Glow Orb Widget ───────────────────────────────────
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
            color.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
