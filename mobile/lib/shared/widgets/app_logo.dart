import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Simple drawn mark standing in for a real brand logo: a rounded five-petal
/// flower with a small map-pin center — a warm "travel companion" mark
/// rather than the angular security-shield look this replaced, since a
/// shield reads as guarded/techy rather than friendly.
/// Swap this out once real branding assets exist — everything that shows
/// the app icon imports from here, so replacement is a single-file change.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AppLogoPainter()),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final petalRadius = w * 0.24;

    canvas.drawCircle(center, w * 0.46, Paint()..color = Colors.black.withValues(alpha: 0.06));

    final petalColors = [
      AppColors.pinkLight,
      AppColors.pink,
      AppColors.pinkLight,
      AppColors.pink,
      AppColors.pinkDark,
    ];

    for (var i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * math.pi - math.pi / 2;
      final offset = Offset(
        center.dx + petalRadius * 0.95 * math.cos(angle),
        center.dy + petalRadius * 0.95 * math.sin(angle),
      );
      canvas.drawCircle(offset, petalRadius, Paint()..color = petalColors[i]);
    }

    // Soft cream center disc.
    canvas.drawCircle(center, w * 0.2, Paint()..color = AppColors.yellowPale);

    // A tiny map-pin mark inside the center, so the travel identity reads
    // through even at a glance.
    final pinPath = Path()
      ..moveTo(center.dx, center.dy + w * 0.1)
      ..cubicTo(
        center.dx - w * 0.07, center.dy + w * 0.02,
        center.dx - w * 0.07, center.dy - w * 0.04,
        center.dx, center.dy - w * 0.06,
      )
      ..cubicTo(
        center.dx + w * 0.07, center.dy - w * 0.04,
        center.dx + w * 0.07, center.dy + w * 0.02,
        center.dx, center.dy + w * 0.1,
      )
      ..close();
    canvas.drawPath(pinPath, Paint()..color = AppColors.pinkDark);
    canvas.drawCircle(Offset(center.dx, center.dy - w * 0.02), w * 0.025, Paint()..color = AppColors.yellowPale);
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter oldDelegate) => false;
}
