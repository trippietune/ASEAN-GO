import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/providers.dart';
import '../../../core/realtime/socket_service.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

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
  AuthController(this._repository, this._socketService, ApiClient apiClient) : super(const AuthInitial()) {
    apiClient.onUnauthorized = _handleUnauthorized;
    _restoreSession();
  }

  final AuthRepository _repository;
  final SocketService _socketService;

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

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthAuthenticated(user);
      await _socketService.connect();
    } catch (_) {
      state = const AuthUnauthenticated(error: 'Invalid email or password');
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    state = const AuthLoading();
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AuthAuthenticated(user);
      await _socketService.connect();
    } catch (_) {
      state = const AuthUnauthenticated(error: 'Could not create account. Try a different email.');
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
    ref.watch(apiClientProvider),
  );
});
