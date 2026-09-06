import 'dart:io' show Platform;
import '../api/api_client.dart';

/// Registers/unregisters this device's FCM token with the backend, so
/// `sendPushToUser` (server-side) knows where to deliver a push for a given
/// user. Mirrors [SettingsRepository]'s shape — a plain class wrapping
/// [ApiClient] calls, parsing nothing beyond a success flag here.
class FcmTokenRepository {
  FcmTokenRepository(this._client);

  final ApiClient _client;

  Future<void> registerToken(String token) => _client.dio.post(
        '/users/me/fcm-token',
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );

  Future<void> unregisterToken(String token) => _client.dio.delete(
        '/users/me/fcm-token',
        data: {'token': token},
      );
}
