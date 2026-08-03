import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../data/achievement_model.dart';
import '../data/achievements_repository.dart';

final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  return AchievementsRepository(ref.watch(apiClientProvider));
});

final achievementsControllerProvider = AsyncNotifierProvider<AchievementsController, List<Achievement>>(
  AchievementsController.new,
);

class AchievementsController extends AsyncNotifier<List<Achievement>> {
  @override
  Future<List<Achievement>> build() {
    return ref.read(achievementsRepositoryProvider).fetchAchievements();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(achievementsRepositoryProvider).fetchAchievements(),
    );
  }
}
