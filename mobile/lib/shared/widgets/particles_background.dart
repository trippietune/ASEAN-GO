import 'dart:math';
import 'package:flutter/material.dart';

/// Faint floating shapes (circle/square/triangle) drifting behind [child] —
/// a decorative layer, not wired into any screen yet. Each particle gets a
/// random size/position/phase/color once at construction; a single shared
/// [AnimationController] (normalized 0..1, looping) drives all of them so
/// there's one ticker for the whole widget instead of one per particle.
class ParticlesBackground extends StatefulWidget {
  const ParticlesBackground({
    super.key,
    required this.child,
    this.particleCount = 12,
    this.opacity = 0.6,
    this.colors = const [
      Color(0xFFE91E63),
      Color(0xFFF9A825),
      Color(0xFF42A5F5),
      Color(0xFF66BB6A),
      Color(0xFFAB47BC),
    ],
  });

  final Widget child;
  final int particleCount;
  final double opacity;
  final List<Color> colors;

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    // A long, non-looping-per-particle master clock — each particle reads
    // its own phase-shifted position off of it via sin(), so individual
    // particles don't need (and don't get) their own AnimationController.
    _controller = AnimationController(duration: const Duration(seconds: 30), vsync: this)..repeat();

    final random = Random();
    _particles = List.generate(
      widget.particleCount,
      (index) => _Particle(
        size: 10 + random.nextDouble() * 40,
        leftFraction: random.nextDouble(),
        topFraction: random.nextDouble(),
        // Cycles per full controller loop — varies per particle so they
        // don't all bob in lockstep.
        cyclesPerLoop: 1 + random.nextDouble() * 3,
        phase: random.nextDouble() * 2 * pi,
        baseOpacity: 0.03 + random.nextDouble() * 0.07,
        color: widget.colors[random.nextInt(widget.colors.length)],
        shape: _ParticleShape.values[random.nextInt(_ParticleShape.values.length)],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                for (final particle in _particles)
                  _buildParticle(particle, _controller.value, constraints.biggest),
                child!,
              ],
            );
          },
          child: widget.child,
        );
      },
    );
  }

  Widget _buildParticle(_Particle particle, double t, Size bounds) {
    final angle = t * particle.cyclesPerLoop * 2 * pi + particle.phase;
    final bob = sin(angle);
    final scale = 0.8 + 0.4 * (sin(angle * 0.5) + 1) / 2;

    return Positioned(
      left: particle.leftFraction * bounds.width,
      top: particle.topFraction * bounds.height,
      child: Transform.translate(
        offset: Offset(0, bob * 25),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: particle.baseOpacity * widget.opacity,
            child: _ParticleShapeWidget(shape: particle.shape, color: particle.color, size: particle.size),
          ),
        ),
      ),
    );
  }
}

enum _ParticleShape { circle, square, triangle }

class _Particle {
  const _Particle({
    required this.size,
    required this.leftFraction,
    required this.topFraction,
    required this.cyclesPerLoop,
    required this.phase,
    required this.baseOpacity,
    required this.color,
    required this.shape,
  });

  final double size;
  final double leftFraction;
  final double topFraction;
  final double cyclesPerLoop;
  final double phase;
  final double baseOpacity;
  final Color color;
  final _ParticleShape shape;
}

class _ParticleShapeWidget extends StatelessWidget {
  const _ParticleShapeWidget({required this.shape, required this.color, required this.size});

  final _ParticleShape shape;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (shape) {
      case _ParticleShape.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        );
      case _ParticleShape.square:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        );
      case _ParticleShape.triangle:
        return CustomPaint(painter: _TrianglePainter(color: color), size: Size(size, size));
    }
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}
