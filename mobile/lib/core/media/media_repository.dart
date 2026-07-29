import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/providers.dart';

enum MediaPurpose {
  reviewPhoto('review_photo'),
  pinPhoto('pin_photo'),
  riskReportPhoto('risk_report_photo');

  const MediaPurpose(this.apiValue);
  final String apiValue;
}

class UploadedMedia {
  const UploadedMedia({required this.id, required this.url});

  final String id;
  final String url;

  factory UploadedMedia.fromJson(Map<String, dynamic> json) {
    return UploadedMedia(id: json['id'] as String, url: json['url'] as String);
  }
}

/// Shared upload/delete client used by every "attach a photo" flow (review,
/// pin, risk report). Profile avatar is separate — see AuthRepository /
/// `POST /users/me/avatar` — since it always replaces a single image rather
/// than accumulating a list.
class MediaRepository {
  MediaRepository(this._client);

  final ApiClient _client;

  Future<UploadedMedia> upload(String filePath, MediaPurpose purpose) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final response = await _client.dio.post(
      '/media/upload',
      queryParameters: {'purpose': purpose.apiValue},
      data: formData,
    );
    return UploadedMedia.fromJson(response.data as Map<String, dynamic>);
  }

  /// Best-effort: lets the caller discard a photo it just uploaded but
  /// decided not to use before submitting. Failures are swallowed — an
  /// orphaned Cloudinary asset is a minor cleanup issue, not something that
  /// should block or confuse the user mid-flow.
  Future<void> delete(String url) async {
    try {
      await _client.dio.post('/media/delete', data: {'url': url});
    } catch (_) {
      // best-effort
    }
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(apiClientProvider));
});
