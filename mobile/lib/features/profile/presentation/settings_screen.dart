import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/settings_list_tile.dart';
import '../../../shared/widgets/settings_section_header.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../safety/presentation/emergency_contact_screen.dart';
import 'about_screen.dart';
import 'change_password_screen.dart';
import 'language_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'theme_settings_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final user = await ref.read(authRepositoryProvider).uploadAvatar(picked.path);
      ref.read(authControllerProvider.notifier).applyUser(user);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).avatarUploadError)),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.pink, AppColors.yellow],
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                        child: _isUploadingAvatar
                            ? const CircularProgressIndicator(color: Colors.white)
                            : user?.avatarUrl == null
                                ? Text(
                                    (user?.displayName.isNotEmpty ?? false) ? user!.displayName.characters.first : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                  )
                                : null,
                      ),
                      if (!_isUploadingAvatar)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppColors.pinkDark, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsSectionHeader(title: l10n.settingsAccountSection, color: AppColors.pink),
                Card(
                  child: Column(
                    children: [
                      SettingsListTile(
                        icon: Icons.lock_outline,
                        title: l10n.settingsChangePassword,
                        subtitle: l10n.settingsChangePasswordSubtitle,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      SettingsListTile(
                        icon: Icons.notifications_none,
                        title: l10n.settingsNotifications,
                        subtitle: l10n.settingsNotificationsSubtitle,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      SettingsListTile(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.settingsPrivacy,
                        subtitle: l10n.settingsPrivacySubtitle,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SettingsSectionHeader(title: l10n.settingsSafetySection, color: AppColors.danger),
                Card(
                  child: SettingsListTile(
                    icon: Icons.contact_phone_outlined,
                    title: l10n.settingsEmergencyContact,
                    subtitle: l10n.settingsEmergencyContactSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EmergencyContactScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SettingsSectionHeader(title: l10n.settingsGeneralSection, color: AppColors.yellow.withValues(alpha: 1)),
                Card(
                  child: Column(
                    children: [
                      SettingsListTile(
                        icon: Icons.info_outline,
                        title: l10n.settingsAbout,
                        subtitle: l10n.settingsAboutSubtitle,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      SettingsListTile(
                        icon: Icons.palette_outlined,
                        title: l10n.settingsTheme,
                        subtitle: l10n.settingsThemeSubtitle,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      SettingsListTile(
                        icon: Icons.language_outlined,
                        title: l10n.settingsLanguage,
                        subtitle: l10n.settingsLanguageSubtitle,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.settingsLogout),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
