import 'package:cloud_firestore/cloud_firestore.dart';

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
}
