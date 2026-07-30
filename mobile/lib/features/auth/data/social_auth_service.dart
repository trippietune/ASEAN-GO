import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around the Google/Facebook SDKs' native sign-in flows —
/// isolates the platform-plugin API surface from [AuthController], which
/// only needs the resulting token to hand to our backend for verification.
///
/// Configuration: Google needs `GOOGLE_IOS_CLIENT_ID`/`GOOGLE_WEB_CLIENT_ID`
/// (via --dart-define) on iOS/web; Android reads its client config from
/// `android/app/google-services.json` instead, so no runtime id is needed
/// there. Facebook needs `android/app/src/main/res/values/strings.xml`
/// (facebook_app_id, fb_login_protocol_scheme) and the iOS Info.plist
/// entries — see the package README. None of this is configured yet; see
/// the setup notes left for the human operator.
class SocialAuthService {
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID').isEmpty
          ? null
          : const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      serverClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID').isEmpty
          ? null
          : const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    );
    _googleInitialized = true;
  }

  /// Runs the interactive Google sign-in flow and returns the ID token our
  /// backend needs to verify, or null if the user cancelled.
  Future<String?> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// Runs the interactive Facebook login flow and returns the classic
  /// (Graph-API-usable) access token our backend needs to verify, or null if
  /// the user cancelled or declined required permissions.
  Future<String?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      // 'enabled' (not the default 'limited') is what actually yields a
      // ClassicToken with a Graph-API-usable access token — 'limited' only
      // gives a LimitedToken meant for on-device use, which our backend's
      // Graph API verification call can't use.
      loginTracking: LoginTracking.enabled,
      permissions: const ['email', 'public_profile'],
    );
    switch (result.status) {
      case LoginStatus.success:
        final token = result.accessToken;
        if (token is ClassicToken) return token.tokenString;
        // Shouldn't happen given loginTracking: classic, but fail closed
        // rather than send a token our backend can't use.
        if (kDebugMode) {
          debugPrint('Facebook login returned a non-classic token unexpectedly: ${token.runtimeType}');
        }
        return null;
      case LoginStatus.cancelled:
        return null;
      case LoginStatus.failed:
        throw Exception(result.message ?? 'Facebook sign-in failed');
      case LoginStatus.operationInProgress:
        return null;
    }
  }
}
