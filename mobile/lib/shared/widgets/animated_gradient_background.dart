import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Slowly-drifting pastel-yellow radial gradient used as the backdrop for
/// the app's main tab screens — gives otherwise-flat screens a bit of life
/// without the cost/asset overhead of a Lottie animation. Wrap a screen's
/// body in this instead of a plain [Container]/[Scaffold] background.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.opacity = 1.0,
    this.duration = const Duration(seconds: 12),
    this.colors = const [
      AppColors.creamYellow,
      AppColors.yellowPale,
      AppColors.lightYellow,
      AppColors.softCream,
    ],
  });

  final Widget child;
  final double opacity;
  final Duration duration;
  final List<Color> colors;

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Alignment> _centerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)..repeat(reverse: true);
    _centerAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _centerAnimation,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: _centerAnimation.value,
              radius: 1.5,
              // No explicit `stops` — Flutter spaces colors evenly by
              // default, so this stays correct regardless of how many
              // colors a caller passes (the fixed 4-stop list this replaced
              // would silently mis-render or throw if `colors.length` ever
              // diverged from 4).
              colors: widget.colors,
            ),
          ),
          child: widget.opacity == 1.0 ? child : Opacity(opacity: widget.opacity, child: child),
        );
      },
      child: widget.child,
    );
  }
}
