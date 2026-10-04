import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../providers/asset_provider.dart';
import '../assets/asset_detail_screen.dart';
import '../assets/asset_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onViewAllAssets,
  });

  final VoidCallback onViewAllAssets;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  late final Animation<double> _fadeAnimation;

  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().loadAssets();

      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        title: const Text(
          'Home Asset Manager',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    110,
                  ),
                  children: [
                    _GreetingSection(
                      onAddAsset: _openAddAsset,
                    ),
                    const SizedBox(height: 24),
                    _SummarySection(
                      provider: provider,
                    ),
                    const SizedBox(height: 24),
                    _WarrantySection(
                    provider: provider,
                    onAssetTap: _openAssetDetail,
                    ),
                    const SizedBox(height: 24),
                    _RecentAssetsSection(
                      provider: provider,
                      onAssetTap: _openAssetDetail,
                      onAddAsset: _openAddAsset,
                      onViewAll: widget.onViewAllAssets,
                    ),
                  ],
                ),
              ),
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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(
              alpha: 0.22,
            ),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withValues(
                  alpha: 0.07,
                ),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -65,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withValues(
                  alpha: 0.06,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        Icons.home_work_rounded,
                        color: colorScheme.onPrimary,
                        size: 30,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(
                          alpha: 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'จัดการบ้านของคุณ',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'จัดการทรัพย์สินภายในบ้าน\nให้ง่าย เป็นระเบียบ และค้นหาได้ทันที',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color: colorScheme.onPrimary.withValues(
                          alpha: 0.84,
                        ),
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onAddAsset,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.onPrimary,
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_rounded,
                  ),
                  label: const Text(
                    'เพิ่มทรัพย์สิน',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
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
        const _SectionHeader(
          title: 'ภาพรวมทรัพย์สิน',
          icon: Icons.dashboard_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _AnimatedSummaryCard(
                icon: Icons.inventory_2_rounded,
                title: 'ทรัพย์สินทั้งหมด',
                value: '${provider.totalAssets}',
                unit: 'รายการ',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedSummaryCard(
                icon: Icons.account_balance_wallet_rounded,
                title: 'มูลค่ารวม',
                value: _formatPrice(provider.totalValue),
                unit: 'บาท',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPrice(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toStringAsFixed(0);
  }
}

class _AnimatedSummaryCard extends StatefulWidget {
  const _AnimatedSummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String title;
  final String value;
  final String unit;

  @override
  State<_AnimatedSummaryCard> createState() =>
      _AnimatedSummaryCardState();
}

class _AnimatedSummaryCardState
    extends State<_AnimatedSummaryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.icon,
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarrantySection extends StatelessWidget {
  const _WarrantySection({
    required this.provider,
    required this.onAssetTap,
  });

  final AssetProvider provider;
  final Future<void> Function(int assetId) onAssetTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final expiringAssets = provider.expiringWarrantyAssets;
    final hasWarning = expiringAssets.isNotEmpty;
    final hasExpired = provider.expiredWarrantyCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'สถานะการรับประกัน',
          icon: Icons.verified_rounded,
        ),
        const SizedBox(height: 12),

        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _WarrantyRow(
                icon: Icons.verified_rounded,
                title: 'ยังมีประกัน',
                value: provider.activeWarrantyCount,
                iconColor: colorScheme.primary,
                backgroundColor: colorScheme.primaryContainer,
              ),

              const Divider(height: 1),

              _WarrantyRow(
                icon: Icons.warning_amber_rounded,
                title: 'ใกล้หมดประกัน',
                value: provider.expiringWarrantyCount,
                iconColor: hasWarning
                    ? colorScheme.tertiary
                    : colorScheme.outline,
                backgroundColor: hasWarning
                    ? colorScheme.tertiaryContainer
                    : colorScheme.surfaceContainerHighest,
              ),

              const Divider(height: 1),

              _WarrantyRow(
                icon: Icons.cancel_rounded,
                title: 'หมดประกัน',
                value: provider.expiredWarrantyCount,
                iconColor: hasExpired
                    ? colorScheme.error
                    : colorScheme.outline,
                backgroundColor: hasExpired
                    ? colorScheme.errorContainer
                    : colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
        ),

        if (expiringAssets.isNotEmpty) ...[
          const SizedBox(height: 12),

          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ทรัพย์สินที่ประกันใกล้หมด',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        '${expiringAssets.length} รายการ',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),

                for (var index = 0;
                    index < expiringAssets.length && index < 5;
                    index++) ...[
                  _ExpiringWarrantyTile(
                    asset: expiringAssets[index],
                    onTap: () => onAssetTap(
                      expiringAssets[index].id,
                    ),
                  ),
                  if (index < expiringAssets.length - 1 &&
                  index < 4)
                const Divider(
                  height: 1,
                  indent: 72,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _WarrantyRow extends StatelessWidget {
  const _WarrantyRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String title;
  final int value;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (
          child,
          animation,
        ) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: Container(
          key: ValueKey<int>(value),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$value รายการ',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _ExpiringWarrantyTile extends StatelessWidget {
  const _ExpiringWarrantyTile({
    required this.asset,
    required this.onTap,
  });

  final Asset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final remainingDays = _getRemainingDays(
      asset.warrantyEndDate,
    );

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.inventory_2_rounded,
          color: colorScheme.onTertiaryContainer,
        ),
      ),
      title: Text(
        asset.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        remainingDays == 0
            ? 'หมดประกันวันนี้'
            : 'เหลืออีก $remainingDays วัน',
        style: TextStyle(
          color: colorScheme.tertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  int _getRemainingDays(DateTime? warrantyEndDate) {
    if (warrantyEndDate == null) {
      return 0;
    }

    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final endDate = DateTime(
  warrantyEndDate.year,
  warrantyEndDate.month,
  warrantyEndDate.day,
);

    return endDate.difference(todayOnly).inDays;
  }
}

class _RecentAssetsSection extends StatelessWidget {
  const _RecentAssetsSection({
    required this.provider,
    required this.onAssetTap,
    required this.onAddAsset,
    required this.onViewAll,
  });

  final AssetProvider provider;
  final Future<void> Function(int assetId) onAssetTap;
  final VoidCallback onAddAsset;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final recentAssets = provider.assets.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'ทรัพย์สินล่าสุด',
                icon: Icons.history_rounded,
                compact: true,
              ),
            ),
            if (recentAssets.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${recentAssets.length} รายการ',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: onViewAll,
              child: const Text('ดูทั้งหมด'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentAssets.isEmpty)
          _NoRecentAssets(
            onAddAsset: onAddAsset,
          )
        else
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
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
                    const Divider(
                      height: 1,
                      indent: 84,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentAssetTile extends StatefulWidget {
  const _RecentAssetTile({
    required this.asset,
    required this.onTap,
  });

  final Asset asset;
  final VoidCallback onTap;

  @override
  State<_RecentAssetTile> createState() =>
      _RecentAssetTileState();
}

class _RecentAssetTileState
    extends State<_RecentAssetTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      color: _pressed
          ? colorScheme.surfaceContainerHighest
          : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) {
          setState(() {
            _pressed = true;
          });
        },
        onTapCancel: () {
          setState(() {
            _pressed = false;
          });
        },
        onTapUp: (_) {
          setState(() {
            _pressed = false;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          child: Row(
            children: [
              _RecentAssetImage(
                imagePath: widget.asset.imagePath,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 15,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${widget.asset.purchasePrice.toStringAsFixed(2)} บาท',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
            ],
          ),
        ),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder(colorScheme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(imagePath!),
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _buildPlaceholder(colorScheme);
        },
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_rounded,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _NoRecentAssets extends StatelessWidget {
  const _NoRecentAssets({
    required this.onAddAsset,
  });

  final VoidCallback onAddAsset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 36,
        ),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
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
              child: Icon(
                Icons.inventory_2_rounded,
                size: 38,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ยังไม่มีทรัพย์สิน',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'เพิ่มทรัพย์สินชิ้นแรกของคุณ\nเพื่อเริ่มจัดการทรัพย์สินภายในบ้าน',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddAsset,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'เพิ่มทรัพย์สิน',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: compact ? 34 : 38,
          height: compact ? 34 : 38,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              compact ? 11 : 12,
            ),
          ),
          child: Icon(
            icon,
            size: compact ? 18 : 20,
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'เกิดข้อผิดพลาด',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'ลองอีกครั้ง',
              ),
            ),
          ],
        ),
      ),
    );
  }
}