import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/providers.dart';
import 'fcm_token_repository.dart';

final fcmTokenRepositoryProvider = Provider<FcmTokenRepository>((ref) {
  return FcmTokenRepository(ref.watch(apiClientProvider));
});
