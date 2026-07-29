import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'proximity_alert_controller.dart';

/// Shows a dismissible warning when the foreground proximity check finds a
/// risky pin nearby. Renders nothing when there's no active alert, so it's
/// safe to drop into any screen's layout (e.g. above Home's content).
class ProximityAlertBanner extends ConsumerWidget {
  const ProximityAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risk = ref.watch(proximityAlertControllerProvider);
    if (risk == null) return const SizedBox.shrink();

    final message = risk.scamAlertMessage ??
        (risk.reportCount > 0
            ? 'มีคนรายงานว่าพื้นที่นี้ควรระวัง (${risk.reportCount} รายงาน)'
            : 'จุดนี้ควรระวังเป็นพิเศษนะ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ใกล้ ${risk.name} 🍂',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.greyDark),
                ),
                const SizedBox(height: 2),
                Text(message, style: const TextStyle(color: AppColors.greyDark, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.greyDark),
            onPressed: () => ref.read(proximityAlertControllerProvider.notifier).dismiss(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
