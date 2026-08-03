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

  /// Grouped by questType, preserving each type's original relative order
  /// (server already orders by created_at, chapters by chapter_order).
  Map<String, List<Quest>> get byType {
    final result = <String, List<Quest>>{};
    for (final quest in quests) {
      (result[quest.questType] ??= []).add(quest);
    }
    return result;
  }

  /// A "3 of 20" stat where 15 are locked is worse UX than "3 of 5
  /// unlocked" — counts exclude quests the user can't act on yet.
  List<Quest> get _unlocked => quests.where((q) => !q.locked).toList();
  int get completedCount => _unlocked.where((q) => q.isCompleted).length;
  int get totalCount => _unlocked.length;
}

class QuestsController extends AsyncNotifier<QuestsState> {
  @override
  Future<QuestsState> build() async {
    final quests = await ref.read(questsRepositoryProvider).fetchQuests();
    return QuestsState(quests: quests);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final quests = await ref.read(questsRepositoryProvider).fetchQuests();
      return QuestsState(quests: quests);
    });
  }

  /// Returns the server's authoritative completion result (including final
  /// xp/level/coinBalance — never recomputed on the client) so the caller
  /// can show a snackbar, or null if the quest was already completed / the
  /// request failed.
  Future<QuestCompletionResult?> completeQuest(Quest quest) async {
    if (state.valueOrNull == null) return null;

    try {
      final result = await ref.read(questsRepositoryProvider).completeQuest(
            quest.id,
            pinId: quest.pinId,
          );

      // A full re-fetch (not a local patch of just this one quest) because
      // completing a quest can unlock others — the next quest in a Story
      // chapter, a quest gated on this one via the generic 'quest'
      // requirement type — and their `locked` flags need to reflect that.
      final quests = await ref.read(questsRepositoryProvider).fetchQuests();
      state = AsyncData(QuestsState(quests: quests));

      return result.alreadyCompleted ? null : result;
    } catch (_) {
      return null;
    }
  }
}

final questsControllerProvider = AsyncNotifierProvider<QuestsController, QuestsState>(
  QuestsController.new,
);
