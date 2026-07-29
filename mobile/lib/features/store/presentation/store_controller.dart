import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/coins_repository.dart';
import '../data/store_item_model.dart';
import '../data/store_repository.dart';

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(ref.watch(apiClientProvider));
});

final coinsRepositoryProvider = Provider<CoinsRepository>((ref) {
  return CoinsRepository(ref.watch(apiClientProvider));
});

/// Currently selected store category tab. Null means "all".
final storeCategoryProvider = StateProvider<String?>((ref) => null);

class StoreState {
  const StoreState({required this.items, required this.ownedItemIds});

  final List<StoreItem> items;
  final Set<String> ownedItemIds;

  bool owns(String itemId) => ownedItemIds.contains(itemId);
}

/// Loads the full catalog once and re-filters client-side per category tab,
/// so switching tabs doesn't re-hit the network each time.
class StoreController extends AsyncNotifier<StoreState> {
  @override
  Future<StoreState> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<StoreState> _load() async {
    final repo = ref.read(storeRepositoryProvider);
    final items = await repo.fetchItems();
    final inventory = await repo.fetchInventory();
    return StoreState(
      items: items,
      ownedItemIds: inventory.map((i) => i.itemId).toSet(),
    );
  }

  /// Returns null on success (state already reflects the purchase), or an
  /// error message the caller can show in a snackbar.
  Future<String?> purchaseItem(StoreItem item) async {
    final current = state.valueOrNull;
    if (current == null) return 'ยังโหลดร้านค้าไม่เสร็จ ลองใหม่อีกทีนะ';

    try {
      final result = await ref.read(storeRepositoryProvider).purchaseItem(item.id);

      state = AsyncData(
        StoreState(items: current.items, ownedItemIds: {...current.ownedItemIds, item.id}),
      );

      final authState = ref.read(authControllerProvider);
      if (authState is AuthAuthenticated) {
        ref.read(authControllerProvider.notifier).applyXpGain(
              xp: authState.user.xp,
              level: authState.user.level,
              coinBalance: result.newBalance,
            );
      }

      return null;
    } on Object catch (e) {
      return _purchaseErrorMessage(e);
    }
  }

  String _purchaseErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('409')) return 'มีของชิ้นนี้อยู่แล้วนะ';
    if (message.contains('400')) return 'เหรียญไม่พอ ไปเติมเหรียญกันก่อนนะ';
    return 'ซื้อไม่สำเร็จ ลองใหม่อีกทีนะ';
  }
}

final storeControllerProvider = AsyncNotifierProvider<StoreController, StoreState>(
  StoreController.new,
);

final coinBalanceProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(coinsRepositoryProvider).fetchBalance();
});
