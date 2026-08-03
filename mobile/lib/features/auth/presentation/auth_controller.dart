import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/providers.dart';
import '../../../core/realtime/socket_service.dart';
import '../data/auth_repository.dart';
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

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final socialAuthServiceProvider = Provider<SocialAuthService>((ref) => SocialAuthService());

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
    ApiClient apiClient,
  ) : super(const AuthInitial()) {
    apiClient.onUnauthorized = _handleUnauthorized;
    _restoreSession();
  }

  final AuthRepository _repository;
  final SocketService _socketService;
  final SocialAuthService _socialAuthService;

  void _handleUnauthorized() {
    _socketService.disconnect();
    state = const AuthUnauthenticated();
  }

  Future<void> _restoreSession() async {
    state = const AuthLoading();
    final user = await _repository.fetchCurrentUser();
    if (user != null) {
      state = AuthAuthenticated(user);
      await _socketService.connect();
    } else {
      state = const AuthUnauthenticated();
    }
  }

  /// [identifier] may be either the account's email or its username.
  Future<void> login(String identifier, String password, {required String fallbackError}) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(identifier: identifier, password: password);
      state = AuthAuthenticated(user);
      await _socketService.connect();
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
    } catch (e) {
      state = AuthUnauthenticated(error: _authErrorMessage(e, fallbackError));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _socketService.disconnect();
    state = const AuthUnauthenticated();
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
    ref.watch(apiClientProvider),
  );
});
