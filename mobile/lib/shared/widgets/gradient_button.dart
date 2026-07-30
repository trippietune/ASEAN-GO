import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Primary call-to-action button: flat pinkDark fill with a gentle
/// press-down scale, used in place of a plain ElevatedButton wherever the
/// design calls for extra emphasis (login, check-in, complete quest).
///
/// Kept the class name `GradientButton` even though it no longer renders a
/// gradient — every screen already imports it by this name, and the swap-in
/// stayed a one-file change. Uses `pinkDark` (not `pink`) for the same WCAG
/// AA contrast reason as the theme's button styles: white-on-pink is 4.35:1,
/// under the 4.5:1 threshold for this text size; pinkDark clears it at 5.87:1.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.expand ? double.infinity : null,
          decoration: BoxDecoration(
            color: disabled ? Colors.grey.shade300 : AppColors.pinkDark,
            borderRadius: BorderRadius.circular(12),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.pinkDark.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: disabled ? null : widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                child: Row(
                  mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else ...[
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
