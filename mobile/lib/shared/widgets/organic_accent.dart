import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Soft, hand-drawn-feeling blob shape for corner decoration — deliberately
/// imperfect/asymmetric curves rather than a perfect circle, so screens with
/// a plain pastel background don't read as bare or "engineered".
class OrganicAccent extends StatelessWidget {
  const OrganicAccent({super.key, required this.color, this.size = 140});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BlobPainter(color: color)),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;

    // An asymmetric rounded blob: control points nudged unevenly so it
    // doesn't read as a perfect circle.
    final path = Path()
      ..moveTo(w * 0.5, h * 0.02)
      ..cubicTo(w * 0.85, h * 0.05, w * 0.98, h * 0.35, w * 0.95, h * 0.6)
      ..cubicTo(w * 0.92, h * 0.88, w * 0.6, h * 1.0, w * 0.35, h * 0.95)
      ..cubicTo(w * 0.08, h * 0.9, w * -0.02, h * 0.55, w * 0.08, h * 0.3)
      ..cubicTo(w * 0.18, h * 0.05, w * 0.2, h * -0.02, w * 0.5, h * 0.02)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) => oldDelegate.color != color;
}

/// A small hand-drawn-style flower doodle: five overlapping petal circles
/// around a lighter center, used as an inline decorative mark instead of a
/// hard Material icon.
class FlowerDoodle extends StatelessWidget {
  const FlowerDoodle({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FlowerPainter(color: color)),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  const _FlowerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalRadius = size.width * 0.22;
    final petalPaint = Paint()..color = color.withValues(alpha: 0.85);

    for (var i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * math.pi;
      final offset = Offset(
        center.dx + petalRadius * 0.9 * math.cos(angle),
        center.dy + petalRadius * 0.9 * math.sin(angle),
      );
      canvas.drawCircle(offset, petalRadius, petalPaint);
    }
    canvas.drawCircle(center, size.width * 0.14, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter oldDelegate) => oldDelegate.color != color;
}
