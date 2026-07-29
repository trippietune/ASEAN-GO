import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import 'user_model.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    await _client.saveToken(response.data['token'] as String);
    return AppUser.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> login({required String email, required String password}) async {
    final response = await _client.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _client.saveToken(response.data['token'] as String);
    return AppUser.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<AppUser?> fetchCurrentUser() async {
    final token = await _client.readToken();
    if (token == null) return null;
    try {
      final response = await _client.dio.get('/users/me');
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _client.clearToken();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() => _client.clearToken();

  Future<AppUser> updateProfile({String? displayName, String? avatarUrl}) async {
    final response = await _client.dio.put('/users/me', data: {
      // ignore: use_null_aware_elements
      if (displayName != null) 'displayName': displayName,
      // ignore: use_null_aware_elements
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }

  /// Uploads a new avatar image (replaces any existing one — see backend
  /// `POST /users/me/avatar`, which also deletes the previous Cloudinary
  /// asset once the new one is saved).
  Future<AppUser> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final response = await _client.dio.post('/users/me/avatar', data: formData);
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) {
    return _client.dio.put('/users/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
