enum ItemRarity { common, rare, epic, legendary }

ItemRarity _parseRarity(String value) {
  return ItemRarity.values.firstWhere(
    (r) => r.name == value,
    orElse: () => ItemRarity.common,
  );
}

class StoreItem {
  const StoreItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.rarity,
    required this.imageUrl,
    required this.isActive,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final String type; // outfit, avatar, booster, souvenir
  final int price;
  final ItemRarity rarity;
  final String imageUrl;
  final bool isActive;

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    return StoreItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      price: json['price'] as int,
      rarity: _parseRarity(json['rarity'] as String),
      imageUrl: json['image_url'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}
