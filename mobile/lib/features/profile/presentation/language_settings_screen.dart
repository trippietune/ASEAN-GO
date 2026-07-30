import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../l10n/generated/app_localizations.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  String _labelFor(BuildContext context, Locale? locale) {
    final l10n = AppLocalizations.of(context);
    if (locale == null) return l10n.languageSystemDefault;
    return switch (locale.languageCode) {
      'th' => l10n.languageThai,
      'en' => l10n.languageEnglish,
      _ => locale.languageCode,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeControllerProvider);
    const options = <Locale?>[null, Locale('th'), Locale('en')];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageSettingsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: RadioGroup<Locale?>(
            groupValue: currentLocale,
            onChanged: (value) {
              ref.read(localeControllerProvider.notifier).setLocale(value);
            },
            child: Column(
              children: [
                for (final option in options)
                  RadioListTile<Locale?>(
                    title: Text(_labelFor(context, option)),
                    value: option,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
