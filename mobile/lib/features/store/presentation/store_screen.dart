import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../data/store_item_model.dart';
import 'coin_purchase_dialog.dart';
import 'store_controller.dart';
import 'store_item_card.dart';

const _categories = <String?>[null, 'outfit', 'avatar', 'booster', 'souvenir'];

String _categoryLabel(AppLocalizations l10n, String? category) {
  switch (category) {
    case 'outfit':
      return l10n.storeCategoryOutfit;
    case 'avatar':
      return l10n.storeCategoryAvatar;
    case 'booster':
      return l10n.storeCategoryBooster;
    case 'souvenir':
      return l10n.storeCategorySouvenir;
    default:
      return l10n.storeCategoryAll;
  }
}

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _purchasingItemId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(storeCategoryProvider.notifier).state = _categories[_tabController.index];
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _buy(StoreItem item) async {
    setState(() => _purchasingItemId = item.id);
    final error = await ref.read(storeControllerProvider.notifier).purchaseItem(item);
    if (!mounted) return;
    setState(() => _purchasingItemId = null);

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? l10n.storeItemPurchasedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storeAsync = ref.watch(storeControllerProvider);
    final selectedCategory = ref.watch(storeCategoryProvider);
    final coinBalanceAsync = ref.watch(coinBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storeScreenTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => showCoinPurchaseDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.yellowPale,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, size: 18, color: AppColors.yellowDark),
                      const SizedBox(width: 6),
                      Text(
                        coinBalanceAsync.valueOrNull?.toString() ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.greyDark),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.add_circle, size: 16, color: AppColors.pinkDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [for (final c in _categories) Tab(text: _categoryLabel(l10n, c))],
        ),
      ),
      body: storeAsync.when(
        loading: () => const _StoreGridShimmer(),
        error: (err, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          message: l10n.storeLoadErrorMessage(err.toString()),
          onRetry: () => ref.read(storeControllerProvider.notifier).refresh(),
        ),
        data: (state) {
          final items = selectedCategory == null
              ? state.items
              : state.items.where((i) => i.type == selectedCategory).toList();

          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.shopping_bag_outlined,
              message: l10n.storeEmptyCategoryMessage,
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(storeControllerProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.56,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return StoreItemCard(
                  item: item,
                  isOwned: state.owns(item.id),
                  isPurchasing: _purchasingItemId == item.id,
                  onBuy: () => _buy(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StoreGridShimmer extends StatelessWidget {
  const _StoreGridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.56,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              AspectRatio(aspectRatio: 1, child: LoadingShimmer(borderRadius: 14)),
              SizedBox(height: 10),
              LoadingShimmer(height: 14, width: 100),
              SizedBox(height: 8),
              LoadingShimmer(height: 20, width: 60),
            ],
          ),
        ),
      ),
    );
  }
}
