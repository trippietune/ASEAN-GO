import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, this.size = 40});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.pink,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppColors.pinkDark.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
