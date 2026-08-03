import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/schedule_model.dart';

class ScheduleItemCard extends StatelessWidget {
  const ScheduleItemCard({super.key, required this.item, required this.onDelete});

  final ScheduleItem item;
  final VoidCallback onDelete;

  /// "09:30 - 11:00", "09:30" (no end time), or null if neither is set.
  String? _timeRangeLabel(ScheduleItem item) {
    final start = item.startTime?.substring(0, 5);
    final end = item.endTime?.substring(0, 5);
    if (start == null) return null;
    return end != null ? '$start - $end' : start;
  }

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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: const Border(left: BorderSide(color: AppColors.yellowSoft, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconFor(item.pinCategory), size: 26, color: AppColors.pinkDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.pinName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      _timeRangeLabel(item),
                      item.pinCity ?? item.pinCountry,
                    ].whereType<String>().join(' · '),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  if (item.note != null && item.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.note!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.pinkDark),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
