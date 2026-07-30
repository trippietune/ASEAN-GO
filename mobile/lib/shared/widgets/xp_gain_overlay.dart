import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shows a "+XX XP" label that floats up and fades out, anchored at
/// [anchor] (global coordinates), then removes itself. Fire-and-forget via
/// [showXpGainOverlay] — no state to manage at the call site.
void showXpGainOverlay(BuildContext context, {required Offset anchor, required int xp}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _FloatingXpLabel(
      anchor: anchor,
      xp: xp,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _FloatingXpLabel extends StatefulWidget {
  const _FloatingXpLabel({required this.anchor, required this.xp, required this.onDone});

  final Offset anchor;
  final int xp;
  final VoidCallback onDone;

  @override
  State<_FloatingXpLabel> createState() => _FloatingXpLabelState();
}

class _FloatingXpLabelState extends State<_FloatingXpLabel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rise;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _rise = Tween<double>(begin: 0, end: -70).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.55, 1, curve: Curves.easeIn));
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.anchor.dx,
          top: widget.anchor.dy + _rise.value,
          child: Opacity(
            opacity: 1 - _fade.value,
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 18,
            color: AppColors.pinkDark,
            shadows: [Shadow(color: Colors.white, blurRadius: 4)],
          ),
          const SizedBox(width: 4),
          Text(
            '+${widget.xp} XP',
            style: const TextStyle(
              color: AppColors.pinkDark,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              shadows: [Shadow(color: Colors.white, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
