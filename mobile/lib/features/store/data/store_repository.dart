import '../../../core/api/api_client.dart';
import 'inventory_item_model.dart';
import 'store_item_model.dart';

class PurchaseResult {
  const PurchaseResult({required this.item, required this.newBalance});

  final StoreItem item;
  final int newBalance;

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    return PurchaseResult(
      item: StoreItem.fromJson(json['item'] as Map<String, dynamic>),
      newBalance: json['newBalance'] as int,
    );
  }
}

class StoreRepository {
  StoreRepository(this._client);

  final ApiClient _client;

  Future<List<StoreItem>> fetchItems({String? category}) async {
    final response = await _client.dio.get('/store/items', queryParameters: {
      // ignore: use_null_aware_elements
      if (category != null) 'category': category,
    });
    return (response.data as List)
        .map((e) => StoreItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryItem>> fetchInventory() async {
    final response = await _client.dio.get('/inventory');
    return (response.data as List)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Throws a [DioException] with status 409 if the item is already owned,
  /// or 400 if the user doesn't have enough coins.
  Future<PurchaseResult> purchaseItem(String itemId) async {
    final response = await _client.dio.post('/inventory/purchase', data: {'itemId': itemId});
    return PurchaseResult.fromJson(response.data as Map<String, dynamic>);
  }
}
