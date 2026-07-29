import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inventory_item_model.dart';
import 'store_controller.dart';

/// Just the user's owned items — used by the Profile screen, which doesn't
/// need the full store catalog. Separate from [storeControllerProvider] so
/// visiting Profile doesn't pull in every store item.
final inventoryProvider = FutureProvider.autoDispose<List<InventoryItem>>((ref) async {
  return ref.watch(storeRepositoryProvider).fetchInventory();
});
