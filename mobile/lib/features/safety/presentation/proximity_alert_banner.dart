import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
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

    final l10n = AppLocalizations.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final message = risk.scamAlertMessage ??
        (risk.reportCount > 0
            ? l10n.proximityAlertReportCountMessage(risk.reportCount)
            : l10n.proximityAlertGenericMessage);

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
                  l10n.proximityAlertNearbyTitle(risk.name),
                  style: TextStyle(fontWeight: FontWeight.bold, color: onSurface),
                ),
                const SizedBox(height: 2),
                Text(message, style: TextStyle(color: onSurface, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: onSurface),
            onPressed: () => ref.read(proximityAlertControllerProvider.notifier).dismiss(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
