import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../data/pin_model.dart';
import 'map_controller.dart';
import 'pin_detail_screen.dart';
import 'star_rating.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritePinsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesScreenTitle)),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          message: err.toString(),
          onRetry: () => ref.invalidate(favoritePinsProvider),
        ),
        data: (pins) {
          if (pins.isEmpty) {
            return EmptyStateWidget(icon: Icons.favorite_border, message: l10n.favoritesEmptyState);
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(favoritePinsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pins.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _FavoritePinCard(pin: pins[index]),
            ),
          );
        },
      ),
    );
  }
}

class _FavoritePinCard extends StatelessWidget {
  const _FavoritePinCard({required this.pin});

  final VerifiedPin pin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: AppColors.pinkLight,
          child: Icon(Icons.favorite, color: AppColors.pinkDark, size: 18),
        ),
        title: Text(pin.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Expanded(child: Text('${pin.category} · ${pin.city ?? pin.country}')),
            StarRating(rating: pin.averageRating, size: 14),
          ],
        ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PinDetailScreen(pin: pin))),
      ),
    );
  }
}
