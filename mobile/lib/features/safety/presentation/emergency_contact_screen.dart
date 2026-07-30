import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'proximity_alert_controller.dart';

class EmergencyContactScreen extends ConsumerStatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  ConsumerState<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends ConsumerState<EmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final contact = await ref.read(safetyRepositoryProvider).fetchEmergencyContact();
      if (!mounted) return;
      _nameController.text = contact.name ?? '';
      _phoneController.text = contact.phone ?? '';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(safetyRepositoryProvider).updateEmergencyContact(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.emergencyContactSaved)),
      );
      Navigator.of(context).pop();
    } on DioException catch (e) {
      final l10n = AppLocalizations.of(context);
      final message = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String? ?? l10n.emergencyContactSaveFailed
          : l10n.emergencyContactSaveFailed;
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsEmergencyContact)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.emergencyContactExplanation,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.emergencyContactNameLabel,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? l10n.emergencyContactNameValidator : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.emergencyContactPhoneLabel,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().length < 9) ? l10n.emergencyContactPhoneValidator : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    GradientButton(
                      label: l10n.saveLabel,
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
