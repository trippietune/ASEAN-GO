import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/xp_gain_overlay.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/quest_model.dart';
import 'quest_card.dart';
import 'quest_controller.dart';

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
    final result = await ref.read(questsControllerProvider.notifier).completeQuest(quest);
    if (!mounted) return;
    setState(() => _submittingQuestId = null);

    if (result != null) {
      // Trust the server's final xp/level/coinBalance rather than
      // recomputing the level curve on the client — the backend is the only
      // place that formula should live.
      ref.read(authControllerProvider.notifier).applyXpGain(
            xp: result.xp,
            level: result.level,
            coinBalance: result.coinBalance,
          );

      if (mounted && cardContext.mounted) {
        final box = cardContext.findRenderObject() as RenderBox?;
        if (box != null) {
          final topRight = box.localToGlobal(Offset(box.size.width - 60, box.size.height / 2));
          showXpGainOverlay(context, anchor: topRight, xp: result.xpAwarded);
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
      body: questsAsync.when(
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
          onRetry: () => ref.read(questsControllerProvider.notifier).refresh(),
        ),
        data: (questsState) {
          if (questsState.quests.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.checklist_rtl,
              message: l10n.questsEmptyState,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(questsControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _QuestStatsHeader(questsState: questsState),
                const SizedBox(height: 16),
                for (final (index, quest) in questsState.quests.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(
                      builder: (cardContext) => QuestCard(
                        quest: quest,
                        isSubmitting: _submittingQuestId == quest.id,
                        animationDelay: Duration(milliseconds: 60 * index),
                        onComplete: () => _completeQuest(quest, cardContext),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
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
              allDone ? l10n.questsAllCompletedBanner : l10n.questsKeepGoingBanner,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.iconColor, required this.value, required this.label});

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
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.pinkDark)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
