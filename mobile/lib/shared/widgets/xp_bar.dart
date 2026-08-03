import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// XP progress bar, colored by the level tier (see AppColors.xpBarGradient).
/// Built as a Stack + FractionallySizedBox rather than LinearProgressIndicator
/// because the latter's valueColor only accepts a solid Color — the 41+
/// tiers need a real multi-stop gradient across the filled portion.
class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.xp, required this.level, this.height = 8});

  final int xp;
  final int level;
  final double height;

  @override
  Widget build(BuildContext context) {
    final xpIntoLevel = xp % 100;
    final progress = (xpIntoLevel / 100).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Stack(
        children: [
          Container(height: height, color: Colors.white.withValues(alpha: 0.5)),
          FractionallySizedBox(
            widthFactor: progress,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.xpBarGradient(level)),
              child: SizedBox(height: height),
            ),
          ),
        ],
      ),
    );
  }
}
