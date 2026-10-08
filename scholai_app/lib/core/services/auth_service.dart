import 'package:firebase_auth/firebase_auth.dart';

/// Handles anonymous Firebase Authentication.
/// No email, no phone, no name — ever.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  bool get isSignedIn => _auth.currentUser != null;

  /// Signs in anonymously. Safe to call multiple times —
  /// if a session already exists it does nothing.
  Future<void> signInAnonymously() async {
    if (isSignedIn) return;
    await _auth.signInAnonymously();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
