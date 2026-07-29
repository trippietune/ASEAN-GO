import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เกี่ยวกับเรา')),
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
            'เวอร์ชัน 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Text(
            'ASEAN GO คือผู้คุ้มกันดิจิทัลและไกด์นำเที่ยวส่วนตัวของคุณในภูมิภาคอาเซียน '
            'ช่วยให้การเดินทางปลอดภัยยิ่งขึ้นด้วยจุดที่ผ่านการยืนยัน ระบบแจ้งเตือนความเสี่ยง '
            'และภารกิจที่ทำให้การท่องเที่ยวสนุกยิ่งขึ้น',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const _AboutLinkTile(icon: Icons.language, label: 'เว็บไซต์', value: 'aseango.example.com'),
          const _AboutLinkTile(icon: Icons.email_outlined, label: 'อีเมลติดต่อ', value: 'support@aseango.example.com'),
          const _AboutLinkTile(icon: Icons.description_outlined, label: 'นโยบายความเป็นส่วนตัว', value: 'aseango.example.com/privacy'),
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
