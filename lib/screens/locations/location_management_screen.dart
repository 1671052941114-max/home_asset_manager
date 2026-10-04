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
    final isEditing = locationId != null;

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _LocationDialog(
          title: isEditing ? 'แก้ไขสถานที่' : 'เพิ่มสถานที่',
          initialName: currentName ?? '',
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );

    if (!mounted || name == null) {
      return;
    }

    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      _showMessage(
        'กรุณาระบุชื่อสถานที่',
        isError: true,
      );
      return;
    }

    final provider = context.read<LocationProvider>();

    final bool success = isEditing
        ? await provider.updateLocation(
            locationId,
            trimmedName,
          )
        : await provider.addLocation(
            trimmedName,
          );

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage(
        isEditing
            ? 'แก้ไขสถานที่เรียบร้อยแล้ว'
            : 'เพิ่มสถานที่เรียบร้อยแล้ว',
      );
    } else {
      _showMessage(
        provider.errorMessage ?? 'ไม่สามารถบันทึกสถานที่ได้',
        isError: true,
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

    final provider = context.read<LocationProvider>();

    final success = await provider.deleteLocation(
      locationId,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'ลบสถานที่เรียบร้อยแล้ว'
          : provider.errorMessage ?? 'ไม่สามารถลบสถานที่ได้',
      isError: !success,
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : null,
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
          if (provider.isLoading &&
              provider.locations.isEmpty) {
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
                physics:
                    const AlwaysScrollableScrollPhysics(),
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
              separatorBuilder: (_, _) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final location =
                    provider.locations[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context)
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
                      'สร้างเมื่อ '
                      '${_formatDate(location.createdAt)}',
                    ),
                    trailing:
                        PopupMenuButton<String>(
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
                            leading: Icon(
                              Icons.edit_outlined,
                            ),
                            title: Text('แก้ไข'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                            ),
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
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          _showLocationDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสถานที่'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({
    required this.title,
    required this.initialName,
    required this.onCancel,
  });

  final String title;
  final String initialName;
  final VoidCallback onCancel;

  @override
  State<_LocationDialog> createState() =>
      _LocationDialogState();
}

class _LocationDialogState
    extends State<_LocationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _controller.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 50,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'ชื่อสถานที่',
          hintText: 'เช่น ห้องนอน, ห้องนั่งเล่น',
          prefixIcon: Icon(
            Icons.location_on_outlined,
          ),
        ),
        onSubmitted: (_) {
          _submit();
        },
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.title.startsWith('แก้ไข')
                ? 'บันทึก'
                : 'เพิ่ม',
          ),
        ),
      ],
    );
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
          color: Theme.of(context)
              .colorScheme
              .outline,
        ),
        const SizedBox(height: 16),
        Text(
          'ยังไม่มีสถานที่',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'เพิ่มสถานที่ เช่น ห้องนอน ห้องครัว '
          'หรือห้องนั่งเล่น',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium,
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
              color: Theme.of(context)
                  .colorScheme
                  .error,
            ),
            const SizedBox(height: 16),
            Text(
              'เกิดข้อผิดพลาด',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
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