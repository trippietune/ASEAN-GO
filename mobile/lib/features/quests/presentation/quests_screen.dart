import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
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
    setState(() => _submittingQuestId = quest.id);
    final xpAwarded = await ref.read(questsControllerProvider.notifier).completeQuest(quest);
    if (!mounted) return;
    setState(() => _submittingQuestId = null);

    if (xpAwarded != null) {
      final user = ref.read(authControllerProvider);
      if (user is AuthAuthenticated) {
        ref.read(authControllerProvider.notifier).applyXpGain(
              xp: user.user.xp + xpAwarded,
              level: (user.user.xp + xpAwarded) ~/ 100 + 1,
              coinBalance: user.user.coinBalance + quest.coinReward,
            );
      }

      if (mounted && cardContext.mounted) {
        final box = cardContext.findRenderObject() as RenderBox?;
        if (box != null) {
          final topRight = box.localToGlobal(Offset(box.size.width - 60, box.size.height / 2));
          showXpGainOverlay(context, anchor: topRight, xp: xpAwarded);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ภารกิจนี้ทำไปแล้ว หรือลองใหม่อีกทีนะ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(questsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ภารกิจประจำวัน 🎯')),
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
          message: 'ยังโหลดภารกิจไม่ได้เลย ลองใหม่อีกทีนะ\n$err',
          onRetry: () => ref.read(questsControllerProvider.notifier).refresh(),
        ),
        data: (questsState) {
          if (questsState.quests.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.checklist_rtl,
              message: 'ยังไม่มีภารกิจตอนนี้เลย กลับมาดูใหม่เร็วๆ นี้นะ',
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
    final remaining = questsState.totalCount - questsState.completedCount;
    final allDone = questsState.totalCount > 0 && remaining == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _StatPill(emoji: '✅', value: '${questsState.completedCount}', label: 'ทำแล้ว')),
            const SizedBox(width: 10),
            Expanded(child: _StatPill(emoji: '🌱', value: '$remaining', label: 'เหลืออีก')),
            const SizedBox(width: 10),
            Expanded(child: _StatPill(emoji: '⭐', value: '${questsState.totalCount}', label: 'ทั้งหมด')),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          allDone ? 'เก่งมาก ทำครบทุกภารกิจแล้ว! 🎉' : 'ทำต่ออีกนิดนะ สู้ๆ 🌿',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.emoji, required this.value, required this.label});

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.pinkDark)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
