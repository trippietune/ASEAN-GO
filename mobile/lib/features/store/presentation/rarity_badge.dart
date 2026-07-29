import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/store_item_model.dart';

Color _colorFor(ItemRarity rarity) {
  switch (rarity) {
    case ItemRarity.common:
      return Colors.grey.shade400;
    case ItemRarity.rare:
      return AppColors.success;
    case ItemRarity.epic:
      return const Color(0xFFB9A0D4); // muted lavender, stays inside the pastel palette
    case ItemRarity.legendary:
      return AppColors.yellow;
  }
}

String _labelFor(ItemRarity rarity) {
  switch (rarity) {
    case ItemRarity.common:
      return 'ทั่วไป';
    case ItemRarity.rare:
      return 'หายาก';
    case ItemRarity.epic:
      return 'พิเศษ';
    case ItemRarity.legendary:
      return 'ตำนาน';
  }
}

class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity});

  final ItemRarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labelFor(rarity),
        style: TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
