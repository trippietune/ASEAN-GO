import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'auth_controller.dart';

final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

/// Two-step flow backed by real endpoints (POST /auth/forgot-password then
/// POST /auth/reset-password): step 1 collects the email and requests a
/// 6-digit code; step 2 collects that code plus a new password. A code
/// (rather than a deep-linked reset URL) avoids needing native deep-link
/// config on both platforms — the user just types what the email shows them.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _requestFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _codeRequested = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_requestFormKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _codeRequested = true;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = l10n.forgotPasswordRequestFailed;
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.resetPasswordResendSuccess)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.forgotPasswordRequestFailed)));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _submitReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.resetPasswordSuccessMessage)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = l10n.resetPasswordFailedFallback;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset_outlined, size: 64, color: AppColors.pinkDark),
                const SizedBox(height: 16),
                Text(
                  _codeRequested ? l10n.resetPasswordHeading : l10n.forgotPasswordHeading,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.pinkDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeRequested
                      ? l10n.resetPasswordInstructions(_emailController.text.trim())
                      : l10n.forgotPasswordInstructions,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 24),
                if (_codeRequested) _buildResetForm(l10n) else _buildRequestForm(l10n),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.backToLoginLink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm(AppLocalizations l10n) {
    return Form(
      key: _requestFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.emailRequiredValidator;
              if (!_emailRegex.hasMatch(v)) return l10n.emailValidator;
              return null;
            },
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: l10n.forgotPasswordSubmitButton,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _requestCode,
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm(AppLocalizations l10n) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.yellowPale, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.mark_email_read_outlined, color: AppColors.yellowDark),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.forgotPasswordCodeSentMessage)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 8),
            decoration: InputDecoration(
              labelText: l10n.resetPasswordCodeLabel,
              counterText: '',
            ),
            validator: (v) => (v == null || v.trim().length != 6) ? l10n.resetPasswordCodeValidator : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: l10n.resetPasswordNewPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.length < 8) ? l10n.passwordValidator : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isResending ? null : _resendCode,
              child: Text(l10n.resetPasswordResendCode),
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: l10n.resetPasswordSubmitButton,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submitReset,
          ),
        ],
      ),
    );
  }
}
