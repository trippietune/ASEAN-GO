import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../store/data/inventory_item_model.dart';
import '../../store/presentation/inventory_controller.dart';

IconData _iconForType(String type) {
  switch (type) {
    case 'outfit':
      return Icons.checkroom;
    case 'avatar':
      return Icons.face_retouching_natural;
    case 'booster':
      return Icons.bolt;
    case 'souvenir':
      return Icons.card_giftcard;
    default:
      return Icons.star;
  }
}

class InventoryGrid extends ConsumerWidget {
  const InventoryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return inventoryAsync.when(
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
      ),
      error: (err, _) => Text(
        'ยังโหลดของสะสมไม่ได้เลย ลองใหม่อีกทีนะ',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'ยังไม่มีของสะสมเลย 🎒\nไปช้อปที่ร้านค้ากันก่อนนะ',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) => _InventoryTile(item: items[index]),
        );
      },
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: AppColors.yellowPale,
                  child: Image.network(
                    item.itemImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(_iconForType(item.itemType), size: 26, color: AppColors.pinkDark),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.itemName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              DateFormat('d MMM').format(item.acquiredAt),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
