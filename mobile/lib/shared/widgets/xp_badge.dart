import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class XpBadge extends StatelessWidget {
  const XpBadge({super.key, required this.xp, this.prefix = '+'});

  final int xp;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.yellowPale,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: AppColors.pinkDark),
          const SizedBox(width: 4),
          Text(
            '$prefix$xp XP',
            style: const TextStyle(
              color: AppColors.pinkDark,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
