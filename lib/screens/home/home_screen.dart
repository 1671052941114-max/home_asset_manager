import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../providers/asset_provider.dart';
import '../assets/asset_detail_screen.dart';
import '../assets/asset_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().loadAssets();
    });
  }

  Future<void> _openAddAsset() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AssetFormScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await context.read<AssetProvider>().loadAssets();
  }

  Future<void> _openAssetDetail(int assetId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssetDetailScreen(
          assetId: assetId,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await context.read<AssetProvider>().loadAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Asset Manager'),
      ),
      body: Consumer<AssetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.assets.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null &&
              provider.assets.isEmpty) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: provider.loadAssets,
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadAssets,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              children: [
                _GreetingSection(
                  onAddAsset: _openAddAsset,
                ),
                const SizedBox(height: 20),
                _SummarySection(
                  provider: provider,
                ),
                const SizedBox(height: 24),
                _WarrantySection(
                  provider: provider,
                ),
                const SizedBox(height: 24),
                _RecentAssetsSection(
                  provider: provider,
                  onAssetTap: _openAssetDetail,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({
    required this.onAddAsset,
  });

  final VoidCallback onAddAsset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'จัดการทรัพย์สินของคุณ',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ดูภาพรวมและจัดการทรัพย์สินภายในบ้านได้ง่ายขึ้น',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.home_work_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.provider,
  });

  final AssetProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ภาพรวม',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.inventory_2_outlined,
                title: 'ทรัพย์สินทั้งหมด',
                value: '${provider.totalAssets}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.payments_outlined,
                title: 'มูลค่ารวม',
                value: _formatPrice(provider.totalValue),
                suffix: 'บาท',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPrice(double value) {
    return value.toStringAsFixed(2);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WarrantySection extends StatelessWidget {
  const _WarrantySection({
    required this.provider,
  });

  final AssetProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'สถานะประกัน',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _WarrantyRow(
                icon: Icons.verified_outlined,
                title: 'ยังมีประกัน',
                value: provider.activeWarrantyCount,
              ),
              const Divider(height: 1),
              _WarrantyRow(
                icon: Icons.warning_amber_outlined,
                title: 'ใกล้หมดประกัน',
                value: provider.expiringWarrantyCount,
              ),
              const Divider(height: 1),
              _WarrantyRow(
                icon: Icons.cancel_outlined,
                title: 'หมดประกัน',
                value: provider.expiredWarrantyCount,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WarrantyRow extends StatelessWidget {
  const _WarrantyRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        '$value รายการ',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _RecentAssetsSection extends StatelessWidget {
  const _RecentAssetsSection({
    required this.provider,
    required this.onAssetTap,
  });

  final AssetProvider provider;
  final Future<void> Function(int assetId) onAssetTap;

  @override
  Widget build(BuildContext context) {
    final recentAssets = provider.assets.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ทรัพย์สินล่าสุด',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (recentAssets.isNotEmpty)
              Text(
                '${recentAssets.length} รายการ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentAssets.isEmpty)
          const _NoRecentAssets()
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0;
                    index < recentAssets.length;
                    index++) ...[
                  _RecentAssetTile(
                    asset: recentAssets[index],
                    onTap: () => onAssetTap(
                      recentAssets[index].id,
                    ),
                  ),
                  if (index < recentAssets.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
class _RecentAssetTile extends StatelessWidget {
  const _RecentAssetTile({
    required this.asset,
    required this.onTap,
  });

  final Asset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _RecentAssetImage(
        imagePath: asset.imagePath,
      ),
      title: Text(
        asset.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${asset.purchasePrice.toStringAsFixed(2)} บาท',
      ),
      trailing: const Icon(
        Icons.chevron_right,
      ),
      onTap: onTap,
    );
  }
}

class _RecentAssetImage extends StatelessWidget {
  const _RecentAssetImage({
    required this.imagePath,
  });

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;

    if (path == null || path.isEmpty) {
      return const _RecentImagePlaceholder();
    }

    return SizedBox(
      width: 56,
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              'Home Recent Asset Image Error: $error',
            );

            return const _RecentImagePlaceholder();
          },
        ),
      ),
    );
  }
}

class _RecentImagePlaceholder extends StatelessWidget {
  const _RecentImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 56,
      height: 56,
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
class _NoRecentAssets extends StatelessWidget {
  const _NoRecentAssets();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              const Text(
                'ยังไม่มีทรัพย์สิน',
              ),
              const SizedBox(height: 4),
              Text(
                'เพิ่มทรัพย์สินเพื่อดูข้อมูลบน Dashboard',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'เกิดข้อผิดพลาด',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }
}