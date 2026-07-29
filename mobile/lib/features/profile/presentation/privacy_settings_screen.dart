import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    setState(() => _isSaving = true);
    await ref.read(privacySettingsProvider.notifier).save(draft);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกการตั้งค่าแล้ว')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(privacySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('การตั้งค่าความเป็นส่วนตัว')),
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
                        title: const Text('แสดงโปรไฟล์ให้ผู้อื่นเห็น'),
                        value: draft.showProfileToOthers,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(showProfileToOthers: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('แสดงประวัติการเช็คอิน'),
                        value: draft.showCheckins,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(showCheckins: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('แสดงรีวิวที่เขียน'),
                        value: draft.showReviews,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(showReviews: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('อนุญาตให้เก็บข้อมูลการใช้งาน'),
                        value: draft.allowDataCollection,
                        onChanged: (v) => setState(() => _draft = draft.copyWith(allowDataCollection: v)),
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
