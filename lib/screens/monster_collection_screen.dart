import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class MonsterCollectionScreen extends StatefulWidget {
  const MonsterCollectionScreen({super.key});

  @override
  State<MonsterCollectionScreen> createState() => _MonsterCollectionScreenState();
}

class _MonsterCollectionScreenState extends State<MonsterCollectionScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  late TabController _tabController;
  String _selectedElement = 'All';
  String _sortBy = 'Rarity';

  // 50 Predefined Monsters Database
  final List<Map<String, dynamic>> _allMonsters = List.generate(50, (index) {
    final elements = ['Fire', 'Water', 'Wind', 'Electric', 'Nature'];
    final rarities = ['Common', 'Uncommon', 'Rare'];
    final element = elements[index % 5];
    final rarity = rarities[index % 3];

    // Stats calculations
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

  // Local state active deck list (contains monster IDs)
  List<String> _activeDeck = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  // Toggles card selection for the deck
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

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.userProfileStream(_user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        
        // Load user owned monsters (raw strings IDs list)
        final List<dynamic> rawMonsters = userData?['monsters'] ?? [];
        final List<String> ownedIds = rawMonsters.map((e) => e.toString()).toList();

        // Fallback: if user has no monsters, grant them 5 starter cards
        if (ownedIds.isEmpty && snapshot.connectionState == ConnectionState.active) {
          ownedIds.addAll(['mon_0', 'mon_1', 'mon_2', 'mon_3', 'mon_4']);
          _firestore.updateUserProfile(_user.uid, {'monsters': ownedIds});
        }

        // Load active deck
        final List<dynamic> rawDeck = userData?['activeDeck'] ?? [];
        _activeDeck = rawDeck.map((e) => e.toString()).toList();
        if (_activeDeck.isEmpty && ownedIds.isNotEmpty) {
          _activeDeck = ownedIds.take(5).toList();
        }

        // Filter & Sort inventory
        List<Map<String, dynamic>> filteredInventory = _allMonsters.where((mon) {
          final isOwned = ownedIds.contains(mon['id']);
          final matchesElement = _selectedElement == 'All' || mon['element'] == _selectedElement;
          return isOwned && matchesElement;
        }).toList();

        if (_sortBy == 'Rarity') {
          final rarityWeights = {'Rare': 3, 'Uncommon': 2, 'Common': 1};
          filteredInventory.sort((a, b) =>
              (rarityWeights[b['rarity']] ?? 0).compareTo(rarityWeights[a['rarity']] ?? 0));
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
              // ── Tab 1: Collection Grid & Filter ───────────
              Column(
                children: [
                  // Filter header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: _selectedElement,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: ['All', 'Fire', 'Water', 'Wind', 'Electric', 'Nature'].map((el) {
                            return DropdownMenuItem(value: el, child: Text(el));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedElement = val!),
                        ),
                        DropdownButton<String>(
                          value: _sortBy,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: ['Rarity', 'Level', 'ATK'].map((sort) {
                            return DropdownMenuItem(value: sort, child: Text('Sort by $sort'));
                          }).toList(),
                          onChanged: (val) => setState(() => _sortBy = val!),
                        ),
                      ],
                    ),
                  ),

                  // Grid view
                  Expanded(
                    child: filteredInventory.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching cards in collection yet.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredInventory.length,
                            itemBuilder: (context, index) {
                              final monster = filteredInventory[index];
                              final isSelected = _activeDeck.contains(monster['id']);
                              final elementColor = _getElementColor(monster['element']);

                              return GestureDetector(
                                onTap: () => _toggleDeckCard(monster['id']),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.surfaceVariant,
                                        elementColor.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.secondary
                                          : elementColor.withValues(alpha: 0.3),
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.secondary.withValues(alpha: 0.25),
                                              blurRadius: 12,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Element glowing background orb
                                      Positioned(
                                        right: -20,
                                        bottom: -20,
                                        child: Icon(
                                          Icons.circle,
                                          size: 100,
                                          color: elementColor.withValues(alpha: 0.05),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Rarity & Level row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: elementColor.withValues(alpha: 0.18),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    monster['rarity'].toUpperCase(),
                                                    style: TextStyle(
                                                      color: elementColor,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'Lvl ${monster['level']}',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            // Icon
                                            Center(
                                              child: Icon(
                                                Icons.catching_pokemon_rounded,
                                                size: 48,
                                                color: elementColor,
                                              ),
                                            ),
                                            const Spacer(),
                                            // Name & Stats
                                            Text(
                                              monster['name'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                _buildStatLabel('HP', '${monster['hp']}'),
                                                _buildStatLabel('ATK', '${monster['atk']}'),
                                                _buildStatLabel('DEF', '${monster['def']}'),
                                              ],
                                            ),
                                          ],
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
              ),

              // ── Tab 2: Deck Builder Panel ─────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 6),
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
                  const SizedBox(height: 20),

                  // Loaded Deck Horizontal List
                  Expanded(
                    child: _activeDeck.isEmpty
                        ? const Center(
                            child: Text(
                              'Tap cards in collection to build your active deck.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _activeDeck.length,
                            itemBuilder: (context, index) {
                              final cardId = _activeDeck[index];
                              final monster = _allMonsters.firstWhere(
                                (m) => m['id'] == cardId,
                                orElse: () => _allMonsters.first,
                              );
                              final elementColor = _getElementColor(monster['element']);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: elementColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.catching_pokemon, color: elementColor, size: 28),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            monster['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                '${monster['element']}  •  ',
                                                style: TextStyle(
                                                  color: elementColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'ATK: ${monster['atk']}  HP: ${monster['hp']}',
                                                style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _toggleDeckCard(cardId),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.redAccent,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatLabel(String name, String val) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
