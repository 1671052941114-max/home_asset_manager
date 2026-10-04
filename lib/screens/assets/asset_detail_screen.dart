import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/warranty_utils.dart';
import '../../data/database/app_database.dart';
import '../../providers/asset_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../qr/asset_qr_screen.dart';
import 'asset_form_screen.dart';

class AssetDetailScreen extends StatefulWidget {
  const AssetDetailScreen({
    super.key,
    required this.assetId,
  });

  final int assetId;

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  Asset? _asset;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadAsset();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<MaintenanceProvider>().loadRecords(
            widget.assetId,
          );
    });
  }

  Future<void> _showMaintenanceDialog({
    MaintenanceRecord? record,
  }) async {
    final isEditing = record != null;

    final result = await showDialog<_MaintenanceFormResult>(
      context: context,
      builder: (dialogContext) {
        return _MaintenanceDialog(
          isEditing: isEditing,
          record: record,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    final provider = context.read<MaintenanceProvider>();

    final success = isEditing
        ? await provider.updateRecord(
            assetId: widget.assetId,
            recordId: record.id,
            date: result.date,
            type: result.type,
            description: result.description,
            cost: result.cost,
            note: result.note,
          )
        : await provider.addRecord(
            assetId: widget.assetId,
            date: result.date,
            type: result.type,
            description: result.description,
            cost: result.cost,
            note: result.note,
          );

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? isEditing
              ? 'แก้ไขประวัติการซ่อมเรียบร้อยแล้ว'
              : 'เพิ่มประวัติการซ่อมเรียบร้อยแล้ว'
          : provider.errorMessage ?? 'ไม่สามารถดำเนินการได้',
    );
  }

  Future<void> _confirmDeleteMaintenance(
    MaintenanceRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบประวัติการซ่อม'),
          content: Text(
            'คุณต้องการลบประวัติ "${record.type}" หรือไม่?',
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
                backgroundColor:
                    Theme.of(context).colorScheme.error,
                foregroundColor:
                    Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<MaintenanceProvider>();

    final success = await provider.deleteRecord(
      assetId: widget.assetId,
      recordId: record.id,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'ลบประวัติการซ่อมเรียบร้อยแล้ว'
          : provider.errorMessage ??
              'ไม่สามารถลบประวัติการซ่อมได้',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _loadAsset() async {
    try {
      final asset =
          await context.read<AssetProvider>().getAssetById(
                widget.assetId,
              );

      if (!mounted) {
        return;
      }

      setState(() {
        _asset = asset;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _asset = null;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'ไม่ระบุ';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(2)} บาท';
  }

  String _warrantyLabel(String status) {
    switch (status) {
      case 'active':
        return 'อยู่ในประกัน';
      case 'expiringSoon':
        return 'ประกันใกล้หมด';
      case 'expired':
        return 'หมดประกันแล้ว';
      default:
        return 'ไม่ระบุวันหมดประกัน';
    }
  }

  Color _warrantyColor(
    BuildContext context,
    String status,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case 'active':
        return Colors.green;
      case 'expiringSoon':
        return Colors.orange;
      case 'expired':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  Future<void> _toggleFavorite() async {
    final asset = _asset;

    if (asset == null) {
      return;
    }

    final assetProvider = context.read<AssetProvider>();
    final wasFavorite = asset.isFavorite;

    final success = await assetProvider.toggleFavorite(
      asset.id,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        assetProvider.errorMessage ??
            'ไม่สามารถเปลี่ยนสถานะรายการโปรดได้',
      );
      return;
    }

    await _loadAsset();

    if (!mounted) {
      return;
    }

    _showMessage(
      wasFavorite
          ? 'นำออกจากรายการโปรดแล้ว'
          : 'เพิ่มในรายการโปรดแล้ว',
    );
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบทรัพย์สิน'),
          content: const Text(
            'คุณต้องการลบทรัพย์สินรายการนี้ใช่หรือไม่?\n'
            'การลบข้อมูลไม่สามารถย้อนกลับได้',
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
                backgroundColor:
                    Theme.of(context).colorScheme.error,
                foregroundColor:
                    Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final provider = context.read<AssetProvider>();

    final success = await provider.deleteAsset(
      widget.assetId,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage('ลบทรัพย์สินเรียบร้อยแล้ว');
      Navigator.of(context).pop();
    } else {
      _showMessage(
        provider.errorMessage ??
            'ไม่สามารถลบทรัพย์สินได้',
      );
    }
  }

  void _openFullImage(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenImageScreen(
          imagePath: imagePath,
          assetName: _asset?.name ?? 'รูปทรัพย์สิน',
        ),
      ),
    );
  }

  Widget _buildAssetImage(
    BuildContext context,
    Asset asset,
  ) {
    final imagePath = asset.imagePath;

    if (imagePath == null || imagePath.isEmpty) {
      return const _ImagePlaceholder();
    }

    final file = File(imagePath);

    if (!file.existsSync()) {
      return const _ImagePlaceholder(
        message: 'ไม่พบไฟล์รูปภาพ',
      );
    }

    return GestureDetector(
      onTap: () => _openFullImage(imagePath),
      child: SizedBox(
        width: double.infinity,
        height: 260,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const _ImagePlaceholder(
                  message: 'ไม่สามารถแสดงรูปภาพได้',
                );
              },
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'แตะเพื่อดูรูปเต็ม',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Asset asset,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                asset.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: asset.isFavorite
                  ? 'นำออกจากรายการโปรด'
                  : 'เพิ่มในรายการโปรด',
              onPressed: _toggleFavorite,
              icon: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 200,
                ),
                transitionBuilder: (
                  child,
                  animation,
                ) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  asset.isFavorite
                      ? Icons.star
                      : Icons.star_border,
                  key: ValueKey(asset.isFavorite),
                  color: asset.isFavorite
                      ? colorScheme.primary
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.build_outlined,
              label: asset.condition,
            ),
            _InfoChip(
              icon: Icons.category_outlined,
              label: _findCategoryName(asset),
            ),
            _InfoChip(
              icon: Icons.location_on_outlined,
              label: _findLocationName(asset),
            ),
          ],
        ),
      ],
    );
  }

  String _findCategoryName(Asset asset) {
    final provider = context.read<CategoryProvider>();

    for (final category in provider.categories) {
      if (category.id == asset.categoryId) {
        return category.name;
      }
    }

    return 'ไม่ระบุ';
  }

  String _findLocationName(Asset asset) {
    final provider = context.read<LocationProvider>();

    for (final location in provider.locations) {
      if (location.id == asset.locationId) {
        return location.name;
      }
    }

    return 'ไม่ระบุ';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('รายละเอียดทรัพย์สิน'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final asset = _asset;

    if (asset == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('รายละเอียดทรัพย์สิน'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบข้อมูลทรัพย์สิน',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('ย้อนกลับ'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final assetProvider = context.read<AssetProvider>();

    final warrantyStatus =
        assetProvider.getWarrantyStatus(asset);

    final warrantyColor = _warrantyColor(
      context,
      warrantyStatus,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดทรัพย์สิน'),
        actions: [
          IconButton(
            tooltip: 'QR Code',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AssetQrScreen(
                    assetId: asset.id,
                    assetName: asset.name,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.qr_code_2_outlined,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'ตัวเลือก',
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AssetFormScreen(
                        assetId: widget.assetId,
                      ),
                    ),
                  );

                  if (mounted) {
                    await _loadAsset();
                  }

                case 'delete':
                  await _confirmDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('แก้ไข'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('ลบ'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32,
        ),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: _buildAssetImage(
              context,
              asset,
            ),
          ),

          const SizedBox(height: 20),

          _buildHeader(
            context,
            asset,
          ),

          const SizedBox(height: 24),

          _DetailSection(
            icon: Icons.inventory_2_outlined,
            title: 'ข้อมูลทรัพย์สิน',
            children: [
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'หมวดหมู่',
                value: _findCategoryName(asset),
              ),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'สถานที่',
                value: _findLocationName(asset),
              ),
              _DetailRow(
                icon: Icons.payments_outlined,
                label: 'ราคาซื้อ',
                value: _formatPrice(
                  asset.purchasePrice,
                ),
                valueStyle: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'วันที่ซื้อ',
                value: _formatDate(
                  asset.purchaseDate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _DetailSection(
            icon: Icons.shield_outlined,
            title: 'การรับประกัน',
            children: [
              _WarrantyStatusCard(
                warrantyEndDate: asset.warrantyEndDate,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.event_outlined,
                label: 'วันหมดประกัน',
                value: _formatDate(
                  asset.warrantyEndDate,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: warrantyColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _warrantyLabel(warrantyStatus),
                    style: TextStyle(
                      color: warrantyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          _DetailSection(
            icon: Icons.description_outlined,
            title: 'รายละเอียดเพิ่มเติม',
            children: [
              _DetailRow(
                icon: Icons.qr_code_2_outlined,
                label: 'Serial Number',
                value: asset.serialNumber ?? 'ไม่ระบุ',
              ),
              _DetailRow(
                icon: Icons.notes_outlined,
                label: 'รายละเอียด',
                value: asset.description ??
                    'ไม่มีรายละเอียด',
              ),
            ],
          ),

          const SizedBox(height: 24),

          _MaintenanceSection(
            onAdd: () => _showMaintenanceDialog(),
            onEdit: (record) => _showMaintenanceDialog(
              record: record,
            ),
            onDelete: _confirmDeleteMaintenance,
            formatDate: _formatDate,
            formatPrice: _formatPrice,
          ),

          const SizedBox(height: 24),

          _ActionSection(
            onEdit: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AssetFormScreen(
                    assetId: widget.assetId,
                  ),
                ),
              );

              if (!mounted) {
                return;
              }

              await _loadAsset();
            },
            onQr: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AssetQrScreen(
                    assetId: asset.id,
                    assetName: asset.name,
                  ),
                ),
              );
            },
            onDelete: _confirmDelete,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 17,
      ),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 21,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyStatusCard extends StatelessWidget {
  const _WarrantyStatusCard({
    required this.warrantyEndDate,
  });

  final DateTime? warrantyEndDate;

  @override
  Widget build(BuildContext context) {
    final status = WarrantyUtils.getStatus(
      warrantyEndDate,
    );

    final remainingDays =
        WarrantyUtils.getRemainingDays(
      warrantyEndDate,
    );

    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color color;
    String title;
    String description;

    switch (status) {
      case WarrantyStatus.noWarranty:
        icon = Icons.shield_outlined;
        color = colorScheme.outline;
        title = 'ไม่มีข้อมูลประกัน';
        description = 'ยังไม่ได้ระบุวันหมดประกัน';

      case WarrantyStatus.active:
        icon = Icons.verified_outlined;
        color = colorScheme.primary;
        title = 'อยู่ในระยะประกัน';
        description = 'เหลืออีก $remainingDays วัน';

      case WarrantyStatus.expiringSoon:
        icon = Icons.warning_amber_rounded;
        color = colorScheme.tertiary;
        title = 'ประกันใกล้หมด';
        description = 'เหลืออีก $remainingDays วัน';

      case WarrantyStatus.expired:
        icon = Icons.gpp_bad_outlined;
        color = colorScheme.error;
        title = 'หมดประกันแล้ว';
        description = 'สิ้นสุดประกันแล้ว';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor:
                color.withValues(alpha: 0.14),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(description),
                if (warrantyEndDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'สิ้นสุดวันที่ ${_formatDate(warrantyEndDate!)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

class _MaintenanceSection extends StatelessWidget {
  const _MaintenanceSection({
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.formatDate,
    required this.formatPrice,
  });

  final VoidCallback onAdd;
  final ValueChanged<MaintenanceRecord> onEdit;
  final ValueChanged<MaintenanceRecord> onDelete;
  final String Function(DateTime?) formatDate;
  final String Function(double) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, child) {
        final colorScheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 21,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ประวัติการซ่อม',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: provider.isSaving
                      ? null
                      : onAdd,
                  icon: const Icon(
                    Icons.add,
                    size: 19,
                  ),
                  label: const Text('เพิ่ม'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            color: colorScheme
                                .onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ค่าใช้จ่ายซ่อมทั้งหมด',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme
                                            .onPrimaryContainer,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  formatPrice(
                                    provider.totalCost,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight:
                                            FontWeight.bold,
                                        color: colorScheme
                                            .onPrimaryContainer,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      )
                    else if (provider.errorMessage != null)
                      _MaintenanceError(
                        message:
                            provider.errorMessage!,
                      )
                    else if (provider.records.isEmpty)
                      _MaintenanceEmpty()
                    else
                      Column(
                        children: [
                          for (int index = 0;
                              index <
                                  provider.records.length;
                              index++)
                            _MaintenanceItem(
                              record:
                                  provider.records[index],
                              isLast: index ==
                                  provider.records.length -
                                      1,
                              onEdit: onEdit,
                              onDelete: onDelete,
                              formatDate: formatDate,
                              formatPrice: formatPrice,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MaintenanceItem extends StatelessWidget {
  const _MaintenanceItem({
    required this.record,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    required this.formatDate,
    required this.formatPrice,
  });

  final MaintenanceRecord record;
  final bool isLast;
  final ValueChanged<MaintenanceRecord> onEdit;
  final ValueChanged<MaintenanceRecord> onDelete;
  final String Function(DateTime?) formatDate;
  final String Function(double) formatPrice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            record.type,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(),
                          tooltip: 'ตัวเลือก',
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                onEdit(record);
                              case 'delete':
                                onDelete(record);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('แก้ไข'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('ลบ'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      formatDate(record.date),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatPrice(record.cost),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (record.description != null &&
                        record.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        record.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceEmpty extends StatelessWidget {
  const _MaintenanceEmpty();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: Column(
        children: [
          Icon(
            Icons.build_circle_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 10),
          Text(
            'ยังไม่มีประวัติการซ่อม',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'กดปุ่ม "เพิ่ม" เพื่อบันทึกรายการซ่อม',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceError extends StatelessWidget {
  const _MaintenanceError({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.onEdit,
    required this.onQr,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onQr;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'จัดการทรัพย์สิน',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label: const Text(
                  'แก้ไขทรัพย์สิน',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onQr,
                icon: const Icon(
                  Icons.qr_code_2_outlined,
                ),
                label: const Text(
                  'ดู QR Code ทรัพย์สิน',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(
                    color: colorScheme.error,
                  ),
                ),
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                ),
                label: const Text(
                  'ลบทรัพย์สิน',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    this.message = 'ไม่มีรูปภาพ',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 260,
      child: Container(
        color: colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImageScreen extends StatelessWidget {
  const _FullScreenImageScreen({
    required this.imagePath,
    required this.assetName,
  });

  final String imagePath;
  final String assetName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(assetName),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'ไม่สามารถเปิดรูปภาพได้',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MaintenanceDialog extends StatefulWidget {
  const _MaintenanceDialog({
    required this.isEditing,
    required this.record,
  });

  final bool isEditing;
  final MaintenanceRecord? record;

  @override
  State<_MaintenanceDialog> createState() =>
      _MaintenanceDialogState();
}

class _MaintenanceDialogState
    extends State<_MaintenanceDialog> {
  late final TextEditingController _typeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _costController;
  late final TextEditingController _noteController;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    _selectedDate = record?.date ?? DateTime.now();

    _typeController = TextEditingController(
      text: record?.type ?? '',
    );

    _descriptionController = TextEditingController(
      text: record?.description ?? '',
    );

    _costController = TextEditingController(
      text: record?.cost.toStringAsFixed(2) ?? '',
    );

    _noteController = TextEditingController(
      text: record?.note ?? '',
    );
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'เลือกวันที่ซ่อม',
      cancelText: 'ยกเลิก',
      confirmText: 'เลือก',
    );

    if (!mounted || pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _submit() {
    final type = _typeController.text.trim();

    if (type.isEmpty) {
      _showError('กรุณาระบุประเภทการซ่อม');
      return;
    }

    final cost = double.tryParse(
      _costController.text.trim(),
    );

    if (cost == null || cost < 0) {
      _showError(
        'กรุณาระบุค่าใช้จ่ายให้ถูกต้อง',
      );
      return;
    }

    final description =
        _descriptionController.text.trim();

    final note = _noteController.text.trim();

    Navigator.of(context).pop(
      _MaintenanceFormResult(
        date: _selectedDate,
        type: type,
        description:
            description.isEmpty ? null : description,
        cost: cost,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEditing
            ? 'แก้ไขประวัติการซ่อม'
            : 'เพิ่มประวัติการซ่อม',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _typeController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'ประเภทการซ่อม',
                hintText: 'เช่น เปลี่ยนอะไหล่',
                prefixIcon: Icon(
                  Icons.build_outlined,
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'วันที่ซ่อม',
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                  ),
                ),
                child: Text(
                  _formatDate(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction:
                  TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'ค่าใช้จ่าย',
                hintText: '0.00',
                prefixIcon: Icon(
                  Icons.payments_outlined,
                ),
                suffixText: 'บาท',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              textInputAction:
                  TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                hintText: 'รายละเอียดการซ่อม',
                prefixIcon: Icon(
                  Icons.description_outlined,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'หมายเหตุ',
                hintText: 'หมายเหตุเพิ่มเติม',
                prefixIcon: Icon(
                  Icons.notes_outlined,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.isEditing
                ? 'บันทึก'
                : 'เพิ่ม',
          ),
        ),
      ],
    );
  }
}

class _MaintenanceFormResult {
  const _MaintenanceFormResult({
    required this.date,
    required this.type,
    required this.description,
    required this.cost,
    required this.note,
  });

  final DateTime date;
  final String type;
  final String? description;
  final double cost;
  final String? note;
}