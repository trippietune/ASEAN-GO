import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

const _googleBrandColor = Color(0xFF4285F4);
const _facebookBrandColor = Color(0xFF1877F2);

/// Google + Facebook sign-in buttons stacked with an "OR" divider above them,
/// used identically on both login and signup (only the label text differs,
/// since the underlying action is the same find-or-create on the backend).
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({
    super.key,
    required this.onGooglePressed,
    required this.onFacebookPressed,
    this.googleLabel,
    this.facebookLabel,
    this.enabled = true,
  });

  final VoidCallback? onGooglePressed;
  final VoidCallback? onFacebookPressed;
  final String? googleLabel;
  final String? facebookLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(l10n.orDivider, style: Theme.of(context).textTheme.labelSmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        _SocialButton(
          label: googleLabel ?? l10n.continueWithGoogle,
          badgeText: 'G',
          badgeColor: _googleBrandColor,
          onPressed: enabled ? onGooglePressed : null,
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: facebookLabel ?? l10n.continueWithFacebook,
          badgeText: 'f',
          badgeColor: _facebookBrandColor,
          onPressed: enabled ? onFacebookPressed : null,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.badgeText,
    required this.badgeColor,
    required this.onPressed,
  });

  final String label;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
            child: Text(
              badgeText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
