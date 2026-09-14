import 'package:firebase_auth/firebase_auth.dart';
import 'social_auth_service.dart';

/// Wraps Firebase Auth's own credential verification (password checking,
/// Google OAuth) — Firebase itself confirms the user's identity here; the
/// resulting ID token is then handed to our backend (POST /auth/firebase)
/// purely to exchange it for our existing session JWT, never to re-verify
/// the credential a second time.
class FirebaseAuthService {
  final _auth = FirebaseAuth.instance;
  final _socialAuthService = SocialAuthService();

  Future<String> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final idToken = await credential.user!.getIdToken();
    return idToken!;
  }

  /// Creates the account in Firebase itself (Firebase enforces password
  /// rules and email uniqueness here), then updates the Firebase profile's
  /// displayName so the backend's find-or-create picks it up as this
  /// account's display_name on first exchange.
  Future<String> registerWithEmail(String email, String password, String displayName) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user!.updateDisplayName(displayName);
    await credential.user!.reload();
    final idToken = await _auth.currentUser!.getIdToken();
    return idToken!;
  }

  /// Returns null if the user cancelled the Google picker.
  Future<String?> signInWithGoogle() async {
    final googleIdToken = await _socialAuthService.signInWithGoogle();
    if (googleIdToken == null) return null;
    final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
    final userCredential = await _auth.signInWithCredential(credential);
    final idToken = await userCredential.user!.getIdToken();
    return idToken!;
  }
}
