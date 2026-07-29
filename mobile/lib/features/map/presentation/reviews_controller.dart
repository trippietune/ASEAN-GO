import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../data/review_model.dart';
import '../data/reviews_repository.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(apiClientProvider));
});

/// Reviews for a single pin, keyed by pin ID so switching between pin detail
/// screens doesn't share stale state.
class ReviewsController extends FamilyAsyncNotifier<List<Review>, String> {
  @override
  Future<List<Review>> build(String pinId) {
    return ref.read(reviewsRepositoryProvider).fetchForPin(pinId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(reviewsRepositoryProvider).fetchForPin(arg));
  }

  /// Returns null on success, or an error message for the caller to show.
  Future<String?> submitReview({
    required int rating,
    String? comment,
    List<String> photoUrls = const [],
  }) async {
    try {
      final review = await ref.read(reviewsRepositoryProvider).upsert(
            arg,
            rating: rating,
            comment: comment,
            photoUrls: photoUrls,
          );

      final current = state.valueOrNull ?? [];
      final withoutMine = current.where((r) => r.userId != review.userId).toList();
      state = AsyncData([review, ...withoutMine]);
      return null;
    } catch (_) {
      return 'ส่งรีวิวไม่สำเร็จ ลองใหม่อีกทีนะ';
    }
  }

  Future<String?> deleteMyReview() async {
    try {
      await ref.read(reviewsRepositoryProvider).deleteForPin(arg);
      await refresh();
      return null;
    } catch (_) {
      return 'ลบรีวิวไม่สำเร็จ ลองใหม่อีกทีนะ';
    }
  }
}

final reviewsControllerProvider =
    AsyncNotifierProviderFamily<ReviewsController, List<Review>, String>(
  ReviewsController.new,
);
