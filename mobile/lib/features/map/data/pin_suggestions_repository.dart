import '../../../core/api/api_client.dart';
import 'pin_suggestion_model.dart';

/// Ordinary users no longer create pins directly (POST /pins is admin-only)
/// — this submits a suggestion for an admin to review instead. Kept separate
/// from PinsRepository since that class is about the verified-pins-on-the-map
/// surface, not pending suggestions.
class PinSuggestionsRepository {
  PinSuggestionsRepository(this._client);

  final ApiClient _client;

  Future<PinSuggestion> submitSuggestion({
    required String name,
    required String category,
    required String country,
    required double lat,
    required double lng,
    String? description,
    String? city,
    List<String> photoUrls = const [],
  }) async {
    final response = await _client.dio.post('/pin-suggestions', data: {
      'name': name,
      'category': category,
      'country': country,
      'lat': lat,
      'lng': lng,
      // ignore: use_null_aware_elements
      if (description != null && description.isNotEmpty) 'description': description,
      // ignore: use_null_aware_elements
      if (city != null && city.isNotEmpty) 'city': city,
      'photoUrls': photoUrls,
    });
    return PinSuggestion.fromJson(response.data as Map<String, dynamic>);
  }
}
