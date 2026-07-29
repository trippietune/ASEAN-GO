import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/organic_accent.dart';
import '../../auth/data/user_model.dart';
import '../../auth/presentation/auth_controller.dart';
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

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ClipRRect(
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
                  top: -25,
                  right: -25,
                  child: OrganicAccent(color: Colors.white.withValues(alpha: 0.18), size: 130),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 28),
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 4)),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white38,
                          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  user.displayName.isNotEmpty ? user.displayName.characters.first : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(user.email, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'เลเวล ${user.level} 🌟',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: xpIntoLevel / 100,
                                minHeight: 10,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('$xpIntoLevel / 100 XP', style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                  'ของสะสมน่ารักๆ 🎒',
                  style: TextStyle(color: AppColors.pinkDark, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const InventoryGrid(),
                const SizedBox(height: 28),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront_outlined, color: AppColors.pinkDark),
                    title: const Text('ร้านค้า', style: TextStyle(color: AppColors.greyDark)),
                    subtitle: Text('${user.coinBalance} 🪙', style: TextStyle(color: Colors.grey.shade600)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StoreScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.settings_outlined, color: AppColors.pinkDark),
                    title: const Text('การตั้งค่า', style: TextStyle(color: AppColors.greyDark)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            color: AppColors.pinkLight.withValues(alpha: 0.35),
            emoji: '✅',
            value: '${questsState?.completedCount ?? 0}',
            label: 'เควสสำเร็จ',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            color: AppColors.yellowSoft,
            emoji: '⭐',
            value: '${user.xp}',
            label: 'XP ทั้งหมด',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            color: const Color(0xFFCFE3E0),
            emoji: '🪙',
            value: '${user.coinBalance}',
            label: 'เหรียญ',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.color, required this.emoji, required this.value, required this.label});

  final Color color;
  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.greyDark, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: AppColors.greyDark.withValues(alpha: 0.7), fontSize: 11)),
        ],
      ),
    );
  }
}


