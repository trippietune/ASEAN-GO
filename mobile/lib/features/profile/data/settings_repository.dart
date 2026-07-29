import '../../../core/api/api_client.dart';
import 'settings_model.dart';

class SettingsRepository {
  SettingsRepository(this._client);

  final ApiClient _client;

  Future<NotificationSettings> fetchNotificationSettings() async {
    final response = await _client.dio.get('/users/me/notification-settings');
    return NotificationSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NotificationSettings> updateNotificationSettings(NotificationSettings settings) async {
    final response = await _client.dio.put('/users/me/notification-settings', data: settings.toJson());
    return NotificationSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PrivacySettings> fetchPrivacySettings() async {
    final response = await _client.dio.get('/users/me/privacy-settings');
    return PrivacySettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PrivacySettings> updatePrivacySettings(PrivacySettings settings) async {
    final response = await _client.dio.put('/users/me/privacy-settings', data: settings.toJson());
    return PrivacySettings.fromJson(response.data as Map<String, dynamic>);
  }
}
