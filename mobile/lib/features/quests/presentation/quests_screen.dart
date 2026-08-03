import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/level_up_animation.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/xp_gain_overlay.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/quest_model.dart';
import 'quest_card.dart';
import 'quest_controller.dart';

// Fixed, deliberate ordering for quest-type sections — not alphabetical or
// server-determined, so the screen reads as a stable progression (daily
// habit -> exploration -> milestones -> story) rather than shuffling as new
// types are added.
const _questTypeOrder = ['daily', 'location', 'category', 'level', 'story'];

String _typeLabel(AppLocalizations l10n, String questType) {
  switch (questType) {
    case 'daily':
      return l10n.questTypeDaily;
    case 'location':
      return l10n.questTypeLocation;
    case 'category':
      return l10n.questTypeCategory;
    case 'level':
      return l10n.questTypeLevel;
    case 'story':
      return l10n.questTypeStory;
    default:
      return questType;
  }
}

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  String? _submittingQuestId;

  Future<void> _completeQuest(Quest quest, BuildContext cardContext) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _submittingQuestId = quest.id);
    final result = await ref
        .read(questsControllerProvider.notifier)
        .completeQuest(quest);
    if (!mounted) return;
    setState(() => _submittingQuestId = null);

    if (result != null) {
      // Trust the server's final xp/level/coinBalance rather than
      // recomputing the level curve on the client — the backend is the only
      // place that formula should live.
      ref
          .read(authControllerProvider.notifier)
          .applyXpGain(
            xp: result.xp,
            level: result.level,
            coinBalance: result.coinBalance,
          );

      if (mounted && cardContext.mounted) {
        final box = cardContext.findRenderObject() as RenderBox?;
        if (box != null) {
          final topRight = box.localToGlobal(
            Offset(box.size.width - 60, box.size.height / 2),
          );
          showXpGainOverlay(context, anchor: topRight, xp: result.xpAwarded);
        }
      }

      if (result.leveledUp && mounted) {
        await showLevelUpAnimation(
          context,
          previousLevel: result.previousLevel,
          newLevel: result.level,
          skippedLevels: result.skippedLevels,
        );
      }

      // Sequenced after the level-up animation, not blocking it — a toast
      // is lightweight enough to just queue behind any modal already shown.
      if (mounted && result.awardedAchievements.isNotEmpty) {
        for (final achievement in result.awardedAchievements) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.questUnlockAchievementToast(achievement.title),
              ),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.questAlreadyCompletedOrRetry)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(questsControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.questsScreenTitle)),
      body: AnimatedGradientBackground(
        child: questsAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              QuestCardShimmer(),
              SizedBox(height: 12),
              QuestCardShimmer(),
              SizedBox(height: 12),
              QuestCardShimmer(),
            ],
          ),
          error: (err, _) => EmptyStateWidget(
            icon: Icons.error_outline,
            message: l10n.questsLoadError(err.toString()),
            onRetry: () =>
                ref.read(questsControllerProvider.notifier).refresh(),
          ),
          data: (questsState) {
            if (questsState.quests.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.checklist_rtl,
                message: l10n.questsEmptyState,
              );
            }
            final byType = questsState.byType;
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(questsControllerProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _QuestStatsHeader(questsState: questsState),
                  const SizedBox(height: 20),
                  for (final questType in _questTypeOrder)
                    if (byType[questType]?.isNotEmpty ?? false)
                      _QuestTypeSection(
                        questType: questType,
                        quests: byType[questType]!,
                        submittingQuestId: _submittingQuestId,
                        onComplete: _completeQuest,
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuestTypeSection extends StatelessWidget {
  const _QuestTypeSection({
    required this.questType,
    required this.quests,
    required this.submittingQuestId,
    required this.onComplete,
  });

  final String questType;
  final List<Quest> quests;
  final String? submittingQuestId;
  final void Function(Quest, BuildContext) onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _typeLabel(l10n, questType),
            style: TextStyle(
              color: AppColors.pinkDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (questType == 'story')
            _StoryChapters(
              quests: quests,
              submittingQuestId: submittingQuestId,
              onComplete: onComplete,
            )
          else
            for (final (index, quest) in quests.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Builder(
                  builder: (cardContext) => QuestCard(
                    quest: quest,
                    isSubmitting: submittingQuestId == quest.id,
                    animationDelay: Duration(milliseconds: 60 * index),
                    onComplete: () => onComplete(quest, cardContext),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Story quests additionally group by chapter, with a per-chapter completion
/// count — computed client-side from each quest's chapterId/status (no
/// separate "is this chapter complete" endpoint).
class _StoryChapters extends StatelessWidget {
  const _StoryChapters({
    required this.quests,
    required this.submittingQuestId,
    required this.onComplete,
  });

  final List<Quest> quests;
  final String? submittingQuestId;
  final void Function(Quest, BuildContext) onComplete;

  @override
  Widget build(BuildContext context) {
    final chapters = <String?, List<Quest>>{};
    for (final quest in quests) {
      (chapters[quest.chapterId] ??= []).add(quest);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in chapters.entries) ...[
          if (entry.key != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.value.where((q) => q.isCompleted).length}/${entry.value.length}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          for (final (index, quest) in entry.value.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Builder(
                builder: (cardContext) => QuestCard(
                  quest: quest,
                  isSubmitting: submittingQuestId == quest.id,
                  animationDelay: Duration(milliseconds: 60 * index),
                  onComplete: () => onComplete(quest, cardContext),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _QuestStatsHeader extends StatelessWidget {
  const _QuestStatsHeader({required this.questsState});

  final QuestsState questsState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remaining = questsState.totalCount - questsState.completedCount;
    final allDone = questsState.totalCount > 0 && remaining == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatPill(
                icon: Icons.check_circle,
                iconColor: AppColors.success,
                value: '${questsState.completedCount}',
                label: l10n.questStatCompleted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatPill(
                icon: Icons.pending_actions,
                iconColor: AppColors.pinkDark,
                value: '$remaining',
                label: l10n.questStatRemaining,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatPill(
                icon: Icons.star,
                iconColor: AppColors.yellow,
                value: '${questsState.totalCount}',
                label: l10n.questStatTotal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              allDone ? Icons.celebration_outlined : Icons.flag_outlined,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              allDone
                  ? l10n.questsAllCompletedBanner
                  : l10n.questsKeepGoingBanner,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.pinkDark,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
