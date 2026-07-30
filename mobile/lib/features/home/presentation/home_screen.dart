import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_tab_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/level_badge.dart';
import '../../../shared/widgets/organic_accent.dart';
import '../../../shared/widgets/safety_indicator.dart';
import '../../../shared/widgets/xp_badge.dart';
import '../../auth/data/user_model.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../map/data/pin_model.dart';
import '../../map/presentation/map_controller.dart';
import '../../map/presentation/pin_detail_screen.dart';
import '../../quests/data/quest_model.dart';
import '../../quests/presentation/quest_controller.dart';
import '../../safety/presentation/proximity_alert_banner.dart';
import '../../safety/presentation/sos_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: user != null ? _HomeHeader(user: user) : const SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const ProximityAlertBanner(),
                  const _EmergencyButton(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeWhereToGo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ActionCard(
                        icon: Icons.map_outlined,
                        label: l10n.homeActionMap,
                        onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
                      ),
                      _ActionCard(
                        icon: Icons.checklist_rtl,
                        label: l10n.homeActionQuests,
                        onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                      ),
                      _ActionCard(
                        icon: Icons.person_outline,
                        label: l10n.homeActionProfile,
                        onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
                      ),
                      _ActionCard(
                        icon: Icons.notifications_outlined,
                        label: l10n.homeActionNotifications,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.homeNoNewNotifications)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
            sliver: SliverToBoxAdapter(child: _RecommendedQuestsSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            sliver: SliverToBoxAdapter(child: _NearbyPlacesSection()),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsState = ref.watch(questsControllerProvider).valueOrNull;
    final xpIntoLevel = user.xp % 100;
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
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
            top: -20,
            left: -20,
            child: OrganicAccent(color: Colors.white.withValues(alpha: 0.18), size: 120),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 3)),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white38,
                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.displayName.isNotEmpty ? user.displayName.characters.first : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homeGreeting(user.displayName),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(l10n.homeGreetingSubtitle, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    LevelBadge(level: user.level, size: 36),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.homeCloseToNextLevel, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    Text('$xpIntoLevel / 100 XP', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: xpIntoLevel / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                if (questsState != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.track_changes, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        l10n.homeQuestsProgressToday(questsState.completedCount, questsState.totalCount),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedQuestsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questsControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Text(
            l10n.homeRecommendedQuests,
            style: TextStyle(color: AppColors.pinkDark, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: questsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
            data: (state) {
              final pending = state.quests.where((q) => !q.isCompleted).take(5).toList();
              if (pending.isEmpty) {
                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.celebration_outlined, size: 18, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(l10n.homeAllQuestsCompleted),
                    ],
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 20),
                itemCount: pending.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _MiniQuestCard(quest: pending[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniQuestCard extends StatelessWidget {
  const _MiniQuestCard({required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.yellowSoft, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            quest.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Align(alignment: Alignment.centerLeft, child: XpBadge(xp: quest.xpReward)),
        ],
      ),
    );
  }
}

class _NearbyPlacesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsAsync = ref.watch(nearbyPinsProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeNearbyPlaces,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        pinsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          error: (_, _) => Text(l10n.homeNearbyPlacesError),
          data: (pins) {
            final nearest = pins.take(4).toList();
            if (nearest.isEmpty) {
              return Text(l10n.homeNoNearbyPlaces);
            }
            return Column(
              children: [
                for (final pin in nearest) ...[
                  _NearbyPlaceTile(pin: pin),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _NearbyPlaceTile extends StatelessWidget {
  const _NearbyPlaceTile({required this.pin});

  final VerifiedPin pin;

  IconData _iconFor(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'shop':
        return Icons.storefront;
      case 'attraction':
        return Icons.photo_camera;
      case 'transport':
        return Icons.directions_bus;
      case 'lodging':
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.yellowPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(pin.category), color: AppColors.pink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pin.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      pin.city ?? pin.country,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SafetyBar(score: pin.safetyScore),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyButton extends ConsumerWidget {
  const _EmergencyButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosState = ref.watch(sosControllerProvider);
    final activeSos = sosState.valueOrNull;
    final isSending = sosState.isLoading;
    final l10n = AppLocalizations.of(context);

    if (activeSos != null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.greyDark,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: isSending ? null : () => _confirmResolve(context, ref),
          icon: const Icon(Icons.check_circle_outline),
          label: Text(l10n.homeSosActiveButton),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.danger,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isSending ? null : () => _confirmTrigger(context, ref),
        icon: isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.emergency),
        label: Text(l10n.homeSosTriggerButton),
      ),
    );
  }

  Future<void> _confirmTrigger(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.homeSosConfirmTitle),
        content: Text(l10n.homeSosConfirmContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.homeSosCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.homeSosSendButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(sosControllerProvider.notifier).trigger();
    if (!context.mounted) return;

    final result = ref.read(sosControllerProvider);
    result.when(
      data: (event) {
        if (event == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.homeSosSentMessage)),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.homeSosSendFailed(error.toString().replaceFirst('Exception: ', '')))),
        );
      },
      loading: () {},
    );
  }

  Future<void> _confirmResolve(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.homeSosResolveTitle),
        content: Text(l10n.homeSosResolveContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.homeSosNotSafeYet)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.homeSosSafeConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(sosControllerProvider.notifier).resolve();
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.pinkLight.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: AppColors.pinkDark),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
