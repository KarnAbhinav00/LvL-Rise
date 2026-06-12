import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the users collection reference
  CollectionReference get _users => _db.collection('users');

  /// Creates or updates a user profile document in Firestore.
  /// Called after every successful sign-in/sign-up to keep profile in sync.
  Future<void> upsertUserProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? authProvider,
  }) async {
    final docRef = _users.doc(uid);
    final existing = await docRef.get();

    if (existing.exists) {
      // Update last login + any changed fields
      final updates = <String, dynamic>{
        'lastLoginAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null && displayName.isNotEmpty) {
        updates['displayName'] = displayName;
      }
      if (email != null) updates['email'] = email;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (authProvider != null) updates['lastAuthProvider'] = authProvider;
      await docRef.update(updates);
    } else {
      // Create brand new user profile
      await docRef.set({
        'uid': uid,
        'displayName': displayName ?? 'Adventurer',
        'email': email ?? '',
        'photoUrl': photoUrl ?? '',
        'authProvider': authProvider ?? 'email',
        'lastAuthProvider': authProvider ?? 'email',
        // RPG fields — start at level 1
        'level': 1,
        'xp': 0,
        'totalXp': 0,
        'strength': 10,
        'endurance': 10,
        'discipline': 10,
        'questsCompleted': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Fetches a user profile document
  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _users.doc(uid).get();
  }

  /// Stream of user profile data for real-time updates
  Stream<DocumentSnapshot> userProfileStream(String uid) {
    return _users.doc(uid).snapshots();
  }

  /// Updates specific fields on the user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  /// Deletes a user profile
  Future<void> deleteUserProfile(String uid) async {
    await _users.doc(uid).delete();
  }

  // ── Activity Logging ─────────────────────────────────
  Future<void> saveWorkout({
    required String uid,
    required String type,
    required double metricValue, // distance for runs, sets for lifting
    required int durationMinutes,
    required int xpEarned,
    required int goldEarned,
  }) async {
    try {
      final batch = _db.batch();
      final userRef = _users.doc(uid);
      final workoutRef = userRef.collection('workouts').doc();

      batch.set(workoutRef, {
        'type': type,
        'metricValue': metricValue,
        'durationMinutes': durationMinutes,
        'xpEarned': xpEarned,
        'goldEarned': goldEarned,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(userRef, {
        'xp': FieldValue.increment(xpEarned),
        'totalXp': FieldValue.increment(xpEarned),
        'gold': FieldValue.increment(goldEarned),
      });

      await batch.commit();
    } catch (e) {
      // Offline fallback: handled by local UI state if Firebase fails
      debugPrint('Firestore saveWorkout error: $e');
    }
  }

  // ── Quests & Achievements ─────────────────────────────
  Future<void> completeQuest({
    required String uid,
    required String questId,
    required int xpEarned,
    required int goldEarned,
  }) async {
    try {
      final userRef = _users.doc(uid);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final questsCompleted = (data['questsCompleted'] ?? 0) + 1;
        final currentXp = (data['xp'] ?? 0) + xpEarned;
        final currentGold = (data['gold'] ?? 0) + goldEarned;

        // Level up check
        int currentLevel = data['level'] ?? 1;
        int nextLevelThreshold = currentLevel * 1000;
        int newXp = currentXp;
        int newLevel = currentLevel;
        if (newXp >= nextLevelThreshold) {
          newXp -= nextLevelThreshold;
          newLevel += 1;
        }

        transaction.update(userRef, {
          'questsCompleted': questsCompleted,
          'xp': newXp,
          'totalXp': FieldValue.increment(xpEarned),
          'gold': currentGold,
          'level': newLevel,
        });
      });
    } catch (e) {
      debugPrint('Firestore completeQuest error: $e');
    }
  }

  // ── Monsters Collection & Deck Builder ─────────────────
  Future<void> addMonsterToCollection(String uid, String monsterId) async {
    try {
      final userRef = _users.doc(uid);
      await userRef.update({
        'monsters': FieldValue.arrayUnion([monsterId]),
      });
    } catch (e) {
      debugPrint('Firestore addMonsterToCollection error: $e');
    }
  }

  Future<void> updateActiveDeck(String uid, List<String> deckCardIds) async {
    try {
      final userRef = _users.doc(uid);
      await userRef.update({
        'activeDeck': deckCardIds,
      });
    } catch (e) {
      debugPrint('Firestore updateActiveDeck error: $e');
    }
  }

  // ── Battle Arena ──────────────────────────────────────
  Future<void> recordBattleResult(String uid, bool isWin, int goldEarned) async {
    try {
      final userRef = _users.doc(uid);
      await userRef.update({
        'battlesWon': FieldValue.increment(isWin ? 1 : 0),
        'battlesPlayed': FieldValue.increment(1),
        'gold': FieldValue.increment(goldEarned),
      });
    } catch (e) {
      debugPrint('Firestore recordBattleResult error: $e');
    }
  }

  // ── Global Leaderboardingsings ──────────────────────────
  Future<List<Map<String, dynamic>>> getLeaderboard(String orderByField) async {
    try {
      final snapshot = await _users
          .orderBy(orderByField, descending: true)
          .limit(10)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Firestore getLeaderboard error: $e');
      return [];
    }
  }

  // ── Friends & Social ───────────────────────────────────
  Stream<DocumentSnapshot> friendsStream(String uid) {
    return _users.doc(uid).snapshots();
  }

  Future<void> addFriendByEmail(String uid, String email) async {
    try {
      final query = await _users.where('email', isEqualTo: email.trim().toLowerCase()).get();
      if (query.docs.isEmpty) throw Exception('No user found with that email.');

      final friendDoc = query.docs.first;
      final friendId = friendDoc.id;

      if (uid == friendId) throw Exception('You cannot add yourself.');

      final batch = _db.batch();
      batch.update(_users.doc(uid), {
        'friends': FieldValue.arrayUnion([friendId])
      });
      batch.update(_users.doc(friendId), {
        'friends': FieldValue.arrayUnion([uid])
      });
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore addFriendByEmail error: $e');
      rethrow;
    }
  }

  // ── Marketplace ────────────────────────────────────────
  Stream<QuerySnapshot> marketplaceStream() {
    return _db.collection('marketplace').snapshots();
  }

  Future<void> listCardInMarket({
    required String uid,
    required String sellerName,
    required String cardId,
    required String monsterName,
    required String monsterElement,
    required int price,
  }) async {
    try {
      await _db.collection('marketplace').add({
        'sellerId': uid,
        'sellerName': sellerName,
        'cardId': cardId,
        'monsterName': monsterName,
        'monsterElement': monsterElement,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore listCardInMarket error: $e');
    }
  }

  Future<void> buyCardFromMarket({
    required String buyerId,
    required String buyerName,
    required String listingId,
    required String sellerId,
    required String cardId,
    required int price,
  }) async {
    try {
      final buyerRef = _users.doc(buyerId);
      final sellerRef = _users.doc(sellerId);
      final listingRef = _db.collection('marketplace').doc(listingId);

      await _db.runTransaction((transaction) async {
        final buyerSnap = await transaction.get(buyerRef);
        final sellerSnap = await transaction.get(sellerRef);

        if (!buyerSnap.exists || !sellerSnap.exists) return;

        final buyerData = buyerSnap.data() as Map<String, dynamic>;
        final buyerGold = buyerData['gold'] ?? 0;

        if (buyerGold < price) throw Exception('Insufficient GOLD.');

        // Update buyer balance and cards
        transaction.update(buyerRef, {
          'gold': buyerGold - price,
          'monsters': FieldValue.arrayUnion([cardId]),
        });

        // Update seller balance and remove card
        final sellerData = sellerSnap.data() as Map<String, dynamic>;
        final sellerGold = sellerData['gold'] ?? 0;
        final tax = (price * 0.10).round(); // 10% marketplace tax fee
        final proceeds = price - tax;

        transaction.update(sellerRef, {
          'gold': sellerGold + proceeds,
          'monsters': FieldValue.arrayRemove([cardId]),
        });

        // Delete the listing
        transaction.delete(listingRef);
      });
    } catch (e) {
      debugPrint('Firestore buyCardFromMarket error: $e');
      rethrow;
    }
  }
}
