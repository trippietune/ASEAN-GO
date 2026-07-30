import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../data/settings_model.dart';
import 'settings_controller.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  PrivacySettings? _draft;
  bool _isSaving = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    await ref.read(privacySettingsProvider.notifier).save(draft);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsSavedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(privacySettingsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacy)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.settingsLoadError(err.toString()))),
        data: (settings) {
          _draft ??= settings;
          final draft = _draft!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(l10n.privacySettingsShowProfileLabel),
                        value: draft.showProfileToOthers,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(showProfileToOthers: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(l10n.privacySettingsShowCheckinsLabel),
                        value: draft.showCheckins,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(showCheckins: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(l10n.privacySettingsShowReviewsLabel),
                        value: draft.showReviews,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(showReviews: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(l10n.privacySettingsAllowDataCollectionLabel),
                        value: draft.allowDataCollection,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(allowDataCollection: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(label: l10n.saveLabel, isLoading: _isSaving, onPressed: _isSaving ? null : _save),
              ],
            ),
          );
        },
      ),
    );
  }
}
