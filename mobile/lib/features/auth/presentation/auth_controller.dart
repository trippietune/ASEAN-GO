import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/providers.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../core/notifications/fcm_token_repository.dart';
import '../../../core/notifications/fcm_token_repository_provider.dart';
import '../../../core/realtime/socket_service.dart';
import '../data/auth_repository.dart';
import '../data/firebase_auth_service.dart';
import '../data/social_auth_service.dart';
import '../data/user_model.dart';

/// Pulls the backend's `{ error: "..." }` message out of a failed auth call,
/// falling back to [fallback] for network errors or unexpected shapes — auth
/// endpoints return specific, user-facing messages (e.g. "Invalid email or
/// password") that are more useful here than a generic string.
String _authErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
  }
  return fallback;
}

/// Maps Firebase's stable error codes to readable messages; falls back to
/// [_authErrorMessage] for the backend-side exchange call, or [fallback].
String _firebaseErrorMessage(Object error, String fallback) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'invalid-email':
        return 'That email address looks invalid';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'weak-password':
        return 'Password is too weak — please choose a stronger one';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
    }
  }
  return _authErrorMessage(error, fallback);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final socialAuthServiceProvider = Provider<SocialAuthService>((ref) => SocialAuthService());

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) => FirebaseAuthService());

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AppUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.error});
  final String? error;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(
    this._repository,
    this._socketService,
    this._socialAuthService,
    this._firebaseAuthService,
    this._fcmService,
    this._fcmTokenRepository,
    ApiClient apiClient,
  ) : super(const AuthInitial()) {
    apiClient.onUnauthorized = _handleUnauthorized;
    _restoreSession();
  }

  final AuthRepository _repository;
  final SocketService _socketService;
  final SocialAuthService _socialAuthService;
  final FirebaseAuthService _firebaseAuthService;
  final FcmService _fcmService;
  final FcmTokenRepository _fcmTokenRepository;

  void _handleUnauthorized() {
    _socketService.disconnect();
    state = const AuthUnauthenticated();
  }

  /// Requests notification permission and, if granted, sends this device's
  /// FCM token to the backend. Called right after auth succeeds (not at app
  /// cold-start) so the iOS system permission prompt has some context —
  /// asking before the user has even logged in tends to get reflexively
  /// denied. Silently does nothing on failure (e.g. FCM unset up in dev, or
  /// the user denies permission) — push registration is best-effort and
  /// must never block a successful login.
  Future<void> _registerPushToken() async {
    try {
      final granted = await _fcmService.requestPermission();
      if (!granted) return;
      final token = await _fcmService.getToken();
      if (token != null) {
        await _fcmTokenRepository.registerToken(token);
      }
    } catch (_) {
      // Best-effort — push registration failing must never block login.
    }
  }

  Future<void> _restoreSession() async {
    state = const AuthLoading();
    try {
      final user = await _repository.fetchCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
        await _socketService.connect();
        await _registerPushToken();
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      // Any unexpected failure here (network error, unhandled status code)
      // must still resolve to an interactive screen — never leave the app
      // stuck on the splash screen with no way for the user to proceed.
      state = const AuthUnauthenticated();
    }
  }

  /// Signs in via Firebase Authentication (Firebase itself checks the
  /// password), then exchanges the resulting ID token for our own session
  /// JWT so every existing req.userId-based route keeps working unchanged.
  Future<void> loginWithFirebaseEmail(String email, String password, {required String fallbackError}) async {
    state = const AuthLoading();
    try {
      final idToken = await _firebaseAuthService.signInWithEmail(email, password);
      final user = await _repository.loginWithFirebaseToken(idToken);
      state = AuthAuthenticated(user);
      await _socketService.connect();
      await _registerPushToken();
    } catch (e) {
      state = AuthUnauthenticated(error: _firebaseErrorMessage(e, fallbackError));
    }
  }

  /// Creates the account in Firebase itself, then exchanges the resulting ID
  /// token for our own session — mirrors [loginWithFirebaseEmail].
  Future<void> registerWithFirebase(
    String email,
    String password,
    String displayName, {
    required String fallbackError,
  }) async {
    state = const AuthLoading();
    try {
      final idToken = await _firebaseAuthService.registerWithEmail(email, password, displayName);
      final user = await _repository.loginWithFirebaseToken(idToken);
      state = AuthAuthenticated(user);
      await _socketService.connect();
      await _registerPushToken();
    } catch (e) {
      state = AuthUnauthenticated(error: _firebaseErrorMessage(e, fallbackError));
    }
  }

  /// [identifier] may be either the account's email or its username.
  Future<void> login(String identifier, String password, {required String fallbackError}) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(identifier: identifier, password: password);
      state = AuthAuthenticated(user);
      await _socketService.connect();
      await _registerPushToken();
    } catch (e) {
      state = AuthUnauthenticated(error: _authErrorMessage(e, fallbackError));
    }
  }

  Future<void> register(
    String email,
    String password,
    String displayName,
    String username, {
    required String fallbackError,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
        username: username,
      );
      state = AuthAuthenticated(user);
      await _socketService.connect();
      await _registerPushToken();
    } catch (e) {
      state = AuthUnauthenticated(error: _authErrorMessage(e, fallbackError));
    }
  }

  /// Runs the native Google sign-in flow, then exchanges the resulting ID
  /// token for our session. Leaves state untouched (no error shown) if the
  /// user simply cancels the picker — that's not a failure worth surfacing.
  Future<void> loginWithGoogle({required String fallbackError}) async {
    state = const AuthLoading();
    try {
      final idToken = await _socialAuthService.signInWithGoogle();
      if (idToken == null) {
        state = const AuthUnauthenticated();
        return;
      }
      final user = await _repository.loginWithGoogle(idToken: idToken);
      state = AuthAuthenticated(user);
      await _socketService.connect();
      await _registerPushToken();
    } catch (e) {
      state = AuthUnauthenticated(error: _authErrorMessage(e, fallbackError));
    }
  }

  /// Runs the native Facebook login flow, then exchanges the resulting
  /// access token for our session. Leaves state untouched (no error shown)
  /// if the user simply cancels — that's not a failure worth surfacing.
  Future<void> loginWithFacebook({required String fallbackError}) async {
    state = const AuthLoading();
    try {
      final accessToken = await _socialAuthService.signInWithFacebook();
      if (accessToken == null) {
        state = const AuthUnauthenticated();
        return;
      }
      final user = await _repository.loginWithFacebook(accessToken: accessToken);
      state = AuthAuthenticated(user);
      await _socketService.connect();
      await _registerPushToken();
    } catch (e) {
      state = AuthUnauthenticated(error: _authErrorMessage(e, fallbackError));
    }
  }

  Future<void> logout() async {
    // Captured before clearing the session so a stale token doesn't linger
    // in user_fcm_tokens after this device signs out — otherwise, on a
    // shared/reset device, whoever logs in next wouldn't overwrite it until
    // their own token registration happens to fire, during which pushes for
    // this account would still land on it.
    final token = await _fcmService.getToken();

    await _repository.logout();
    _socketService.disconnect();
    state = const AuthUnauthenticated();

    if (token != null) {
      try {
        await _fcmTokenRepository.unregisterToken(token);
      } catch (_) {
        // Best-effort — must never block local sign-out from completing.
      }
    }
  }

  /// Replaces the whole cached user (e.g. after an avatar upload returns the
  /// updated profile) without a separate refetch round trip.
  void applyUser(AppUser user) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(user);
    }
  }

  /// Applies an XP/level/coin update locally after a check-in or quest
  /// completion, without a full profile refetch.
  void applyXpGain({required int xp, required int level, int? coinBalance}) {
    final current = state;
    if (current is AuthAuthenticated) {
      state = AuthAuthenticated(
        current.user.copyWith(xp: xp, level: level, coinBalance: coinBalance),
      );
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(socketServiceProvider),
    ref.watch(socialAuthServiceProvider),
    ref.watch(firebaseAuthServiceProvider),
    ref.watch(fcmServiceProvider),
    ref.watch(fcmTokenRepositoryProvider),
    ref.watch(apiClientProvider),
  );
});
