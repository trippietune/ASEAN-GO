import 'dart:math';
import 'package:flutter/material.dart';

/// A static single wave shape painted near the bottom of the widget, behind
/// [child] — a decorative divider/accent, not wired into any screen yet.
class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key, required this.child, this.color, this.waveHeight = 20});

  final Widget child;
  final Color? color;
  final double waveHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _WavePainter(
              color: color ?? Colors.white.withValues(alpha: 0.5),
              waveHeight: waveHeight,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.color, required this.waveHeight});

  final Color color;
  final double waveHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(0, size.height * 0.8);

    for (double x = 0; x <= size.width; x += 2) {
      final y = size.height * 0.8 + waveHeight * sin(x / 50);
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.waveHeight != waveHeight;
}
