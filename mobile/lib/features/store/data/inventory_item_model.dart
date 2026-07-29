import 'store_item_model.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.itemRarity,
    required this.itemImageUrl,
    required this.acquiredAt,
  });

  final String id;
  final String itemId;
  final String itemName;
  final String itemType;
  final ItemRarity itemRarity;
  final String itemImageUrl;
  final DateTime acquiredAt;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String,
      itemType: json['item_type'] as String,
      itemRarity: ItemRarity.values.firstWhere(
        (r) => r.name == json['item_rarity'] as String,
        orElse: () => ItemRarity.common,
      ),
      itemImageUrl: json['item_image_url'] as String,
      acquiredAt: DateTime.parse(json['acquired_at'] as String),
    );
  }
}
