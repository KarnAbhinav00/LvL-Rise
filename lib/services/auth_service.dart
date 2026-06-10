import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestore = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Google Sign-In ───────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    await _syncUserToFirestore(result.user, 'google');
    return result;
  }

  // ── Email Sign-In ────────────────────────────────────
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _syncUserToFirestore(result.user, 'email');
    return result;
  }

  // ── Email Sign-Up ────────────────────────────────────
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _syncUserToFirestore(result.user, 'email');
    return result;
  }

  // ── Password Reset ───────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Sign Out ─────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // ── Firestore Sync ───────────────────────────────────
  Future<void> _syncUserToFirestore(User? user, String provider) async {
    if (user == null) return;
    try {
      await _firestore.upsertUserProfile(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
        authProvider: provider,
      );
    } catch (_) {
      // Don't break auth flow if Firestore sync fails
    }
  }
}
