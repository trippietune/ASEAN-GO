import '../../../core/api/api_client.dart';
import 'achievement_model.dart';

class AchievementsRepository {
  AchievementsRepository(this._client);

  final ApiClient _client;

  Future<List<Achievement>> fetchAchievements() async {
    final response = await _client.dio.get('/users/me/achievements');
    return (response.data as List)
        .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
