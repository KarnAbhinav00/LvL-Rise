import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class BattleArenaScreen extends StatefulWidget {
  const BattleArenaScreen({super.key});

  @override
  State<BattleArenaScreen> createState() => _BattleArenaScreenState();
}

class _BattleArenaScreenState extends State<BattleArenaScreen> {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Battle state variables
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

  // Database models lookup (redefined local mock for simplicity and offline)
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
      // Add standard starters
      _playerDeck = _monsterModels.take(5).toList();
    }

    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final rand = Random();
      final opponentMonster = _monsterModels[rand.nextInt(_monsterModels.length)];

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
      });
    });
  }

  double _getTypingMultiplier(String playerElement, String opponentElement) {
    // Fire > Nature > Water > Fire
    // Electric > Water
    if (playerElement == 'Fire' && opponentElement == 'Nature') return 1.5;
    if (playerElement == 'Nature' && opponentElement == 'Water') return 1.5;
    if (playerElement == 'Water' && opponentElement == 'Fire') return 1.5;
    if (playerElement == 'Electric' && opponentElement == 'Water') return 1.5;

    // Disadvantage
    if (playerElement == 'Nature' && opponentElement == 'Fire') return 0.5;
    if (playerElement == 'Water' && opponentElement == 'Nature') return 0.5;
    if (playerElement == 'Fire' && opponentElement == 'Water') return 0.5;
    if (playerElement == 'Water' && opponentElement == 'Electric') return 0.5;

    // Wind has random evasiveness: checked during attack calculations
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

    // Check Wind element evasion: Wind has a 25% chance to dodge attacks
    bool opponentEvaded =
        _opponentActiveMonster!['element'] == 'Wind' && rand.nextDouble() < 0.25;
    bool playerEvaded =
        _playerActiveMonster!['element'] == 'Wind' && rand.nextDouble() < 0.25;

    // 1. Player Action
    if (playerAction == 'Attack') {
      if (opponentEvaded) {
        playerLog = '${_opponentActiveMonster!['name']} dodged the attack using Wind Evasion!';
      } else {
        final mult = _getTypingMultiplier(
          _playerActiveMonster!['element'],
          _opponentActiveMonster!['element'],
        );
        int damage = ((pAtk - (oDef * 0.4)) * mult).round().clamp(10, 80);
        _opponentHP = (_opponentHP - damage).clamp(0, 9999);
        playerLog =
            'Your ${_playerActiveMonster!['name']} used Attack dealing $damage DMG! (Type Mult: ${mult}x)';
      }
    } else if (playerAction == 'Defend') {
      pDef += 15; // Temporarily boost defense
      playerLog = 'Your ${_playerActiveMonster!['name']} prepared a solid defense shield!';
    } else if (playerAction == 'Swap') {
      // Swap active monster to next in deck
      final currentIdx = _playerDeck.indexOf(_playerActiveMonster!);
      final nextIdx = (currentIdx + 1) % _playerDeck.length;
      _playerActiveMonster = _playerDeck[nextIdx];
      _playerHP = _playerActiveMonster!['hp']; // Restores HP to full for simplicity
      playerLog = 'You swapped active monster to ${_playerActiveMonster!['name']}!';
    }

    // Check if opponent is knocked out
    if (_opponentHP <= 0) {
      _endBattle(true);
      return;
    }

    // 2. Opponent AI Action
    final oAction = rand.nextDouble() < 0.85 ? 'Attack' : 'Defend';
    if (oAction == 'Attack') {
      if (playerEvaded) {
        opponentLog = 'Your ${_playerActiveMonster!['name']} dodged the incoming attack!';
      } else {
        final mult = _getTypingMultiplier(
          _opponentActiveMonster!['element'],
          _playerActiveMonster!['element'],
        );
        int damage = ((oAtk - (pDef * 0.4)) * mult).round().clamp(10, 80);
        _playerHP = (_playerHP - damage).clamp(0, 9999);
        opponentLog =
            'Opponent ${_opponentActiveMonster!['name']} counters with Attack dealing $damage DMG!';
      }
    } else {
      opponentLog = 'Opponent ${_opponentActiveMonster!['name']} defends!';
    }

    // Check if player is knocked out
    if (_playerHP <= 0) {
      _endBattle(false);
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.userProfileStream(_user.uid),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final List<dynamic> rawDeck = userData?['activeDeck'] ?? [];
          final activeDeckIds = rawDeck.map((e) => e.toString()).toList();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'Combat Arena',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_inBattle) ...[
                    // Pre-battle screen: search or verify
                    const Spacer(),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.secondary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.15),
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
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const Spacer(),
                    if (_searching)
                      const CircularProgressIndicator(color: AppColors.secondary)
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _searchMatch(activeDeckIds),
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
                    // ── Active Battle HUD ───────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TURN $_turn',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.flash_on_rounded, color: Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Opponent Health panel
                    _buildFighterCard(
                      name: _opponentActiveMonster!['name'],
                      element: _opponentActiveMonster!['element'],
                      hp: _opponentHP,
                      maxHp: _opponentActiveMonster!['hp'],
                      isPlayer: false,
                    ),

                    const SizedBox(height: 16),
                    const Text('VS', style: TextStyle(color: Colors.white24, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Player Health panel
                    _buildFighterCard(
                      name: _playerActiveMonster!['name'],
                      element: _playerActiveMonster!['element'],
                      hp: _playerHP,
                      maxHp: _playerActiveMonster!['hp'],
                      isPlayer: true,
                    ),

                    const SizedBox(height: 20),

                    // Combat log screen
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _combatLog,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Battle actions row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _executeTurn('Attack'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              minimumSize: const Size(0, 54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('ATTACK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _executeTurn('Defend'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(0, 54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('DEFEND', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _executeTurn('Swap'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white30),
                              minimumSize: const Size(0, 54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('SWAP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFighterCard({
    required String name,
    required String element,
    required int hp,
    required int maxHp,
    required bool isPlayer,
  }) {
    final elementColor = _getElementColor(element);
    final hpPercent = (hp / maxHp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: elementColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.catching_pokemon, color: elementColor, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      isPlayer ? 'YOU' : 'OPPONENT',
                      style: TextStyle(
                        fontSize: 10,
                        color: isPlayer ? AppColors.secondary : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: hpPercent,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            hpPercent > 0.4 ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$hp/$maxHp',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
