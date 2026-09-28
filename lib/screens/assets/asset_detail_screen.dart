import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../providers/asset_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/location_provider.dart';
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
  }

  Future<void> _loadAsset() async {
    final asset = await context.read<AssetProvider>().getAssetById(
          widget.assetId,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _asset = asset;
      _isLoading = false;
    });
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

    final success = await provider.deleteAsset(widget.assetId);

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบทรัพย์สินเรียบร้อยแล้ว'),
        ),
      );

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'ไม่สามารถลบทรัพย์สินได้',
          ),
        ),
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
    return _buildImagePlaceholder(context);
  }

  final file = File(imagePath);

  final exists = file.existsSync();

  debugPrint('====================================');
  debugPrint('Asset ID: ${asset.id}');
  debugPrint('Asset Name: ${asset.name}');
  debugPrint('Image Path: $imagePath');
  debugPrint('Image Exists: $exists');
  debugPrint('====================================');

  if (!exists) {
    return _buildImagePlaceholder(
      context,
      message: 'ไม่พบไฟล์รูปภาพ',
    );
  }

  return GestureDetector(
    onTap: () => _openFullImage(imagePath),
    child: SizedBox(
      width: double.infinity,
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint(
                'Image.file error: $error',
              );

              return _buildImagePlaceholder(
                context,
                message: 'ไม่สามารถแสดงรูปภาพได้',
              );
            },
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
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
                      'ดูรูปเต็ม',
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

  Widget _buildImagePlaceholder(
  BuildContext context, {
  String message = 'ไม่มีรูปภาพ',
}) {
  return Container(
    width: double.infinity,
    height: 220,
    color: Theme.of(context)
        .colorScheme
        .surfaceContainerHighest,
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.image_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    ),
  );
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

    if (_asset == null) {
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
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'ไม่พบทรัพย์สิน',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ทรัพย์สินนี้อาจถูกลบไปแล้ว',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('กลับ'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final asset = _asset!;

    final categoryProvider = context.read<CategoryProvider>();
    final locationProvider = context.read<LocationProvider>();
    final assetProvider = context.read<AssetProvider>();

    String categoryName = 'ไม่ระบุ';
    String locationName = 'ไม่ระบุ';

    for (final category in categoryProvider.categories) {
      if (category.id == asset.categoryId) {
        categoryName = category.name;
        break;
      }
    }

    for (final location in locationProvider.locations) {
      if (location.id == asset.locationId) {
        locationName = location.name;
        break;
      }
    }

    final warrantyStatus = assetProvider.getWarrantyStatus(asset);
    final warrantyColor = _warrantyColor(
      context,
      warrantyStatus,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดทรัพย์สิน'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: _buildAssetImage(
              context,
              asset,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            asset.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Chip(
            avatar: const Icon(
              Icons.build_outlined,
              size: 18,
            ),
            label: Text(asset.condition),
          ),

          const SizedBox(height: 24),

          _DetailSection(
            title: 'ข้อมูลทั่วไป',
            children: [
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'หมวดหมู่',
                value: categoryName,
              ),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'สถานที่',
                value: locationName,
              ),
              _DetailRow(
                icon: Icons.payments_outlined,
                label: 'ราคาซื้อ',
                value: _formatPrice(asset.purchasePrice),
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'วันที่ซื้อ',
                value: _formatDate(asset.purchaseDate),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _DetailSection(
            title: 'การรับประกัน',
            children: [
              _DetailRow(
                icon: Icons.verified_outlined,
                label: 'วันหมดประกัน',
                value: _formatDate(asset.warrantyEndDate),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: warrantyColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _warrantyLabel(warrantyStatus),
                      style: TextStyle(
                        color: warrantyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          _DetailSection(
            title: 'ข้อมูลเพิ่มเติม',
            children: [
              _DetailRow(
                icon: Icons.qr_code_2_outlined,
                label: 'Serial Number',
                value: asset.serialNumber ?? 'ไม่ระบุ',
              ),
              _DetailRow(
                icon: Icons.notes_outlined,
                label: 'รายละเอียด',
                value: asset.description ?? 'ไม่มีรายละเอียด',
              ),
            ],
          ),

          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: () async {
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
            icon: const Icon(Icons.edit_outlined),
            label: const Text('แก้ไขทรัพย์สิน'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('ลบทรัพย์สิน'),
          ),

          const SizedBox(height: 24),
        ],
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
            errorBuilder: (context, error, stackTrace) {
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}