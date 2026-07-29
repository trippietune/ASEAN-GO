import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

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

  String get _label {
    if (score >= 70) return 'น่าปลอดภัย';
    if (score >= 40) return 'ระวังหน่อยนะ';
    return 'ควรระวังมากๆ';
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
          _label,
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

  String get _emoji {
    if (score >= 70) return '🌸';
    if (score >= 40) return '🌱';
    return '🍂';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.safetyScoreColor(score);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Icon(Icons.favorite, size: 12, color: color),
      ],
    );
  }
}
