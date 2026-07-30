import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

enum PasswordStrength { empty, weak, medium, strong }

/// Scores a password on length + character-class variety. Intentionally
/// simple (no dictionary/breach checks) — this is a UX nudge, not the
/// server-side policy; the backend still only enforces `min(8)`.
PasswordStrength computePasswordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.empty;

  var score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) score++;

  if (score <= 1) return PasswordStrength.weak;
  if (score <= 3) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

/// Three-segment strength bar shown under the password field while typing,
/// hidden entirely when the field is empty.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = computePasswordStrength(password);
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final (segments, color, label) = switch (strength) {
      PasswordStrength.empty => (0, AppColors.textHint, ''),
      PasswordStrength.weak => (1, AppColors.danger, l10n.passwordStrengthWeak),
      PasswordStrength.medium => (2, AppColors.warning, l10n.passwordStrengthMedium),
      PasswordStrength.strong => (3, AppColors.success, l10n.passwordStrengthStrong),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                decoration: BoxDecoration(
                  color: i < segments ? color : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
