import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/database/app_database_provider.dart';
import '../../providers/asset_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/backup_service.dart';
import '../../services/notification_service.dart';
import '../categories/category_management_screen.dart';
import '../locations/location_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isRestoring = false;

  Future<void> _testNotification(BuildContext context) async {
    try {
      await NotificationService.instance.showTestNotification();

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'ส่งการแจ้งเตือนทดสอบแล้ว',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'ไม่สามารถส่งการแจ้งเตือนได้: $error',
        isError: true,
      );
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final databaseProvider =
          context.read<AppDatabaseProvider>();

      final backupService = BackupService(
        databaseProvider.database,
      );

      final savedUri = await backupService.exportBackup();

      if (!context.mounted || savedUri == null) {
        return;
      }

      _showMessage(
        context,
        'ส่งออกข้อมูลสำรองเรียบร้อยแล้ว',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'ไม่สามารถส่งออกข้อมูลสำรองได้: $error',
        isError: true,
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final databaseProvider =
          context.read<AppDatabaseProvider>();

      final backupService = BackupService(
        databaseProvider.database,
      );

      final preview = await backupService.pickBackupFile();

      if (!context.mounted || preview == null) {
        return;
      }

      final confirmed = await _showRestorePreview(
        context,
        preview,
      );

      if (!context.mounted || confirmed != true) {
        return;
      }

      setState(() {
        _isRestoring = true;
      });

      await backupService.restoreBackup(
        preview.data,
      );

      if (!context.mounted) {
        return;
      }

      await Future.wait([
        context.read<AssetProvider>().loadAssets(),
        context.read<CategoryProvider>().loadCategories(),
        context.read<LocationProvider>().loadLocations(),
      ]);

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'กู้คืนข้อมูลเรียบร้อยแล้ว',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'ไม่สามารถกู้คืนข้อมูลได้: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  Future<bool?> _showRestorePreview(
    BuildContext context,
    BackupPreview preview,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.restore_rounded,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('ตรวจสอบข้อมูลสำรอง'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file_outlined,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          preview.fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ข้อมูลที่จะกู้คืน',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                _PreviewRow(
                  icon: Icons.category_outlined,
                  label: 'หมวดหมู่',
                  value: preview.categoryCount,
                ),
                _PreviewRow(
                  icon: Icons.location_on_outlined,
                  label: 'สถานที่',
                  value: preview.locationCount,
                ),
                _PreviewRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'ทรัพย์สิน',
                  value: preview.assetCount,
                ),
                _PreviewRow(
                  icon: Icons.build_outlined,
                  label: 'ประวัติการซ่อม',
                  value: preview.maintenanceCount,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'การกู้คืนจะลบข้อมูลปัจจุบันในแอป '
                          'และแทนที่ด้วยข้อมูลจากไฟล์นี้',
                          style: TextStyle(
                            color:
                                colorScheme.onErrorContainer,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('กู้คืนข้อมูล'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCategoryManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const CategoryManagementScreen(),
      ),
    );
  }

  Future<void> _openLocationManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const LocationManagementScreen(),
      ),
    );
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? colorScheme.error : null,
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: isError
                    ? colorScheme.onError
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ตั้งค่า',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          110,
        ),
        children: [
          _SettingsHeader(
            onThemeTap: () {
              _showThemeDialog(
                context,
                themeProvider,
              );
            },
          ),

          const SizedBox(height: 24),

          const _SettingsSectionTitle(
            title: 'จัดการข้อมูล',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 12),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.category_outlined,
                iconColor: colorScheme.primary,
                title: 'จัดการหมวดหมู่',
                subtitle:
                    'เพิ่ม แก้ไข และลบหมวดหมู่ทรัพย์สิน',
                onTap: _openCategoryManagement,
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.location_on_outlined,
                iconColor: colorScheme.secondary,
                title: 'จัดการสถานที่',
                subtitle:
                    'เพิ่ม แก้ไข และลบสถานที่ภายในบ้าน',
                onTap: _openLocationManagement,
              ),
            ],
          ),

          const SizedBox(height: 24),

          const _SettingsSectionTitle(
            title: 'รูปลักษณ์',
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 12),

          _ThemeCard(
            themeProvider: themeProvider,
          ),

          const SizedBox(height: 24),

          const _SettingsSectionTitle(
            title: 'การแจ้งเตือน',
            icon: Icons.notifications_outlined,
          ),
          const SizedBox(height: 12),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.notifications_active_outlined,
                iconColor: colorScheme.tertiary,
                title: 'ทดสอบการแจ้งเตือน',
                subtitle:
                    'ตรวจสอบว่าอุปกรณ์สามารถแสดงการแจ้งเตือนได้',
                trailing: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => _testNotification(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const _SettingsSectionTitle(
            title: 'ข้อมูลและการสำรองข้อมูล',
            icon: Icons.cloud_sync_outlined,
          ),
          const SizedBox(height: 12),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.upload_file_outlined,
                iconColor: colorScheme.primary,
                title: 'สำรองข้อมูล',
                subtitle:
                    'ส่งออกข้อมูลทรัพย์สินเป็นไฟล์ JSON',
                trailing: _isRestoring
                    ? null
                    : const Icon(
                        Icons.chevron_right_rounded,
                      ),
                onTap: _isRestoring
                    ? null
                    : () => _exportBackup(context),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: _isRestoring
                    ? null
                    : Icons.file_download_outlined,
                iconColor: colorScheme.error,
                customIcon: _isRestoring
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      )
                    : null,
                title: 'กู้คืนข้อมูล',
                subtitle: _isRestoring
                    ? 'กำลังกู้คืนข้อมูล...'
                    : 'นำเข้าข้อมูลจากไฟล์สำรอง',
                trailing: _isRestoring
                    ? null
                    : const Icon(
                        Icons.chevron_right_rounded,
                      ),
                onTap: _isRestoring
                    ? null
                    : () => _importBackup(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const _SettingsSectionTitle(
            title: 'เกี่ยวกับแอป',
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 12),

          _AboutAppCard(),

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Text(
                  'Home Asset Manager',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'จัดการทรัพย์สินภายในบ้านอย่างเป็นระบบ',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('เลือกรูปลักษณ์'),
          content: RadioGroup<ThemeMode>(
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value == null) {
                return;
              }

              themeProvider.setThemeMode(value);
              Navigator.of(dialogContext).pop();
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
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
        );
      },
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.onThemeTap,
  });

  final VoidCallback onThemeTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(
              alpha: 0.18,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withValues(
                  alpha: 0.07,
                ),
              ),
            ),
          ),
          Positioned(
            right: 45,
            bottom: -65,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withValues(
                  alpha: 0.06,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(
                      alpha: 0.14,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    size: 32,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ตั้งค่าแอปของคุณ',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color:
                                  colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ปรับแต่งการใช้งานให้เหมาะกับคุณ',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: colorScheme.onPrimary
                                  .withValues(alpha: 0.82),
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'เลือกรูปลักษณ์',
                  onPressed: onThemeTap,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        colorScheme.onPrimary.withValues(
                      alpha: 0.10,
                    ),
                  ),
                  icon: Icon(
                    Icons.palette_outlined,
                    color: colorScheme.onPrimary,
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

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 19,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 72,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.iconColor,
    this.icon,
    this.customIcon,
    this.trailing,
  });

  final IconData? icon;
  final Widget? customIcon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final iconWidget = customIcon ??
        (icon == null
            ? const SizedBox(
                width: 26,
                height: 26,
              )
            : Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ));

    return ListTile(
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      leading: iconWidget,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: trailing ??
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      onTap: onTap,
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.themeProvider,
  });

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final currentTheme = themeProvider.themeMode;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showThemeDialog(
            context,
            themeProvider,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _themeIcon(currentTheme),
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ธีมแอป',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _themeLabel(currentTheme),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.settings_suggest_outlined;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'ตามระบบ';
      case ThemeMode.light:
        return 'สว่าง';
      case ThemeMode.dark:
        return 'มืด';
    }
  }

  void _showThemeDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('เลือกรูปลักษณ์'),
          content: RadioGroup<ThemeMode>(
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value == null) {
                return;
              }

              themeProvider.setThemeMode(value);
              Navigator.of(dialogContext).pop();
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
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
        );
      },
    );
  }
}

class _AboutAppCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Icon(
                    Icons.home_work_rounded,
                    size: 34,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home Asset Manager',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'แอปจัดการทรัพย์สินภายในบ้าน',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const _AboutRow(
            icon: Icons.new_releases_outlined,
            title: 'เวอร์ชัน',
            value: '1.0.0',
          ),
          const Divider(
            height: 1,
            indent: 64,
          ),
          const _AboutRow(
            icon: Icons.code_outlined,
            title: 'เทคโนโลยี',
            value: 'Flutter • Dart • Material 3',
          ),
          const Divider(
            height: 1,
            indent: 64,
          ),
          const _AboutRow(
            icon: Icons.storage_outlined,
            title: 'ฐานข้อมูล',
            value: 'Drift • SQLite',
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label),
          ),
          Text(
            '$value รายการ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}