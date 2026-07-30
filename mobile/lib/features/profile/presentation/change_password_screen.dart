import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/presentation/auth_controller.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.changePasswordSuccess)),
      );
      Navigator.of(context).pop();
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String? ?? l10n.changePasswordFailure
          : l10n.changePasswordFailure;
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePasswordTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.changePasswordCurrentLabel,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) => (v == null || v.isEmpty) ? l10n.changePasswordCurrentValidator : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.changePasswordNewLabel,
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                ),
                validator: (v) => (v == null || v.length < 8) ? l10n.passwordValidator : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.changePasswordConfirmLabel,
                  prefixIcon: const Icon(Icons.check_circle_outline),
                ),
                validator: (v) => (v != _newController.text) ? l10n.changePasswordMismatchValidator : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              GradientButton(
                label: l10n.changePasswordTitle,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
