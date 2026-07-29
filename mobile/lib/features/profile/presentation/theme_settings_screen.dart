import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_controller.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  String _labelFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'สว่าง (Light Mode)';
      case ThemeMode.dark:
        return 'มืด (Dark Mode)';
      case ThemeMode.system:
        return 'ตามระบบ (System Default)';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('การตั้งค่าธีม')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: RadioGroup<ThemeMode>(
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeControllerProvider.notifier).setThemeMode(value);
              }
            },
            child: Column(
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    title: Text(_labelFor(mode)),
                    value: mode,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
