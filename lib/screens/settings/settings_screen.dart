import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../categories/category_management_screen.dart';
import '../locations/location_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        children: [
          Text(
            'การตั้งค่า',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.category_outlined,
                  ),
                  title: const Text('จัดการหมวดหมู่'),
                  subtitle: const Text(
                    'เพิ่ม แก้ไข และลบหมวดหมู่ทรัพย์สิน',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const CategoryManagementScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                  ),
                  title: const Text('จัดการสถานที่'),
                  subtitle: const Text(
                    'เพิ่ม แก้ไข และลบสถานที่ภายในบ้าน',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const LocationManagementScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'รูปลักษณ์',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    secondary: Icon(
                      Icons.settings_suggest_outlined,
                    ),
                    title: Text('ตามระบบ'),
                    subtitle: Text(
                      'ใช้ธีมตามการตั้งค่าของอุปกรณ์',
                    ),
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    secondary: Icon(
                      Icons.light_mode_outlined,
                    ),
                    title: Text('สว่าง'),
                    subtitle: Text(
                      'ใช้ธีมสว่างตลอดเวลา',
                    ),
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    secondary: Icon(
                      Icons.dark_mode_outlined,
                    ),
                    title: Text('มืด'),
                    subtitle: Text(
                      'ใช้ธีมมืดตลอดเวลา',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'เกี่ยวกับแอป',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.home_work_outlined,
                  ),
                  title: Text('Home Asset Manager'),
                  subtitle: Text(
                    'แอปจัดการทรัพย์สินภายในบ้าน',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(
                    Icons.info_outline,
                  ),
                  title: Text('เวอร์ชัน'),
                  trailing: Text('1.0.0'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(
                    Icons.code_outlined,
                  ),
                  title: Text('เทคโนโลยี'),
                  subtitle: Text(
                    'Flutter • Dart • Material 3 • Drift • SQLite',
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