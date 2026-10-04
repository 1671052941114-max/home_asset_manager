import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/asset_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assetProvider = context.watch<AssetProvider>();

    final totalWarranty =
        assetProvider.activeWarrantyCount +
        assetProvider.expiringWarrantyCount +
        assetProvider.expiredWarrantyCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('สถิติทรัพย์สิน'),
      ),
      body: RefreshIndicator(
        onRefresh: assetProvider.loadAssets,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _buildHeader(
              context,
              totalAssets: assetProvider.totalAssets,
              totalValue: assetProvider.totalValue,
            ),

            const SizedBox(height: 20),

            _buildSummaryGrid(
              context,
              assetProvider,
            ),

            const SizedBox(height: 28),

            _buildSectionTitle(
              context,
              title: 'สถานะการรับประกัน',
              icon: Icons.shield_outlined,
            ),

            const SizedBox(height: 12),

            _WarrantyOverviewCard(
              activeCount: assetProvider.activeWarrantyCount,
              expiringCount: assetProvider.expiringWarrantyCount,
              expiredCount: assetProvider.expiredWarrantyCount,
              totalCount: totalWarranty,
            ),

            const SizedBox(height: 28),

            _buildSectionTitle(
              context,
              title: 'ทรัพย์สินล่าสุด',
              icon: Icons.history,
            ),

            const SizedBox(height: 12),

            if (assetProvider.assets.isEmpty)
              const _EmptyStatisticsView()
            else
              ...assetProvider.assets.take(5).map(
                (asset) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RecentAssetCard(
                    name: asset.name,
                    purchasePrice: asset.purchasePrice,
                    condition: asset.condition,
                    imagePath: asset.imagePath,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required int totalAssets,
    required double totalValue,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ภาพรวมทรัพย์สิน',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalAssets รายการ • มูลค่ารวม ${_formatPrice(totalValue)} บาท',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    AssetProvider provider,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatisticCard(
                icon: Icons.inventory_2_outlined,
                title: 'ทรัพย์สินทั้งหมด',
                value: '${provider.totalAssets}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatisticCard(
                icon: Icons.payments_outlined,
                title: 'มูลค่ารวม',
                value: _formatPrice(provider.totalValue),
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
                value: '${provider.activeWarrantyCount}',
                accentColor: AppStatisticsColors.success(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatisticCard(
                icon: Icons.warning_amber_outlined,
                title: 'ใกล้หมดประกัน',
                value: '${provider.expiringWarrantyCount}',
                accentColor: AppStatisticsColors.warning(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatisticCard(
          icon: Icons.error_outline,
          title: 'หมดประกันแล้ว',
          value: '${provider.expiredWarrantyCount}',
          accentColor: AppStatisticsColors.error(context),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
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

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
    this.suffix,
    this.accentColor,
    this.fullWidth = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? suffix;
  final Color? accentColor;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = accentColor ?? colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (suffix != null) ...[
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            suffix!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarrantyOverviewCard extends StatelessWidget {
  const _WarrantyOverviewCard({
    required this.activeCount,
    required this.expiringCount,
    required this.expiredCount,
    required this.totalCount,
  });

  final int activeCount;
  final int expiringCount;
  final int expiredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            if (totalCount > 0)
              _WarrantyProgressBar(
                activeCount: activeCount,
                expiringCount: expiringCount,
                expiredCount: expiredCount,
                totalCount: totalCount,
              )
            else
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

            const SizedBox(height: 20),

            _WarrantyRow(
              icon: Icons.verified_outlined,
              label: 'ยังมีประกัน',
              value: activeCount,
              color: AppStatisticsColors.success(context),
            ),

            const Divider(height: 24),

            _WarrantyRow(
              icon: Icons.warning_amber_outlined,
              label: 'ใกล้หมดประกัน',
              value: expiringCount,
              color: AppStatisticsColors.warning(context),
            ),

            const Divider(height: 24),

            _WarrantyRow(
              icon: Icons.error_outline,
              label: 'หมดประกันแล้ว',
              value: expiredCount,
              color: AppStatisticsColors.error(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarrantyProgressBar extends StatelessWidget {
  const _WarrantyProgressBar({
    required this.activeCount,
    required this.expiringCount,
    required this.expiredCount,
    required this.totalCount,
  });

  final int activeCount;
  final int expiringCount;
  final int expiredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final success = AppStatisticsColors.success(context);
    final warning = AppStatisticsColors.warning(context);
    final error = AppStatisticsColors.error(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            if (activeCount > 0)
              Expanded(
                flex: activeCount,
                child: Container(color: success),
              ),
            if (expiringCount > 0)
              Expanded(
                flex: expiringCount,
                child: Container(color: warning),
              ),
            if (expiredCount > 0)
              Expanded(
                flex: expiredCount,
                child: Container(color: error),
              ),
            if (totalCount == 0)
              Expanded(
                child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
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
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          '$value รายการ',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}

class _RecentAssetCard extends StatelessWidget {
  const _RecentAssetCard({
    required this.name,
    required this.purchasePrice,
    required this.condition,
    required this.imagePath,
  });

  final String name;
  final double purchasePrice;
  final String condition;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        leading: _StatisticAssetImage(
          imagePath: imagePath,
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'มูลค่า ${_formatPrice(purchasePrice)} บาท',
          ),
        ),
        trailing: _ConditionChip(
          condition: condition,
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

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({
    required this.condition,
  });

  final String condition;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        condition,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
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
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        color: colorScheme.outline,
      ),
    );
  }
}

class _EmptyStatisticsView extends StatelessWidget {
  const _EmptyStatisticsView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 36,
        ),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 56,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีข้อมูลทรัพย์สิน',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'เมื่อเพิ่มทรัพย์สินแล้ว สถิติและข้อมูลล่าสุดจะแสดงที่นี่',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class AppStatisticsColors {
  static Color success(BuildContext context) {
    return const Color(0xFF16A34A);
  }

  static Color warning(BuildContext context) {
    return const Color(0xFFD97706);
  }

  static Color error(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }
}