import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/settings_list_tile.dart';
import '../../../shared/widgets/settings_section_header.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../safety/presentation/emergency_contact_screen.dart';
import 'about_screen.dart';
import 'change_password_screen.dart';
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
        const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์ไม่สำเร็จ ลองใหม่อีกทีนะ')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('การตั้งค่า')),
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
                SettingsSectionHeader(title: 'การตั้งค่าบัญชี', color: AppColors.pink),
                Card(
                  child: Column(
                    children: [
                      SettingsListTile(
                        icon: Icons.lock_outline,
                        title: 'เปลี่ยนรหัสผ่าน',
                        subtitle: 'อัปเดตรหัสผ่านบัญชีของคุณ',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      SettingsListTile(
                        icon: Icons.notifications_none,
                        title: 'การตั้งค่าการแจ้งเตือน',
                        subtitle: 'จัดการการตั้งค่าการแจ้งเตือน',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      SettingsListTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'การตั้งค่าความเป็นส่วนตัว',
                        subtitle: 'จัดการการตั้งค่าความเป็นส่วนตัว',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SettingsSectionHeader(title: 'ความปลอดภัย', color: AppColors.danger),
                Card(
                  child: SettingsListTile(
                    icon: Icons.contact_phone_outlined,
                    title: 'ผู้ติดต่อฉุกเฉิน',
                    subtitle: 'ตั้งค่าผู้ที่จะได้รับแจ้งเมื่อคุณกด SOS',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EmergencyContactScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SettingsSectionHeader(title: 'การตั้งค่าทั่วไป', color: AppColors.yellow.withValues(alpha: 1)),
                Card(
                  child: Column(
                    children: [
                      SettingsListTile(
                        icon: Icons.info_outline,
                        title: 'เกี่ยวกับเรา',
                        subtitle: 'เรียนรู้เพิ่มเติมเกี่ยวกับเรา',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        ),
                      ),
                      const Divider(height: 1),
                      SettingsListTile(
                        icon: Icons.palette_outlined,
                        title: 'การตั้งค่าธีม',
                        subtitle: 'จัดการการตั้งค่าธีม',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
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
                    label: const Text('ออกจากระบบ'),
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
