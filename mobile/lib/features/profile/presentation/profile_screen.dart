import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/organic_accent.dart';
import '../../../shared/widgets/xp_bar.dart';
import '../../achievements/presentation/achievements_screen.dart';
import '../../auth/data/user_model.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../map/presentation/favorites_screen.dart';
import '../../quests/presentation/quest_controller.dart';
import '../../store/presentation/store_screen.dart';
import 'inventory_grid.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;
    final questsState = ref.watch(questsControllerProvider).valueOrNull;
    final xpIntoLevel = user.xp % 100;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: AnimatedGradientBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.pinkLight, AppColors.yellowSoft],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -25,
                    right: -25,
                    child: OrganicAccent(
                      color: Colors.white.withValues(alpha: 0.18),
                      size: 130,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 20,
                      20,
                      28,
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: const Border.fromBorderSide(
                              BorderSide(color: AppColors.pink, width: 3.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.pink.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white38,
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName.characters.first
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            color: AppColors.greyDark,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: AppColors.greyDark.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.xpTierAccentColor(user.level),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.profileLevelLabel(user.level),
                                style: TextStyle(
                                  color: AppColors.xpTierAccentColor(user.level),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              XpBar(xp: user.xp, level: user.level, height: 10),
                              const SizedBox(height: 4),
                              Text(
                                l10n.profileXpProgress(xpIntoLevel),
                                style: const TextStyle(
                                  color: AppColors.greyDark,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsRow(user: user, questsState: questsState),
                  const SizedBox(height: 28),
                  Text(
                    l10n.profileMyCollectionsTitle,
                    style: TextStyle(
                      color: AppColors.pinkDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const InventoryGrid(),
                  const SizedBox(height: 28),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.pinkDark,
                      ),
                      title: Text(
                        l10n.profileStoreLabel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.coinBalance}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StoreScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.favorite_border,
                        color: AppColors.pinkDark,
                      ),
                      title: Text(
                        l10n.profileFavoritesLabel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.emoji_events_outlined,
                        color: AppColors.pinkDark,
                      ),
                      title: Text(
                        l10n.profileAchievementsLabel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AchievementsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.pinkDark,
                      ),
                      title: Text(
                        l10n.settingsTitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user, required this.questsState});

  final AppUser user;
  final QuestsState? questsState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            color: AppColors.pinkLight.withValues(alpha: 0.35),
            icon: Icons.check_circle,
            iconColor: AppColors.pinkDark,
            value: '${questsState?.completedCount ?? 0}',
            label: l10n.profileQuestsCompletedLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            color: AppColors.yellowSoft,
            icon: Icons.star,
            iconColor: AppColors.yellowDark,
            value: '${user.xp}',
            label: l10n.profileTotalXpLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            color: const Color(0xFFCFE3E0),
            icon: Icons.monetization_on,
            iconColor: const Color(0xFF2E7D6B),
            value: '${user.coinBalance}',
            label: l10n.profileCoinsLabel,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.greyDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.greyDark.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
