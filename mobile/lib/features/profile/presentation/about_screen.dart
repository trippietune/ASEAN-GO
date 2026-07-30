import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: AppLogo(size: 96)),
          const SizedBox(height: 16),
          Text(
            'ASEAN GO',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.pink, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.aboutVersion,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.aboutDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Divider(),
          _AboutLinkTile(icon: Icons.language, label: l10n.aboutWebsiteLabel, value: 'aseango.example.com'),
          _AboutLinkTile(icon: Icons.email_outlined, label: l10n.aboutContactEmailLabel, value: 'support@aseango.example.com'),
          _AboutLinkTile(icon: Icons.description_outlined, label: l10n.aboutPrivacyPolicyLabel, value: 'aseango.example.com/privacy'),
        ],
      ),
    );
  }
}

class _AboutLinkTile extends StatelessWidget {
  const _AboutLinkTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.pink),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
