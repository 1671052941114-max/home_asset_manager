import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/asset_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assetProvider = context.watch<AssetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: RefreshIndicator(
        onRefresh: assetProvider.loadAssets,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'ภาพรวมทรัพย์สิน',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _StatisticCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'ทรัพย์สินทั้งหมด',
                    value: '${assetProvider.totalAssets}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatisticCard(
                    icon: Icons.payments_outlined,
                    title: 'มูลค่ารวม',
                    value: _formatPrice(assetProvider.totalValue),
                    suffix: 'บาท',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatisticCard(
                    icon: Icons.verified_outlined,
                    title: 'ประกันใช้งาน',
                    value: '${assetProvider.activeWarrantyCount}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatisticCard(
                    icon: Icons.warning_amber_outlined,
                    title: 'ใกล้หมดประกัน',
                    value: '${assetProvider.expiringWarrantyCount}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _StatisticCard(
              icon: Icons.error_outline,
              title: 'หมดประกันแล้ว',
              value: '${assetProvider.expiredWarrantyCount}',
            ),

            const SizedBox(height: 24),

            Text(
              'สถานะประกัน',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _WarrantyRow(
                      icon: Icons.verified_outlined,
                      label: 'ยังมีประกัน',
                      value: assetProvider.activeWarrantyCount,
                    ),
                    const Divider(height: 24),
                    _WarrantyRow(
                      icon: Icons.warning_amber_outlined,
                      label: 'ใกล้หมดประกัน',
                      value: assetProvider.expiringWarrantyCount,
                    ),
                    const Divider(height: 24),
                    _WarrantyRow(
                      icon: Icons.error_outline,
                      label: 'หมดประกันแล้ว',
                      value: assetProvider.expiredWarrantyCount,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'ทรัพย์สินล่าสุด',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            if (assetProvider.assets.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'ยังไม่มีข้อมูลทรัพย์สิน',
                    ),
                  ),
                ),
              )
            else
              ...assetProvider.assets.take(5).map(
  (asset) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      leading: _StatisticAssetImage(
        imagePath: asset.imagePath,
      ),
      title: Text(
        asset.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'มูลค่า ${_formatPrice(asset.purchasePrice)} บาท',
      ),
      trailing: Text(
        asset.condition,
      ),
    ),
  ),
),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(double price) {
    return price
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}
class _StatisticAssetImage extends StatelessWidget {
  const _StatisticAssetImage({
    required this.imagePath,
  });

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;

    if (path == null || path.isEmpty) {
      return const _StatisticImagePlaceholder();
    }

    return SizedBox(
      width: 52,
      height: 52,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              'Statistics Asset Image Error: $error',
            );

            return const _StatisticImagePlaceholder();
          },
        ),
      ),
    );
  }
}

class _StatisticImagePlaceholder extends StatelessWidget {
  const _StatisticImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        color: colorScheme.outline,
      ),
    );
  }
}
class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
    this.suffix,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (suffix != null)
              Text(
                suffix!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _WarrantyRow extends StatelessWidget {
  const _WarrantyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label),
        ),
        Text(
          '$value รายการ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}