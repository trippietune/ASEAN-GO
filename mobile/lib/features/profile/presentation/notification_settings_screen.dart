import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    setState(() => _isSaving = true);
    await ref.read(notificationSettingsProvider.notifier).save(draft);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกการตั้งค่าแล้ว')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('การตั้งค่าการแจ้งเตือน')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('ไม่สามารถโหลดการตั้งค่าได้\n$err')),
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
                        title: const Text('การแจ้งเตือนแบบ Push'),
                        value: draft.pushNotifications,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(pushNotifications: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('การแจ้งเตือนทางอีเมล'),
                        value: draft.emailNotifications,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(emailNotifications: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('การแจ้งเตือนด้านความปลอดภัย'),
                        value: draft.safetyAlerts,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(safetyAlerts: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('การเตือนภารกิจ'),
                        value: draft.questReminders,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(questReminders: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('โปรโมชั่นและข้อเสนอ'),
                        value: draft.promotions,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(promotions: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(label: 'บันทึก', isLoading: _isSaving, onPressed: _isSaving ? null : _save),
              ],
            ),
          );
        },
      ),
    );
  }
}
