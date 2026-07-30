import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/organic_accent.dart';
import '../../../shared/widgets/social_login_buttons.dart';
import '../data/remembered_email_store.dart';
import 'auth_controller.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rememberedEmailStore = RememberedEmailStore();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _formValid = false;

  @override
  void initState() {
    super.initState();
    _restoreRememberedEmail();
    _emailController.addListener(_revalidate);
    _passwordController.addListener(_revalidate);
  }

  Future<void> _restoreRememberedEmail() async {
    final saved = await _rememberedEmailStore.read();
    if (saved != null && mounted) {
      setState(() {
        _emailController.text = saved;
        _rememberMe = true;
      });
    }
  }

  void _revalidate() {
    final valid = _emailRegex.hasMatch(_emailController.text.trim()) && _passwordController.text.isNotEmpty;
    if (valid != _formValid) setState(() => _formValid = valid);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return l10n.emailRequiredValidator;
    if (!_emailRegex.hasMatch(value)) return l10n.emailValidator;
    return null;
  }

  String? _validatePassword(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return l10n.passwordRequiredValidator;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();

    if (_rememberMe) {
      await _rememberedEmailStore.save(email);
    } else {
      await _rememberedEmailStore.clear();
    }

    if (!mounted) return;
    await ref.read(authControllerProvider.notifier).login(
          email,
          _passwordController.text,
          fallbackError: l10n.loginFailedFallback,
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
          Positioned(
            bottom: -40,
            left: -40,
            child: OrganicAccent(color: AppColors.yellowSoft.withValues(alpha: 0.5), size: 180),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 88)),
                      const SizedBox(height: 16),
                      Text(
                        l10n.loginWelcomeTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.pinkDark,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.loginWelcomeSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
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
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => _validatePassword(l10n, v),
                        onFieldSubmitted: (_) => _formValid && !isLoading ? _submit() : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              value: _rememberMe,
                              onChanged: (value) => setState(() => _rememberMe = value ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(l10n.rememberMeLabel, style: Theme.of(context).textTheme.bodyMedium),
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                    ),
                            child: Text(l10n.forgotPasswordLink),
                          ),
                        ],
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 4),
                        Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 16),
                      GradientButton(
                        label: l10n.loginSubmit,
                        isLoading: isLoading,
                        onPressed: (_formValid && !isLoading) ? _submit : null,
                      ),
                      const SizedBox(height: 20),
                      SocialLoginButtons(
                        enabled: !isLoading,
                        onGooglePressed: _submitGoogle,
                        onFacebookPressed: _submitFacebook,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.noAccountYetPrompt, style: Theme.of(context).textTheme.bodyMedium),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                                    ),
                            child: Text(l10n.registerSubmit),
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
