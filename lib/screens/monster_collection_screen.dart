import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

// ─── Inner Glow Painter ─────────────────────────────────────────────────────
class _InnerGlowPainter extends CustomPainter {
  final Color color;
  final double intensity;

  _InnerGlowPainter({required this.color, this.intensity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final radius = size.width * 0.38;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.35 * intensity),
          color.withValues(alpha: 0.12 * intensity),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _InnerGlowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.intensity != intensity;
}

// ─── Shimmer Border Painter (for Rare cards) ────────────────────────────────
class _ShimmerBorderPainter extends CustomPainter {
  final Color baseColor;
  final double progress;

  _ShimmerBorderPainter({required this.baseColor, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    final sweep = SweepGradient(
      startAngle: 0,
      endAngle: pi * 2,
      transform: GradientRotation(progress * pi * 2),
      colors: [
        baseColor.withValues(alpha: 0.0),
        baseColor.withValues(alpha: 0.6),
        Colors.white.withValues(alpha: 0.9),
        baseColor.withValues(alpha: 0.6),
        baseColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
    );

    final borderPaint = Paint()
      ..shader = sweep.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── Main Screen ────────────────────────────────────────────────────────────
class MonsterCollectionScreen extends StatefulWidget {
  const MonsterCollectionScreen({super.key});

  @override
  State<MonsterCollectionScreen> createState() => _MonsterCollectionScreenState();
}

class _MonsterCollectionScreenState extends State<MonsterCollectionScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  late TabController _tabController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  String _selectedElement = 'All';
  String _sortBy = 'Rarity';

  // 50 Predefined Monsters Database
  final List<Map<String, dynamic>> _allMonsters = List.generate(50, (index) {
    final elements = ['Fire', 'Water', 'Wind', 'Electric', 'Nature'];
    final rarities = ['Common', 'Uncommon', 'Rare'];
    final element = elements[index % 5];
    final rarity = rarities[index % 3];

    int hp = 100 + (index * 4);
    int atk = 20 + (index * 2);
    int def = 15 + (index * 2);

    return {
      'id': 'mon_$index',
      'name': '$element Guardian #${index + 1}',
      'element': element,
      'rarity': rarity,
      'hp': hp,
      'atk': atk,
      'def': def,
      'level': 1 + (index % 5),
    };
  });

  List<String> _activeDeck = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────
  String _getMonsterAsset(String element) {
    switch (element) {
      case 'Fire':
        return 'assets/monsters/fire_guardian.png';
      case 'Water':
        return 'assets/monsters/ice_guardian.png';
      case 'Wind':
        return 'assets/monsters/shadow_guardian.png';
      case 'Electric':
        return 'assets/monsters/thunder_guardian.png';
      case 'Nature':
        return 'assets/monsters/nature_guardian.png';
      default:
        return 'assets/monsters/fire_guardian.png';
    }
  }

  Color _getElementColor(String element) {
    switch (element) {
      case 'Fire':
        return Colors.redAccent;
      case 'Water':
        return AppColors.secondary;
      case 'Wind':
        return Colors.greenAccent;
      case 'Electric':
        return Colors.amber;
      case 'Nature':
        return const Color(0xFF50C878);
      default:
        return Colors.white;
    }
  }

  IconData _getElementIcon(String element) {
    switch (element) {
      case 'Fire':
        return Icons.local_fire_department_rounded;
      case 'Water':
        return Icons.water_drop_rounded;
      case 'Wind':
        return Icons.air_rounded;
      case 'Electric':
        return Icons.bolt_rounded;
      case 'Nature':
        return Icons.eco_rounded;
      default:
        return Icons.circle;
    }
  }

  List<Color> _getCardGradient(String element) {
    switch (element) {
      case 'Fire':
        return [
          const Color(0xFF2A0A0A),
          const Color(0xFF1A0505),
          AppColors.surfaceVariant,
        ];
      case 'Water':
        return [
          const Color(0xFF0A1A2A),
          const Color(0xFF050F1A),
          AppColors.surfaceVariant,
        ];
      case 'Wind':
        return [
          const Color(0xFF0A2A15),
          const Color(0xFF051A0D),
          AppColors.surfaceVariant,
        ];
      case 'Electric':
        return [
          const Color(0xFF2A2A0A),
          const Color(0xFF1A1A05),
          AppColors.surfaceVariant,
        ];
      case 'Nature':
        return [
          const Color(0xFF0A2A0A),
          const Color(0xFF051A05),
          AppColors.surfaceVariant,
        ];
      default:
        return [
          AppColors.surfaceVariant,
          AppColors.surface,
          AppColors.surfaceVariant,
        ];
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Rare':
        return const Color(0xFFFFD700);
      case 'Uncommon':
        return AppColors.primary;
      default:
        return Colors.white38;
    }
  }

  void _toggleDeckCard(String cardId) {
    setState(() {
      if (_activeDeck.contains(cardId)) {
        _activeDeck.remove(cardId);
      } else {
        if (_activeDeck.length < 5) {
          _activeDeck.add(cardId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deck is limited to 5 cards max.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    });

    if (_user != null) {
      _firestore.updateActiveDeck(_user.uid, _activeDeck);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.userProfileStream(_user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;

        final List<dynamic> rawMonsters = userData?['monsters'] ?? [];
        final List<String> ownedIds = rawMonsters.map((e) => e.toString()).toList();

        if (ownedIds.isEmpty && snapshot.connectionState == ConnectionState.active) {
          ownedIds.addAll(['mon_0', 'mon_1', 'mon_2', 'mon_3', 'mon_4']);
          _firestore.updateUserProfile(_user.uid, {'monsters': ownedIds});
        }

        final List<dynamic> rawDeck = userData?['activeDeck'] ?? [];
        _activeDeck = rawDeck.map((e) => e.toString()).toList();
        if (_activeDeck.isEmpty && ownedIds.isNotEmpty) {
          _activeDeck = ownedIds.take(5).toList();
        }

        List<Map<String, dynamic>> filteredInventory = _allMonsters.where((mon) {
          final isOwned = ownedIds.contains(mon['id']);
          final matchesElement =
              _selectedElement == 'All' || mon['element'] == _selectedElement;
          return isOwned && matchesElement;
        }).toList();

        if (_sortBy == 'Rarity') {
          final rarityWeights = {'Rare': 3, 'Uncommon': 2, 'Common': 1};
          filteredInventory.sort((a, b) =>
              (rarityWeights[b['rarity']] ?? 0)
                  .compareTo(rarityWeights[a['rarity']] ?? 0));
        } else if (_sortBy == 'Level') {
          filteredInventory.sort((a, b) => b['level'].compareTo(a['level']));
        } else if (_sortBy == 'ATK') {
          filteredInventory.sort((a, b) => b['atk'].compareTo(a['atk']));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.secondary,
            labelColor: AppColors.secondary,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Collection Grid'),
              Tab(text: 'Active Deck (5)'),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCollectionTab(filteredInventory),
              _buildDeckTab(),
            ],
          ),
        );
      },
    );
  }

  // ─── TAB 1: Collection Grid ─────────────────────────────────────────────
  Widget _buildCollectionTab(List<Map<String, dynamic>> filteredInventory) {
    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedElement,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                    items: ['All', 'Fire', 'Water', 'Wind', 'Electric', 'Nature'].map((el) {
                      return DropdownMenuItem(
                        value: el,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (el != 'All')
                              Icon(_getElementIcon(el),
                                  size: 14, color: _getElementColor(el)),
                            if (el != 'All') const SizedBox(width: 6),
                            Text(el),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedElement = val!),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                    items: ['Rarity', 'Level', 'ATK'].map((sort) {
                      return DropdownMenuItem(
                        value: sort,
                        child: Text('Sort: $sort'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _sortBy = val!),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: filteredInventory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 12),
                      const Text(
                        'No matching cards in collection yet.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filteredInventory.length,
                  itemBuilder: (context, index) {
                    final monster = filteredInventory[index];
                    return TweenAnimationBuilder<double>(
                      key: ValueKey(monster['id']),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 400 + (index * 60)),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                        );
                      },
                      child: _buildMonsterCard(monster),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Monster Card ───────────────────────────────────────────────────────
  Widget _buildMonsterCard(Map<String, dynamic> monster) {
    final isSelected = _activeDeck.contains(monster['id']);
    final elementColor = _getElementColor(monster['element']);
    final isRare = monster['rarity'] == 'Rare';
    final gradColors = _getCardGradient(monster['element']);
    final rarityColor = _getRarityColor(monster['rarity']);

    // stat max references for bar fill
    final maxHp = 300.0;
    final maxAtk = 120.0;
    final maxDef = 120.0;

    return GestureDetector(
      onTap: () => _toggleDeckCard(monster['id']),
      child: AnimatedBuilder(
        animation: isRare ? _shimmerController : const AlwaysStoppedAnimation(0),
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: isRare
                ? _ShimmerBorderPainter(
                    baseColor: const Color(0xFFFFD700),
                    progress: _shimmerController.value,
                  )
                : null,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradColors,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.secondary
                  : (isRare ? Colors.transparent : elementColor.withValues(alpha: 0.2)),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inner glow behind monster
              if (isSelected)
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(double.infinity, double.infinity),
                      painter: _InnerGlowPainter(
                        color: elementColor,
                        intensity: 0.6 + (_floatController.value * 0.4),
                      ),
                    );
                  },
                )
              else
                CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: _InnerGlowPainter(color: elementColor, intensity: 0.5),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: rarity + level
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: rarityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: rarityColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            monster['rarity'].toString().toUpperCase(),
                            style: TextStyle(
                              color: rarityColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LV ${monster['level']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Monster image
                    Expanded(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                _getMonsterAsset(monster['element']),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.catching_pokemon_rounded,
                                    size: 48,
                                    color: elementColor,
                                  );
                                },
                              ),
                            ),
                            // In-deck check mark
                            if (isSelected)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.secondary.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.check, size: 10, color: Colors.black),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Name row + element badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            monster['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Element badge
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: elementColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: elementColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getElementIcon(monster['element']),
                            size: 12,
                            color: elementColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Stat bars
                    _buildStatBar('HP', monster['hp'], maxHp, Colors.greenAccent),
                    const SizedBox(height: 4),
                    _buildStatBar('ATK', monster['atk'], maxAtk, Colors.redAccent),
                    const SizedBox(height: 4),
                    _buildStatBar('DEF', monster['def'], maxDef, AppColors.secondary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, int value, double maxValue, Color barColor) {
    final fill = (value / maxValue).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fill,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [
                      barColor.withValues(alpha: 0.7),
                      barColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 22,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─── TAB 2: Deck Builder ────────────────────────────────────────────────
  Widget _buildDeckTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text(
            'Combat Active Deck',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Your deck must contain exactly 5 monster cards for battles.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Deck count indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: List.generate(5, (i) {
              final filled = i < _activeDeck.length;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: filled
                        ? AppColors.secondary
                        : Colors.white.withValues(alpha: 0.1),
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ]
                        : [],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Horizontal card previews
        SizedBox(
          height: 200,
          child: _activeDeck.isEmpty
              ? Center(
                  child: Text(
                    'Tap cards in collection to build your active deck.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _activeDeck.length,
                  itemBuilder: (context, index) {
                    final cardId = _activeDeck[index];
                    final monster = _allMonsters.firstWhere(
                      (m) => m['id'] == cardId,
                      orElse: () => _allMonsters.first,
                    );
                    final elementColor = _getElementColor(monster['element']);
                    final gradColors = _getCardGradient(monster['element']);

                    return TweenAnimationBuilder<double>(
                      key: ValueKey('deck_$cardId'),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 350 + (index * 80)),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: gradColors,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: elementColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: elementColor.withValues(alpha: 0.15),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Glow
                            CustomPaint(
                              size: const Size(140, 200),
                              painter: _InnerGlowPainter(
                                color: elementColor,
                                intensity: 0.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  // Slot number
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '#${index + 1}',
                                          style: const TextStyle(
                                            color: AppColors.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        _getElementIcon(monster['element']),
                                        size: 14,
                                        color: elementColor,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Monster image
                                  Expanded(
                                    child: Image.asset(
                                      _getMonsterAsset(monster['element']),
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.catching_pokemon_rounded,
                                          size: 40,
                                          color: elementColor,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    monster['name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ATK ${monster['atk']}  •  HP ${monster['hp']}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Remove button
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _toggleDeckCard(cardId),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.redAccent),
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

        const SizedBox(height: 16),

        // Drag handle visual separator
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Deck Cards',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Detailed deck list
        Expanded(
          child: _activeDeck.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _activeDeck.length,
                  itemBuilder: (context, index) {
                    final cardId = _activeDeck[index];
                    final monster = _allMonsters.firstWhere(
                      (m) => m['id'] == cardId,
                      orElse: () => _allMonsters.first,
                    );
                    final elementColor = _getElementColor(monster['element']);

                    return TweenAnimationBuilder<double>(
                      key: ValueKey('list_$cardId'),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 60)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(30 * (1 - value), 0),
                          child: Opacity(
                              opacity: value.clamp(0.0, 1.0), child: child),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: elementColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Drag handle cue
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            // Monster image thumb
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: elementColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: elementColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.asset(
                                  _getMonsterAsset(monster['element']),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.catching_pokemon,
                                      color: elementColor,
                                      size: 24,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    monster['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        _getElementIcon(monster['element']),
                                        size: 11,
                                        color: elementColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        monster['element'],
                                        style: TextStyle(
                                          color: elementColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        '  •  ATK ${monster['atk']}  •  HP ${monster['hp']}  •  DEF ${monster['def']}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _toggleDeckCard(cardId),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                  size: 20,
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
      ],
    );
  }
}


