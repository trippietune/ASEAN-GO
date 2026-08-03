import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/xp_badge.dart';
import '../data/achievement_model.dart';
import 'achievements_controller.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsScreenTitle)),
      body: AnimatedGradientBackground(
        child: achievementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => EmptyStateWidget(
            icon: Icons.error_outline,
            message: l10n.achievementsLoadError(err.toString()),
            onRetry: () =>
                ref.read(achievementsControllerProvider.notifier).refresh(),
          ),
          data: (achievements) {
            if (achievements.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.emoji_events_outlined,
                message: l10n.achievementsEmptyState,
              );
            }
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(achievementsControllerProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: achievements.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _AchievementCard(achievement: achievements[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unlocked = achievement.unlocked;
    final borderColor = unlocked ? AppColors.success : Colors.grey.shade400;

    return Opacity(
      opacity: unlocked ? 1.0 : 0.65,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    unlocked ? Icons.emoji_events : Icons.lock_outline,
                    size: 26,
                    color: unlocked ? AppColors.success : Colors.grey.shade500,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unlocked ? l10n.achievementUnlockedLabel : l10n.achievementLockedLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: unlocked ? AppColors.success : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: unlocked
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                    ),
                    if (achievement.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        achievement.description!,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                    if (achievement.xpReward > 0 || achievement.coinReward > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (achievement.xpReward > 0) XpBadge(xp: achievement.xpReward),
                          if (achievement.coinReward > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.yellowSoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                l10n.questCoinReward(achievement.coinReward),
                                style: const TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
