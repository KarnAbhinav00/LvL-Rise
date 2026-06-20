import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  Spark / Particle CustomPainter
// ─────────────────────────────────────────────────────────────
class _SparkParticle {
  double x, y, vx, vy, life, maxLife, size;
  Color color;
  _SparkParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
  });
}

class _BattleSparkPainter extends CustomPainter {
  final List<_SparkParticle> particles;
  _BattleSparkPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(p.x, p.y), p.size * opacity, paint);

      // Tiny glow halo
      final glow = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(p.x, p.y), p.size * opacity * 2.5, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _BattleSparkPainter old) => true;
}

// ─────────────────────────────────────────────────────────────
//  Glowing Border Painter for battle cards
// ─────────────────────────────────────────────────────────────
class _GlowBorderPainter extends CustomPainter {
  final Color color;
  final double intensity;
  _GlowBorderPainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.12 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(rect, glowPaint);

    // Mid glow
    final midPaint = Paint()
      ..color = color.withValues(alpha: 0.25 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rect, midPaint);

    // Inner crisp border
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.45 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter old) =>
      old.intensity != intensity || old.color != color;
}

// ─────────────────────────────────────────────────────────────
//  Main Battle Arena Screen
// ─────────────────────────────────────────────────────────────
class BattleArenaScreen extends StatefulWidget {
  const BattleArenaScreen({super.key});

  @override
  State<BattleArenaScreen> createState() => _BattleArenaScreenState();
}

class _BattleArenaScreenState extends State<BattleArenaScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  // ── Battle state variables ──────────────────────────────
  bool _inBattle = false;
  bool _searching = false;
  String _combatLog = 'Search for a duel to begin!';
  int _turn = 1;

  // Player & Opponent stats
  Map<String, dynamic>? _playerActiveMonster;
  Map<String, dynamic>? _opponentActiveMonster;

  int _playerHP = 100;
  int _opponentHP = 100;

  List<Map<String, dynamic>> _playerDeck = [];



  // ── Animation controllers ──────────────────────────────
  late AnimationController _vsPulseController;
  late Animation<double> _vsPulseAnim;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  late AnimationController _playerHPAnimController;
  late Animation<double> _playerHPAnim;

  late AnimationController _opponentHPAnimController;
  late Animation<double> _opponentHPAnim;

  late AnimationController _sparkController;

  // Spark particles
  final List<_SparkParticle> _sparks = [];
  final Random _rand = Random();

  // ── Monster model lookup (unchanged) ───────────────────
  final List<Map<String, dynamic>> _monsterModels = List.generate(50, (index) {
    final elements = ['Fire', 'Water', 'Wind', 'Electric', 'Nature'];
    final element = elements[index % 5];
    return {
      'id': 'mon_$index',
      'name': '$element Guardian #${index + 1}',
      'element': element,
      'hp': 100 + (index * 2),
      'atk': 25 + index,
      'def': 15 + index,
    };
  });

  @override
  void initState() {
    super.initState();

    // VS pulse: loops forever between 0.7 → 1.0 scale
    _vsPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _vsPulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _vsPulseController, curve: Curves.easeInOut),
    );

    // Screen shake: one-shot
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    // HP bar animations
    _playerHPAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _playerHPAnim = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _playerHPAnimController, curve: Curves.easeOut),
    );

    _opponentHPAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opponentHPAnim = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _opponentHPAnimController, curve: Curves.easeOut),
    );

    // Spark particle ticker
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _sparkController.addListener(_tickSparks);
  }

  @override
  void dispose() {
    _vsPulseController.dispose();
    _shakeController.dispose();
    _playerHPAnimController.dispose();
    _opponentHPAnimController.dispose();
    _sparkController.removeListener(_tickSparks);
    _sparkController.dispose();
    super.dispose();
  }

  // ── Spark particle management ──────────────────────────
  void _spawnSparks(Color color, {int count = 18}) {
    for (int i = 0; i < count; i++) {
      _sparks.add(_SparkParticle(
        x: 80 + _rand.nextDouble() * 200,
        y: 40 + _rand.nextDouble() * 120,
        vx: (_rand.nextDouble() - 0.5) * 6,
        vy: (_rand.nextDouble() - 0.5) * 6,
        life: 0.6 + _rand.nextDouble() * 0.6,
        maxLife: 0.6 + _rand.nextDouble() * 0.6,
        size: 2 + _rand.nextDouble() * 4,
        color: color,
      ));
    }
  }

  void _tickSparks() {
    const dt = 0.016; // ~60fps
    for (final p in _sparks) {
      p.x += p.vx;
      p.y += p.vy;
      p.life -= dt;
      p.vy += 0.1; // gravity
    }
    _sparks.removeWhere((p) => p.life <= 0);
    if (mounted) setState(() {});
  }

  // ── Element to asset path ──────────────────────────────
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

  List<Color> _getElementGradient(String element) {
    switch (element) {
      case 'Fire':
        return [
          const Color(0xFF1A0505),
          const Color(0xFF2D0A0A),
          Colors.redAccent.withValues(alpha: 0.08),
        ];
      case 'Water':
        return [
          const Color(0xFF051019),
          const Color(0xFF071A2D),
          AppColors.secondary.withValues(alpha: 0.08),
        ];
      case 'Wind':
        return [
          const Color(0xFF050F0A),
          const Color(0xFF0A1F12),
          Colors.greenAccent.withValues(alpha: 0.08),
        ];
      case 'Electric':
        return [
          const Color(0xFF14100A),
          const Color(0xFF231C0A),
          Colors.amber.withValues(alpha: 0.08),
        ];
      case 'Nature':
        return [
          const Color(0xFF081209),
          const Color(0xFF0F1F10),
          const Color(0xFF50C878).withValues(alpha: 0.08),
        ];
      default:
        return [AppColors.surface, AppColors.surfaceVariant, AppColors.surface];
    }
  }

  // ── Trigger screen shake + sparks ─────────────────────
  void _triggerAttackEffects(Color elementColor) {
    _shakeController.forward(from: 0.0);
    _spawnSparks(elementColor, count: 22);
  }

  // ── Animate HP bars ────────────────────────────────────
  void _animatePlayerHP(double from, double to) {
    _playerHPAnim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _playerHPAnimController, curve: Curves.easeOut),
    );
    _playerHPAnimController.forward(from: 0.0);
  }

  void _animateOpponentHP(double from, double to) {
    _opponentHPAnim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(
          parent: _opponentHPAnimController, curve: Curves.easeOut),
    );
    _opponentHPAnimController.forward(from: 0.0);
  }

  // ──────────────────────────────────────────────────────────
  //  GAME LOGIC (unchanged from original)
  // ──────────────────────────────────────────────────────────
  void _searchMatch(List<dynamic> activeDeckIds) {
    setState(() {
      _searching = true;
      _combatLog = 'Searching for verified competitor on the network...';
    });

    // Generate player deck
    _playerDeck = activeDeckIds.map((id) {
      return _monsterModels.firstWhere(
        (m) => m['id'] == id,
        orElse: () => _monsterModels.first,
      );
    }).toList();

    if (_playerDeck.isEmpty) {
      _playerDeck = _monsterModels.take(5).toList();
    }

    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final rand = Random();
      final opponentMonster =
          _monsterModels[rand.nextInt(_monsterModels.length)];

      setState(() {
        _searching = false;
        _inBattle = true;
        _playerActiveMonster = _playerDeck.first;
        _opponentActiveMonster = opponentMonster;
        _playerHP = _playerActiveMonster!['hp'];
        _opponentHP = _opponentActiveMonster!['hp'];
        _turn = 1;
        _combatLog =
            'Verified match found! Opponent sent out ${_opponentActiveMonster!['name']}.';


        _playerHPAnim = AlwaysStoppedAnimation(1.0);
        _opponentHPAnim = AlwaysStoppedAnimation(1.0);
      });
    });
  }

  double _getTypingMultiplier(String playerElement, String opponentElement) {
    if (playerElement == 'Fire' && opponentElement == 'Nature') return 1.5;
    if (playerElement == 'Nature' && opponentElement == 'Water') return 1.5;
    if (playerElement == 'Water' && opponentElement == 'Fire') return 1.5;
    if (playerElement == 'Electric' && opponentElement == 'Water') return 1.5;
    if (playerElement == 'Nature' && opponentElement == 'Fire') return 0.5;
    if (playerElement == 'Water' && opponentElement == 'Nature') return 0.5;
    if (playerElement == 'Fire' && opponentElement == 'Water') return 0.5;
    if (playerElement == 'Water' && opponentElement == 'Electric') return 0.5;
    return 1.0;
  }

  void _executeTurn(String playerAction) {
    if (_playerActiveMonster == null || _opponentActiveMonster == null) return;

    final rand = Random();
    int pAtk = _playerActiveMonster!['atk'];
    int oAtk = _opponentActiveMonster!['atk'];
    int pDef = _playerActiveMonster!['def'];
    int oDef = _opponentActiveMonster!['def'];

    String playerLog = '';
    String opponentLog = '';

    bool opponentEvaded =
        _opponentActiveMonster!['element'] == 'Wind' && rand.nextDouble() < 0.25;
    bool playerEvaded =
        _playerActiveMonster!['element'] == 'Wind' && rand.nextDouble() < 0.25;

    final double oldOpponentPercent =
        (_opponentHP / _opponentActiveMonster!['hp']).clamp(0.0, 1.0);
    final double oldPlayerPercent =
        (_playerHP / _playerActiveMonster!['hp']).clamp(0.0, 1.0);

    // 1. Player Action
    if (playerAction == 'Attack') {
      if (opponentEvaded) {
        playerLog =
            '${_opponentActiveMonster!['name']} dodged the attack using Wind Evasion!';
      } else {
        final mult = _getTypingMultiplier(
          _playerActiveMonster!['element'],
          _opponentActiveMonster!['element'],
        );
        int damage = ((pAtk - (oDef * 0.4)) * mult).round().clamp(10, 80);
        _opponentHP = (_opponentHP - damage).clamp(0, 9999);
        playerLog =
            'Your ${_playerActiveMonster!['name']} used Attack dealing $damage DMG! (Type Mult: ${mult}x)';
        _triggerAttackEffects(
            _getElementColor(_playerActiveMonster!['element']));
      }
    } else if (playerAction == 'Defend') {
      pDef += 15;
      playerLog =
          'Your ${_playerActiveMonster!['name']} prepared a solid defense shield!';
    } else if (playerAction == 'Swap') {
      final currentIdx = _playerDeck.indexOf(_playerActiveMonster!);
      final nextIdx = (currentIdx + 1) % _playerDeck.length;
      _playerActiveMonster = _playerDeck[nextIdx];
      _playerHP = _playerActiveMonster!['hp'];
      playerLog =
          'You swapped active monster to ${_playerActiveMonster!['name']}!';
    }

    if (_opponentHP <= 0) {
      final newOppPercent =
          (_opponentHP / _opponentActiveMonster!['hp']).clamp(0.0, 1.0);
      _animateOpponentHP(oldOpponentPercent, newOppPercent);
      _endBattle(true);
      return;
    }

    // 2. Opponent AI Action
    final oAction = rand.nextDouble() < 0.85 ? 'Attack' : 'Defend';
    if (oAction == 'Attack') {
      if (playerEvaded) {
        opponentLog =
            'Your ${_playerActiveMonster!['name']} dodged the incoming attack!';
      } else {
        final mult = _getTypingMultiplier(
          _opponentActiveMonster!['element'],
          _playerActiveMonster!['element'],
        );
        int damage = ((oAtk - (pDef * 0.4)) * mult).round().clamp(10, 80);
        _playerHP = (_playerHP - damage).clamp(0, 9999);
        opponentLog =
            'Opponent ${_opponentActiveMonster!['name']} counters with Attack dealing $damage DMG!';
        _triggerAttackEffects(
            _getElementColor(_opponentActiveMonster!['element']));
      }
    } else {
      opponentLog = 'Opponent ${_opponentActiveMonster!['name']} defends!';
    }

    if (_playerHP <= 0) {
      final newPlayerPercent =
          (_playerHP / _playerActiveMonster!['hp']).clamp(0.0, 1.0);
      _animatePlayerHP(oldPlayerPercent, newPlayerPercent);
      _endBattle(false);
      return;
    }

    // Animate HP bars to new values
    final newOppPercent =
        (_opponentHP / _opponentActiveMonster!['hp']).clamp(0.0, 1.0);
    final newPlayerPercent =
        (_playerHP / _playerActiveMonster!['hp']).clamp(0.0, 1.0);
    _animateOpponentHP(oldOpponentPercent, newOppPercent);
    _animatePlayerHP(oldPlayerPercent, newPlayerPercent);



    setState(() {
      _turn++;
      _combatLog = '$playerLog\n\n$opponentLog';
    });
  }

  void _endBattle(bool isVictory) async {
    final goldReward = isVictory ? 75 : 0;

    if (_user != null) {
      await _firestore.recordBattleResult(_user.uid, isVictory, goldReward);
    }

    setState(() {
      _inBattle = false;
      _combatLog = isVictory
          ? 'Victory! You defeated the opponent. Earned +75 GOLD!'
          : 'Defeat. Better luck next time!';
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isVictory
                ? AppColors.secondary.withValues(alpha: 0.3)
                : Colors.redAccent.withValues(alpha: 0.3),
          ),
        ),
        title: Text(
          isVictory ? 'BATTLE VICTORY' : 'DEFEATED',
          style: TextStyle(
            color: isVictory ? AppColors.secondary : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isVictory
              ? 'Your deck performed outstandingly! You rewarded +75 GOLD.'
              : 'You lost the battle, but there is no gold penalty. Adjust your active deck in Collection!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.userProfileStream(_user.uid),
        builder: (context, snapshot) {
          final userData =
              snapshot.data?.data() as Map<String, dynamic>?;
          final List<dynamic> rawDeck = userData?['activeDeck'] ?? [];
          final activeDeckIds = rawDeck.map((e) => e.toString()).toList();

          return AnimatedBuilder(
            animation: _shakeAnim,
            builder: (context, child) {
              final shakeOffset =
                  sin(_shakeAnim.value * pi * 6) * 6 * (1 - _shakeAnim.value);
              return Transform.translate(
                offset: Offset(shakeOffset, 0),
                child: child,
              );
            },
            child: Stack(
              children: [
                // Spark particle overlay
                if (_sparks.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _BattleSparkPainter(_sparks),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [AppColors.secondary, AppColors.primary],
                          ).createShader(bounds),
                          child: const Text(
                            'Combat Arena',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (!_inBattle) ...[
                          // ── Pre-battle screen ──────────────
                          const Spacer(),
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.all(
                                  color: AppColors.secondary, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.15),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.security_rounded,
                                size: 64,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'ANTI-CHEAT VERIFIED LOBBY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All combat matches are encrypted. Cheat tools or fake sensors are blocked.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _combatLog,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 15),
                          ),
                          const Spacer(),
                          if (_searching)
                            const CircularProgressIndicator(
                                color: AppColors.secondary)
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _searchMatch(activeDeckIds),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'SEARCH DUEL MATCH',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                        ] else ...[
                          // ── Active Battle HUD ─────────────
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'TURN $_turn',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Colors.amber.withValues(alpha: 0.1),
                                ),
                                child: const Icon(Icons.flash_on_rounded,
                                    color: Colors.amber, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Opponent card
                          _buildPremiumFighterCard(
                            name: _opponentActiveMonster!['name'],
                            element: _opponentActiveMonster!['element'],
                            hp: _opponentHP,
                            maxHp: _opponentActiveMonster!['hp'],
                            isPlayer: false,
                            hpAnimation: _opponentHPAnim,
                            hpAnimController: _opponentHPAnimController,
                          ),

                          const SizedBox(height: 12),

                          // ── Pulsing VS badge ──────────────
                          AnimatedBuilder(
                            animation: _vsPulseAnim,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _vsPulseAnim.value,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.3),
                                    AppColors.primary.withValues(alpha: 0.05),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'VS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Player card
                          _buildPremiumFighterCard(
                            name: _playerActiveMonster!['name'],
                            element: _playerActiveMonster!['element'],
                            hp: _playerHP,
                            maxHp: _playerActiveMonster!['hp'],
                            isPlayer: true,
                            hpAnimation: _playerHPAnim,
                            hpAnimController: _playerHPAnimController,
                          ),

                          const SizedBox(height: 16),

                          // ── Combat log ─────────────────────
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.surface,
                                    AppColors.surfaceVariant
                                        .withValues(alpha: 0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.06)),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _combatLog,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Battle action buttons ─────────
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  label: 'ATTACK',
                                  color: Colors.redAccent,
                                  icon: Icons.local_fire_department_rounded,
                                  onTap: () => _executeTurn('Attack'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'DEFEND',
                                  color: AppColors.primary,
                                  icon: Icons.shield_rounded,
                                  onTap: () => _executeTurn('Defend'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'SWAP',
                                  color: Colors.white24,
                                  icon: Icons.swap_horiz_rounded,
                                  onTap: () => _executeTurn('Swap'),
                                  outlined: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  Premium Fighter Card with glowing border + monster image
  // ──────────────────────────────────────────────────────────
  Widget _buildPremiumFighterCard({
    required String name,
    required String element,
    required int hp,
    required int maxHp,
    required bool isPlayer,
    required Animation<double> hpAnimation,
    required AnimationController hpAnimController,
  }) {
    final elementColor = _getElementColor(element);
    final gradient = _getElementGradient(element);
    final assetPath = _getMonsterAsset(element);

    return CustomPaint(
      foregroundPainter:
          _GlowBorderPainter(color: elementColor, intensity: 1.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: Row(
          children: [
            // Monster image with element glow
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: elementColor.withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: elementColor.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: elementColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Icon(
                    Icons.pets_rounded,
                    color: elementColor,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isPlayer
                                  ? AppColors.secondary
                                  : Colors.redAccent)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (isPlayer
                                    ? AppColors.secondary
                                    : Colors.redAccent)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          isPlayer ? 'YOU' : 'ENEMY',
                          style: TextStyle(
                            fontSize: 9,
                            color: isPlayer
                                ? AppColors.secondary
                                : Colors.redAccent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Element tag
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: elementColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: elementColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        element.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: elementColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Animated HP bar
                  AnimatedBuilder(
                    animation: hpAnimation,
                    builder: (context, _) {
                      final hpPercent = hpAnimation.value.clamp(0.0, 1.0);
                      final barColor = hpPercent > 0.5
                          ? Colors.greenAccent
                          : hpPercent > 0.25
                              ? Colors.orangeAccent
                              : Colors.redAccent;
                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: hpPercent,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      colors: [
                                        barColor,
                                        barColor.withValues(alpha: 0.7),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: barColor
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$hp/$maxHp',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  Premium action button
  // ──────────────────────────────────────────────────────────
  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          minimumSize: const Size(0, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.85),
        minimumSize: const Size(0, 52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
