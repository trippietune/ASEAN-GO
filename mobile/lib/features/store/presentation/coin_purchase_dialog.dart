import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/coins_repository.dart';
import 'card_form_screen.dart';
import 'store_controller.dart';

Future<void> showCoinPurchaseDialog(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const CoinPurchaseDialog(),
  );
}

/// Value framing vs. the smallest package's coins-per-baht rate, so bigger
/// packages visibly look like a better deal.
double _valuePerBaht(CoinPackage p) => p.coins / p.priceThb;

int _bonusPercent(CoinPackage p) {
  final baseline = _valuePerBaht(CoinPackage.small);
  final ratio = _valuePerBaht(p) / baseline;
  return ((ratio - 1) * 100).round();
}

class CoinPurchaseDialog extends ConsumerStatefulWidget {
  const CoinPurchaseDialog({super.key});

  @override
  ConsumerState<CoinPurchaseDialog> createState() => _CoinPurchaseDialogState();
}

class _CoinPurchaseDialogState extends ConsumerState<CoinPurchaseDialog> {
  CoinPackage? _purchasing;

  Future<void> _buy(CoinPackage package) async {
    setState(() => _purchasing = package);

    final result = await showCardFormScreen(
      context,
      package: package,
      onCharge: (token) => ref.read(coinsRepositoryProvider).purchaseCoins(package, omiseToken: token),
    );

    if (!mounted) return;
    setState(() => _purchasing = null);
    if (result == null) return; // user backed out of the card form

    final authState = ref.read(authControllerProvider);
    if (authState is AuthAuthenticated && result.newBalance != null) {
      ref.read(authControllerProvider.notifier).applyXpGain(
            xp: authState.user.xp,
            level: authState.user.level,
            coinBalance: result.newBalance,
          );
    }
    ref.invalidate(coinBalanceProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on, color: AppColors.yellowDark, size: 22),
              const SizedBox(width: 6),
              Text(
                l10n.coinPurchaseTitle,
                style: TextStyle(color: AppColors.pinkDark, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.coinPurchaseSubtitle,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          for (final package in CoinPackage.values) ...[
            _CoinPackageTile(
              package: package,
              isPurchasing: _purchasing == package,
              disabled: _purchasing != null,
              onTap: () => _buy(package),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                l10n.coinPurchaseSecureNote,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinPackageTile extends StatelessWidget {
  const _CoinPackageTile({
    required this.package,
    required this.isPurchasing,
    required this.disabled,
    required this.onTap,
  });

  final CoinPackage package;
  final bool isPurchasing;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bonus = _bonusPercent(package);

    return Material(
      color: AppColors.yellowPale,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.monetization_on, size: 30, color: AppColors.yellowDark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.coinAmountLabel(package.coins),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.greyDark),
                    ),
                    if (bonus > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.coinPurchaseBonusPercent(bonus),
                        style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 84,
                child: FilledButton(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  onPressed: disabled ? null : onTap,
                  child: isPurchasing
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('฿${package.priceThb}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
