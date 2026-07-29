import '../../../core/api/api_client.dart';
import 'review_model.dart';

class ReviewsRepository {
  ReviewsRepository(this._client);

  final ApiClient _client;

  Future<List<Review>> fetchForPin(String pinId) async {
    final response = await _client.dio.get('/pins/$pinId/reviews');
    return (response.data as List)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates or updates the current user's review for this pin (one review
  /// per user per pin — posting again edits the existing one).
  Future<Review> upsert(
    String pinId, {
    required int rating,
    String? comment,
    List<String> photoUrls = const [],
  }) async {
    final response = await _client.dio.post('/pins/$pinId/reviews', data: {
      'rating': rating,
      // ignore: use_null_aware_elements
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'photoUrls': photoUrls,
    });
    return Review.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteForPin(String pinId) {
    return _client.dio.delete('/pins/$pinId/reviews');
  }
}
