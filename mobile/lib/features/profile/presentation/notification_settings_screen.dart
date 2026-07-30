import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../data/settings_model.dart';
import 'settings_controller.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  NotificationSettings? _draft;
  bool _isSaving = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    await ref.read(notificationSettingsProvider.notifier).save(draft);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsSavedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotifications)),
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
                        title: Text(l10n.notificationSettingsPushLabel),
                        value: draft.pushNotifications,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(pushNotifications: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(l10n.notificationSettingsEmailLabel),
                        value: draft.emailNotifications,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(emailNotifications: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(l10n.notificationSettingsSafetyLabel),
                        value: draft.safetyAlerts,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(safetyAlerts: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(l10n.notificationSettingsQuestLabel),
                        value: draft.questReminders,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(questReminders: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(l10n.notificationSettingsPromotionsLabel),
                        value: draft.promotions,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(promotions: v)),
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
