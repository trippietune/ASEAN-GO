import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/store_item_model.dart';
import 'rarity_badge.dart';

IconData _fallbackIconFor(String type) {
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

class StoreItemCard extends StatelessWidget {
  const StoreItemCard({
    super.key,
    required this.item,
    required this.isOwned,
    required this.isPurchasing,
    required this.onBuy,
  });

  final StoreItem item;
  final bool isOwned;
  final bool isPurchasing;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: AppColors.yellowPale,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(_fallbackIconFor(item.type), size: 36, color: AppColors.pinkDark),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.greyDark),
            ),
            const SizedBox(height: 4),
            RarityBadge(rarity: item.rarity),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text('${item.price}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: isOwned
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '✅ มีแล้ว',
                        style: TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      onPressed: isPurchasing ? null : onBuy,
                      child: isPurchasing
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('ซื้อ'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
