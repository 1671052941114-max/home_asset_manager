import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/asset_card.dart';
import '../../providers/asset_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/location_provider.dart';
import 'asset_detail_screen.dart';
import 'asset_form_screen.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetProvider>().loadAssets();
      context.read<CategoryProvider>().loadCategories();
      context.read<LocationProvider>().loadLocations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    context.read<AssetProvider>().setSearchQuery(value);
  }

  Future<void> _showFilterSheet() async {
    final assetProvider = context.read<AssetProvider>();

    int? selectedCategoryId = assetProvider.categoryId;
    int? selectedLocationId = assetProvider.locationId;
    String? selectedCondition = assetProvider.condition;
    String? selectedWarranty = assetProvider.warrantyStatus;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ตัวกรอง',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),

                    Consumer<CategoryProvider>(
                      builder: (context, provider, child) {
                        return DropdownButtonFormField<int?>(
                          initialValue: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'หมวดหมู่',
                            prefixIcon: Icon(
                              Icons.category_outlined,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('ทั้งหมด'),
                            ),
                            ...provider.categories.map(
                              (category) {
                                return DropdownMenuItem<int?>(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              },
                            ),
                          ],
                          onChanged: (value) {
                            setSheetState(() {
                              selectedCategoryId = value;
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    Consumer<LocationProvider>(
                      builder: (context, provider, child) {
                        return DropdownButtonFormField<int?>(
                          initialValue: selectedLocationId,
                          decoration: const InputDecoration(
                            labelText: 'สถานที่',
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('ทั้งหมด'),
                            ),
                            ...provider.locations.map(
                              (location) {
                                return DropdownMenuItem<int?>(
                                  value: location.id,
                                  child: Text(location.name),
                                );
                              },
                            ),
                          ],
                          onChanged: (value) {
                            setSheetState(() {
                              selectedLocationId = value;
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String?>(
                      initialValue: selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'สภาพ',
                        prefixIcon: Icon(
                          Icons.build_outlined,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('ทั้งหมด'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'ใหม่',
                          child: Text('ใหม่'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'ดี',
                          child: Text('ดี'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'พอใช้',
                          child: Text('พอใช้'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'ชำรุด',
                          child: Text('ชำรุด'),
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          selectedCondition = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String?>(
                      initialValue: selectedWarranty,
                      decoration: const InputDecoration(
                        labelText: 'ประกัน',
                        prefixIcon: Icon(
                          Icons.verified_outlined,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('ทั้งหมด'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'notSpecified',
                          child: Text('ไม่ได้ระบุ'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'active',
                          child: Text('ยังมีประกัน'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'expiringSoon',
                          child: Text('ใกล้หมดประกัน'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'expired',
                          child: Text('หมดประกัน'),
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          selectedWarranty = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              assetProvider.clearFilters();
                              _searchController.clear();
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('รีเซ็ต'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              assetProvider.setCategoryFilter(
                                selectedCategoryId,
                              );

                              assetProvider.setLocationFilter(
                                selectedLocationId,
                              );

                              assetProvider.setConditionFilter(
                                selectedCondition,
                              );

                              assetProvider.setWarrantyFilter(
                                selectedWarranty,
                              );

                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('ใช้ตัวกรอง'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSortSheet() async {
    final provider = context.read<AssetProvider>();

    final selectedSort = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'เรียงลำดับ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _SortOption(
                title: 'เพิ่มล่าสุด',
                value: 'created_desc',
                selectedValue: provider.sortType,
              ),
              _SortOption(
                title: 'ชื่อ A-Z',
                value: 'name_asc',
                selectedValue: provider.sortType,
              ),
              _SortOption(
                title: 'ราคาสูง → ต่ำ',
                value: 'price_desc',
                selectedValue: provider.sortType,
              ),
              _SortOption(
                title: 'ราคาต่ำ → สูง',
                value: 'price_asc',
                selectedValue: provider.sortType,
              ),
              _SortOption(
                title: 'วันที่ซื้อ ใหม่ → เก่า',
                value: 'purchase_newest',
                selectedValue: provider.sortType,
              ),
              _SortOption(
                title: 'วันที่ซื้อ เก่า → ใหม่',
                value: 'purchase_oldest',
                selectedValue: provider.sortType,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selectedSort != null && mounted) {
      provider.setSortType(selectedSort);
    }
  }

  Future<void> _openAssetForm() async {
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
String _getCategoryName(
  BuildContext context,
  int categoryId,
) {
  final categories = context.read<CategoryProvider>().categories;

  for (final category in categories) {
    if (category.id == categoryId) {
      return category.name;
    }
  }

  return 'ไม่ระบุ';
}

String _getLocationName(
  BuildContext context,
  int locationId,
) {
  final locations = context.read<LocationProvider>().locations;

  for (final location in locations) {
    if (location.id == locationId) {
      return location.name;
    }
  }

  return 'ไม่ระบุ';
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทรัพย์สิน'),
        actions: [
          IconButton(
            tooltip: 'เรียงลำดับ',
            onPressed: _showSortSheet,
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            tooltip: 'ตัวกรอง',
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list),
          ),
        ],
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

          final filteredAssets = provider.filteredAssets;
          final hasAssets = provider.assets.isNotEmpty;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  8,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText:
                        'ค้นหาชื่อ รายละเอียด หรือ Serial Number',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        provider.searchQuery.isNotEmpty
                            ? IconButton(
                                tooltip: 'ล้างการค้นหา',
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              if (_hasActiveFilters(provider))
                _ActiveFilterBar(
                  provider: provider,
                ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.loadAssets,
                  child: filteredAssets.isEmpty
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            _EmptyAssetView(
                              hasAssets: hasAssets,
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            100,
                          ),
                          itemCount: filteredAssets.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final asset = filteredAssets[index];

                            return AssetCard(
  asset: asset,
  categoryName: _getCategoryName(
    context,
    asset.categoryId,
  ),
  locationName: _getLocationName(
    context,
    asset.locationId,
  ),
  onTap: () => _openAssetDetail(asset.id),
);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAssetForm,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มทรัพย์สิน'),
      ),
    );
  }

  bool _hasActiveFilters(AssetProvider provider) {
    return provider.categoryId != null ||
        provider.locationId != null ||
        provider.condition != null ||
        provider.warrantyStatus != null ||
        provider.searchQuery.isNotEmpty;
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.title,
    required this.value,
    required this.selectedValue,
  });

  final String title;
  final String value;
  final String selectedValue;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: value == selectedValue
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        Navigator.of(context).pop(value);
      },
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({
    required this.provider,
  });

  final AssetProvider provider;

  @override
  Widget build(BuildContext context) {
    final filters = <String>[];

    if (provider.categoryId != null) {
      filters.add('หมวดหมู่');
    }

    if (provider.locationId != null) {
      filters.add('สถานที่');
    }

    if (provider.condition != null) {
      filters.add('สภาพ');
    }

    if (provider.warrantyStatus != null) {
      filters.add('ประกัน');
    }

    if (provider.searchQuery.isNotEmpty) {
      filters.add('ค้นหา');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          TextButton(
            onPressed: provider.clearFilters,
            child: const Text('ล้าง'),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssetView extends StatelessWidget {
  const _EmptyAssetView({
    required this.hasAssets,
  });

  final bool hasAssets;

  @override
  Widget build(BuildContext context) {
    final title = hasAssets
        ? 'ไม่พบทรัพย์สินที่ค้นหา'
        : 'ยังไม่มีทรัพย์สิน';

    final description = hasAssets
        ? 'ลองเปลี่ยนคำค้นหาหรือปรับตัวกรองใหม่'
        : 'เพิ่มทรัพย์สินชิ้นแรกของคุณเพื่อเริ่มจัดการข้อมูล';

    return Column(
      children: [
        Icon(
          hasAssets
              ? Icons.search_off_outlined
              : Icons.inventory_2_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
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