import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'gradient_button.dart';

/// Icon-led empty state — a large brand-tinted icon inside a soft circular
/// backdrop standing in for a custom illustration. Swap the icon/backdrop
/// for a real SVG illustration here if/when one is commissioned; every call
/// site already just passes an IconData, so that's a one-file change.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.pinkLight.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 44, color: AppColors.pinkDark),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              GradientButton(
                label: retryLabel ?? AppLocalizations.of(context).retryLabel,
                onPressed: onRetry,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
