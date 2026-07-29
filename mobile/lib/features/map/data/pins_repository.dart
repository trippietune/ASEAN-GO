import '../../../core/api/api_client.dart';
import 'pin_model.dart';

class PinsRepository {
  PinsRepository(this._client);

  final ApiClient _client;

  Future<List<VerifiedPin>> fetchNearby({
    required double lat,
    required double lng,
    double radiusMeters = 2000,
  }) async {
    final response = await _client.dio.get('/pins/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radiusMeters': radiusMeters,
    });
    return (response.data as List)
        .map((e) => VerifiedPin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Throws a [DioException] with status 409 if this pin was already checked
  /// into today.
  Future<CheckInResult> checkIn(String pinId) async {
    final response = await _client.dio.post('/pins/$pinId/checkin');
    return CheckInResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VerifiedPin> fetchById(String pinId) async {
    final response = await _client.dio.get('/pins/$pinId');
    return VerifiedPin.fromJson(response.data as Map<String, dynamic>);
  }

  /// Submits a new pin candidate — starts unverified pending admin review
  /// (see backend POST /pins).
  Future<VerifiedPin> createPin({
    required String name,
    required String category,
    required String country,
    required double lat,
    required double lng,
    String? description,
    String? city,
    List<String> photoUrls = const [],
  }) async {
    final response = await _client.dio.post('/pins', data: {
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
    return VerifiedPin.fromJson(response.data as Map<String, dynamic>);
  }
}

class CheckInResult {
  const CheckInResult({required this.xpAwarded, required this.xp, required this.level});

  final int xpAwarded;
  final int xp;
  final int level;

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      xpAwarded: json['xpAwarded'] as int,
      xp: json['xp'] as int,
      level: json['level'] as int,
    );
  }
}
