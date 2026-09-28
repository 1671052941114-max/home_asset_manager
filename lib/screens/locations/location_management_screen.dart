import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/location_provider.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState
    extends State<LocationManagementScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadLocations();
    });
  }

  Future<void> _showLocationDialog({
    int? locationId,
    String? currentName,
  }) async {
    final controller = TextEditingController(text: currentName ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isEditing = locationId != null;

        return AlertDialog(
          title: Text(
            isEditing ? 'แก้ไขสถานที่' : 'เพิ่มสถานที่',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'ชื่อสถานที่',
              hintText: 'เช่น ห้องนอน, ห้องนั่งเล่น',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            onSubmitted: (_) {
              Navigator.of(dialogContext).pop(true);
            },
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
              child: Text(
                isEditing ? 'บันทึก' : 'เพิ่ม',
              ),
            ),
          ],
        );
      },
    );

    if (result != true || !mounted) {
      controller.dispose();
      return;
    }

    final name = controller.text.trim();
    controller.dispose();

    if (name.isEmpty) {
      _showMessage('กรุณาระบุชื่อสถานที่');
      return;
    }

    final provider = context.read<LocationProvider>();

    final success = locationId == null
        ? await provider.addLocation(name)
        : await provider.updateLocation(locationId, name);

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage(
        locationId == null
            ? 'เพิ่มสถานที่เรียบร้อยแล้ว'
            : 'แก้ไขสถานที่เรียบร้อยแล้ว',
      );
    } else {
      _showMessage(
        provider.errorMessage ?? 'ไม่สามารถดำเนินการได้',
      );
    }
  }

  Future<void> _confirmDelete(
    int locationId,
    String locationName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบสถานที่'),
          content: Text(
            'คุณต้องการลบ "$locationName" หรือไม่?',
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
                backgroundColor: Theme.of(context).colorScheme.error,
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

    final provider = context.read<LocationProvider>();
    final success = await provider.deleteLocation(locationId);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'ลบสถานที่เรียบร้อยแล้ว'
          : provider.errorMessage ?? 'ไม่สามารถลบสถานที่ได้',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการสถานที่'),
      ),
      body: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.locations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null &&
              provider.locations.isEmpty) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: provider.loadLocations,
            );
          }

          if (provider.locations.isEmpty) {
            return RefreshIndicator(
              onRefresh: provider.loadLocations,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  _EmptyLocationView(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadLocations,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              itemCount: provider.locations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final location = provider.locations[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Icon(
                        Icons.location_on_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      location.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'สร้างเมื่อ ${_formatDate(location.createdAt)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'ตัวเลือก',
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showLocationDialog(
                              locationId: location.id,
                              currentName: location.name,
                            );
                          case 'delete':
                            _confirmDelete(
                              location.id,
                              location.name,
                            );
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
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationDialog(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสถานที่'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }
}

class _EmptyLocationView extends StatelessWidget {
  const _EmptyLocationView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.location_off_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          'ยังไม่มีสถานที่',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'เพิ่มสถานที่ เช่น ห้องนอน ห้องครัว หรือห้องนั่งเล่น',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
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