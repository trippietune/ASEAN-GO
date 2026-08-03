import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import 'schedule_controller.dart';
import 'schedule_date_picker_row.dart';
import 'schedule_item_card.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String itemId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.scheduleItemDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              MaterialLocalizations.of(dialogContext).deleteButtonTooltip,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await ref
        .read(scheduleControllerProvider.notifier)
        .removeItem(itemId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.scheduleItemRemoved : l10n.scheduleItemAddError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedScheduleDateProvider);
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduleScreenTitle)),
      body: AnimatedGradientBackground(
        child: Column(
          children: [
            const SizedBox(height: 12),
            ScheduleDatePickerRow(
              selectedDate: selectedDate,
              onDateChanged: (date) =>
                  ref.read(selectedScheduleDateProvider.notifier).state = date,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: scheduleAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => EmptyStateWidget(
                  icon: Icons.error_outline,
                  message: err.toString(),
                  onRetry: () =>
                      ref.read(scheduleControllerProvider.notifier).refresh(),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.event_note_outlined,
                      message: l10n.scheduleEmptyState,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(scheduleControllerProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => ScheduleItemCard(
                        item: items[index],
                        onDelete: () => _delete(context, ref, items[index].id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
