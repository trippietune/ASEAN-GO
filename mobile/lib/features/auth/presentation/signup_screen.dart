import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/organic_accent.dart';
import '../../../shared/widgets/password_strength_indicator.dart';
import '../../../shared/widgets/social_login_buttons.dart';
import 'auth_controller.dart';
import 'terms_of_service_screen.dart';

final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() => _password = _passwordController.text));
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return l10n.emailRequiredValidator;
    if (!_emailRegex.hasMatch(value)) return l10n.emailValidator;
    return null;
  }

  String? _validateUsername(AppLocalizations l10n, String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < 3 || trimmed.length > 30 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return l10n.usernameValidator;
    }
    return null;
  }

  String? _validateConfirmPassword(AppLocalizations l10n, String? value) {
    if (value != _passwordController.text) return l10n.confirmPasswordMismatch;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() => _showTermsError = true);
      return;
    }
    final l10n = AppLocalizations.of(context);
    await ref.read(authControllerProvider.notifier).register(
          _emailController.text.trim(),
          _passwordController.text,
          _displayNameController.text.trim(),
          _usernameController.text.trim(),
          fallbackError: l10n.registerFailedFallback,
        );
  }

  Future<void> _submitGoogle() async {
    final l10n = AppLocalizations.of(context);
    await ref.read(authControllerProvider.notifier).loginWithGoogle(
          fallbackError: l10n.socialLoginFailedFallback,
        );
  }

  Future<void> _submitFacebook() async {
    final l10n = AppLocalizations.of(context);
    await ref.read(authControllerProvider.notifier).loginWithFacebook(
          fallbackError: l10n.socialLoginFailedFallback,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;
    final error = authState is AuthUnauthenticated ? authState.error : null;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signupTitle)),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.yellowPale, AppColors.white],
                stops: [0, 0.5],
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: OrganicAccent(color: AppColors.pinkLight.withValues(alpha: 0.35), size: 160),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 72)),
                      const SizedBox(height: 16),
                      Text(
                        l10n.signupHeading,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.pinkDark,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.signupSubheading,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _displayNameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                          labelText: l10n.displayNameLabel,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l10n.displayNameValidator : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newUsername],
                        decoration: InputDecoration(
                          labelText: l10n.usernameLabel,
                          prefixIcon: const Icon(Icons.alternate_email),
                        ),
                        validator: (v) => _validateUsername(l10n, v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l10n.emailLabel,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (v) => _validateEmail(l10n, v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 8) ? l10n.passwordValidator : null,
                        onChanged: (_) => _formKey.currentState?.validate(),
                      ),
                      PasswordStrengthIndicator(password: _password),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        keyboardType: TextInputType.visiblePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: l10n.confirmPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (v) => _validateConfirmPassword(l10n, v),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _acceptedTerms,
                        onChanged: (value) => setState(() {
                          _acceptedTerms = value ?? false;
                          if (_acceptedTerms) _showTermsError = false;
                        }),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('${l10n.termsAgreementPrefix} ', style: Theme.of(context).textTheme.bodyMedium),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                              ),
                              child: Text(
                                l10n.termsOfServiceLink,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.pinkDark,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showTermsError) ...[
                        const SizedBox(height: 4),
                        Text(l10n.termsAgreementRequired, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 24),
                      GradientButton(
                        label: l10n.registerSubmit,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _submit,
                      ),
                      const SizedBox(height: 20),
                      SocialLoginButtons(
                        enabled: !isLoading,
                        googleLabel: l10n.signUpWithGoogle,
                        facebookLabel: l10n.signUpWithFacebook,
                        onGooglePressed: _submitGoogle,
                        onFacebookPressed: _submitFacebook,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.haveAccountPrompt, style: Theme.of(context).textTheme.bodyMedium),
                          TextButton(
                            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                            child: Text(l10n.logInLinkLabel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
