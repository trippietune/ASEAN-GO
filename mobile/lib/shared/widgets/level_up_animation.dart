import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'gradient_button.dart';

/// Centered, barrier-backed modal celebrating a level-up — deliberately
/// bigger and more blocking than the routine +XP toast (xp_gain_overlay.dart),
/// since crossing a level (or skipping several at once) is a rarer, more
/// significant moment than an ordinary XP grant.
Future<void> showLevelUpAnimation(
  BuildContext context, {
  required int previousLevel,
  required int newLevel,
  required int skippedLevels,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _LevelUpDialog(
      previousLevel: previousLevel,
      newLevel: newLevel,
      skippedLevels: skippedLevels,
    ),
  );
}

class _LevelUpDialog extends StatefulWidget {
  const _LevelUpDialog({
    required this.previousLevel,
    required this.newLevel,
    required this.skippedLevels,
  });

  final int previousLevel;
  final int newLevel;
  final int skippedLevels;

  @override
  State<_LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<_LevelUpDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Opacity(opacity: _fade.value, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.xpBarGradient(widget.newLevel),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.emoji_events, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => AppColors.xpBarGradient(widget.newLevel).createShader(bounds),
                child: Text(
                  l10n.levelUpTitle,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.previousLevel} → ${widget.newLevel}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(l10n.levelUpBody(widget.newLevel), textAlign: TextAlign.center),
              if (widget.skippedLevels > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '🚀 ${l10n.levelUpSkippedLevels(widget.skippedLevels)}',
                  style: TextStyle(fontSize: 16, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 20),
              GradientButton(
                label: l10n.levelUpContinueButton,
                expand: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
