import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scholai_app/core/utils/app_logger.dart';

/// Firebase Authentication for ScholAI.
///
/// Default: anonymous UID (no email/name required).
/// Optional: link Google to keep the same UID across devices.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Web OAuth client from `google-services.json` (client_type 3) —
  /// required so Android returns an `idToken` for Firebase.
  static const _webClientId =
      '249484548606-clu179dhq7lhuunr9lov4mn18mri93l9.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: _webClientId,
  );

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  bool get isSignedIn => _auth.currentUser != null;

  /// True when this Firebase user has a Google provider linked.
  bool get isGoogleLinked {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  /// Non-PII display hint for settings (email only if Google-linked).
  String? get linkedEmail {
    final user = _auth.currentUser;
    if (user == null) return null;
    for (final p in user.providerData) {
      if (p.providerId == 'google.com' && (p.email?.isNotEmpty ?? false)) {
        return p.email;
      }
    }
    return user.email;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in anonymously. Safe to call multiple times —
  /// if a session already exists it does nothing.
  Future<void> signInAnonymously() async {
    if (isSignedIn) return;
    await _auth.signInAnonymously();
  }

  /// Optionally link Google to the current anonymous session so the same
  /// Firebase UID (and `/users/{uid}` data) can be restored on other devices.
  ///
  /// If this Google account is already tied to another Firebase user
  /// (e.g. signing in on a second phone), switches to that existing account.
  Future<GoogleLinkResult> linkOrSignInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return GoogleLinkResult.cancelled;
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final user = _auth.currentUser;
    try {
      if (user != null &&
          user.isAnonymous &&
          !user.providerData.any((p) => p.providerId == 'google.com')) {
        await user.linkWithCredential(credential);
        AppLogger.info('Anonymous session linked to Google (UID preserved).');
        return GoogleLinkResult.linked;
      }

      await _auth.signInWithCredential(credential);
      AppLogger.info('Signed in with Google.');
      return GoogleLinkResult.signedIn;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        // Another Firebase user already owns this Google account — use it.
        await _auth.signInWithCredential(credential);
        AppLogger.info('Switched to existing Google-linked account.');
        return GoogleLinkResult.signedInExisting;
      }
      if (e.code == 'provider-already-linked') {
        return GoogleLinkResult.alreadyLinked;
      }
      AppLogger.warning('Google sign-in failed: ${e.code}', error: e);
      rethrow;
    }
  }

  /// Signs out of Google + Firebase, then starts a fresh anonymous session
  /// so the app keeps working offline-first without a hard auth hole.
  Future<void> signOutToAnonymous() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    await signInAnonymously();
    AppLogger.info('Signed out of Google; restored anonymous session.');
  }
}

enum GoogleLinkResult {
  cancelled,
  linked,
  signedIn,
  signedInExisting,
  alreadyLinked,
}
