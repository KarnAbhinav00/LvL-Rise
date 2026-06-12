import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Predefined Monster models for reference
  final List<Map<String, dynamic>> _monsterModels = List.generate(50, (index) {
    final elements = ['Fire', 'Water', 'Wind', 'Electric', 'Nature'];
    final element = elements[index % 5];
    return {
      'id': 'mon_$index',
      'name': '$element Guardian #${index + 1}',
      'element': element,
    };
  });

  // Mock Active Marketplace listings for simulation if Firestore collection is empty
  final List<Map<String, dynamic>> _mockListings = [
    {
      'id': 'list_1',
      'sellerId': 'other_1',
      'sellerName': 'AstroFlex',
      'cardId': 'mon_12',
      'monsterName': 'Wind Guardian #13',
      'monsterElement': 'Wind',
      'price': 450,
    },
    {
      'id': 'list_2',
      'sellerId': 'other_2',
      'sellerName': 'FitBeast',
      'cardId': 'mon_24',
      'monsterName': 'Nature Guardian #25',
      'monsterElement': 'Nature',
      'price': 650,
    },
    {
      'id': 'list_3',
      'sellerId': 'other_3',
      'sellerName': 'ZenRunner',
      'cardId': 'mon_8',
      'monsterName': 'Water Guardian #9',
      'monsterElement': 'Water',
      'price': 300,
    },
  ];

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

  void _showSellDialog(List<String> ownedCardIds, String displayName) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedCardId = ownedCardIds.isNotEmpty ? ownedCardIds.first : null;
        final priceController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Sell Card',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Card to List:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedCardId,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceVariant,
                    style: const TextStyle(color: Colors.white),
                    items: ownedCardIds.map((id) {
                      final name = _monsterModels.firstWhere((m) => m['id'] == id)['name'];
                      return DropdownMenuItem(value: id, child: Text(name));
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCardId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Price (GOLD):', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter price (e.g. 200)',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Note: 10% marketplace transaction fee applies to listing prices.',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white30)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedCardId == null || priceController.text.isEmpty) return;
                    final price = int.tryParse(priceController.text);
                    if (price == null || price <= 0) return;

                    final monster = _monsterModels.firstWhere((m) => m['id'] == selectedCardId);

                    // Add to listings
                    await _firestore.listCardInMarket(
                      uid: _user!.uid,
                      sellerName: displayName,
                      cardId: selectedCardId!,
                      monsterName: monster['name'],
                      monsterElement: monster['element'],
                      price: price,
                    );

                    // Local mock update
                    setState(() {
                      _mockListings.add({
                        'id': 'list_${DateTime.now().millisecondsSinceEpoch}',
                        'sellerId': _user.uid,
                        'sellerName': displayName,
                        'cardId': selectedCardId!,
                        'monsterName': monster['name'],
                        'monsterElement': monster['element'],
                        'price': price,
                      });
                    });

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Card listed in marketplace successfully!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('List Card'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _buyCard(Map<String, dynamic> listing, int userGold) async {
    final price = listing['price'];

    if (userGold < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient GOLD. Complete quests or battles to earn more!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (listing['sellerId'] == _user!.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot buy your own listed card.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    try {
      await _firestore.buyCardFromMarket(
        buyerId: _user.uid,
        buyerName: 'Buyer',
        listingId: listing['id'],
        sellerId: listing['sellerId'],
        cardId: listing['cardId'],
        price: price,
      );

      // Local mock removal
      setState(() {
        _mockListings.removeWhere((l) => l['id'] == listing['id']);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bought ${listing['monsterName']}! Check collection tab.'),
          backgroundColor: const Color(0xFF50C878),
        ),
      );
    } catch (e) {
      // Offline simulation fallback: manually deduct balance & transfer card
      await _firestore.updateUserProfile(_user.uid, {
        'gold': FieldValue.increment(-price),
        'monsters': FieldValue.arrayUnion([listing['cardId']]),
      });

      setState(() {
        _mockListings.removeWhere((l) => l['id'] == listing['id']);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bought ${listing['monsterName']}! Check collection tab.'),
          backgroundColor: const Color(0xFF50C878),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.userProfileStream(_user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final userGold = userData?['gold'] ?? 1000;
        final displayName = userData?['displayName'] ?? 'Adventurer';
        final List<dynamic> rawMonsters = userData?['monsters'] ?? [];
        final List<String> ownedCardIds = rawMonsters.map((e) => e.toString()).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nexus Marketplace',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '$userGold GOLD',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showSellDialog(ownedCardIds, displayName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Sell Card', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.marketplaceStream(),
                    builder: (context, listSnapshot) {
                      List<Map<String, dynamic>> activeListings = [];
                      
                      if (listSnapshot.hasData && listSnapshot.data!.docs.isNotEmpty) {
                        activeListings = listSnapshot.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          d['id'] = doc.id;
                          return d;
                        }).toList();
                      } else {
                        activeListings = _mockListings;
                      }

                      return ListView.builder(
                        itemCount: activeListings.length,
                        itemBuilder: (context, index) {
                          final listing = activeListings[index];
                          final elementColor = _getElementColor(listing['monsterElement']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: elementColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: elementColor.withValues(alpha: 0.1),
                                  ),
                                  child: Icon(Icons.catching_pokemon, color: elementColor, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing['monsterName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Seller: ${listing['sellerName']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 15),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${listing['price']}',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => _buyCard(listing, userGold),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.surfaceVariant,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(80, 32),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Buy', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
