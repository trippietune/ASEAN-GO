import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Friendly label for a 0-100 safety score: a heart count plus a warm phrase,
/// instead of a bare number in a progress ring — reads as reassuring rather
/// than clinical. Used on pin detail sheets.
class SafetyIndicator extends StatelessWidget {
  const SafetyIndicator({super.key, required this.score, this.size = 56});

  final int score;
  final double size;

  int get _heartCount {
    if (score >= 85) return 3;
    if (score >= 50) return 2;
    return 1;
  }

  String _labelFor(AppLocalizations l10n) {
    if (score >= 70) return l10n.safetyLabelSafe;
    if (score >= 40) return l10n.safetyLabelCaution;
    return l10n.safetyLabelDanger;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.safetyScoreColor(score);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(
                i < _heartCount ? Icons.favorite : Icons.favorite_border,
                size: size * 0.32,
                color: color,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _labelFor(AppLocalizations.of(context)),
          style: TextStyle(fontSize: size * 0.19, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

/// Slim variant for list rows where the full heart row is too heavy.
class SafetyBar extends StatelessWidget {
  const SafetyBar({super.key, required this.score});

  final int score;

  IconData get _icon {
    if (score >= 70) return Icons.verified_outlined;
    if (score >= 40) return Icons.warning_amber_rounded;
    return Icons.dangerous_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.safetyScoreColor(score);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 14, color: color),
        const SizedBox(width: 4),
        Icon(Icons.favorite, size: 12, color: color),
      ],
    );
  }
}
