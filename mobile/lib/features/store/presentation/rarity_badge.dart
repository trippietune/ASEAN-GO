import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
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

String _labelFor(AppLocalizations l10n, ItemRarity rarity) {
  switch (rarity) {
    case ItemRarity.common:
      return l10n.rarityCommon;
    case ItemRarity.rare:
      return l10n.rarityRare;
    case ItemRarity.epic:
      return l10n.rarityEpic;
    case ItemRarity.legendary:
      return l10n.rarityLegendary;
  }
}

class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity});

  final ItemRarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(rarity);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labelFor(l10n, rarity),
        style: TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
