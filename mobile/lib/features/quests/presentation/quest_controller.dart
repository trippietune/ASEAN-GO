import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../data/quest_model.dart';
import '../data/quests_repository.dart';

final questsRepositoryProvider = Provider<QuestsRepository>((ref) {
  return QuestsRepository(ref.watch(apiClientProvider));
});

class QuestsState {
  const QuestsState({required this.quests, this.error});

  final List<Quest> quests;
  final String? error;

  int get completedCount => quests.where((q) => q.isCompleted).length;
  int get totalCount => quests.length;
}

class QuestsController extends AsyncNotifier<QuestsState> {
  @override
  Future<QuestsState> build() async {
    final quests = await ref.read(questsRepositoryProvider).fetchDailyQuests();
    return QuestsState(quests: quests);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final quests = await ref.read(questsRepositoryProvider).fetchDailyQuests();
      return QuestsState(quests: quests);
    });
  }

  /// Returns the server's authoritative completion result (including final
  /// xp/level/coinBalance — never recomputed on the client) so the caller
  /// can show a snackbar, or null if the quest was already completed / the
  /// request failed.
  Future<QuestCompletionResult?> completeQuest(Quest quest) async {
    final current = state.valueOrNull;
    if (current == null) return null;

    try {
      final result = await ref.read(questsRepositoryProvider).completeQuest(
            quest.id,
            pinId: quest.pinId,
          );

      final updatedQuests = [
        for (final q in current.quests)
          if (q.id == quest.id) q.copyWith(status: QuestStatus.completed) else q,
      ];
      state = AsyncData(QuestsState(quests: updatedQuests));

      return result.alreadyCompleted ? null : result;
    } catch (_) {
      return null;
    }
  }
}

final questsControllerProvider = AsyncNotifierProvider<QuestsController, QuestsState>(
  QuestsController.new,
);
