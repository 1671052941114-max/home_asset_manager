import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../providers/maintenance_provider.dart';
import 'maintenance_form_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({
    super.key,
    required this.assetId,
    required this.assetName,
  });

  final int assetId;
  final String assetName;

  @override
  State<MaintenanceScreen> createState() =>
      _MaintenanceScreenState();
}

class _MaintenanceScreenState
    extends State<MaintenanceScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaintenanceProvider>().loadRecords(
            widget.assetId,
          );
    });
  }

  Future<void> _addRecord() async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => MaintenanceFormScreen(
        assetId: widget.assetId,
        assetName: widget.assetName,
      ),
    ),
  );

  if (result == true && mounted) {
    await context.read<MaintenanceProvider>().loadRecords(
          widget.assetId,
        );
  }
}

  Future<void> _editRecord(
    MaintenanceRecord record,
  ) async {
    // จะเชื่อมฟอร์มแก้ไขในขั้นถัดไป
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('ฟังก์ชันแก้ไขกำลังพัฒนา'),
        ),
      );
  }

  Future<void> _deleteRecord(
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'ลบประวัติการซ่อมเรียบร้อยแล้ว'
                : provider.errorMessage ??
                    'ไม่สามารถลบประวัติการซ่อมได้',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประวัติการซ่อม'),
      ),
      body: Consumer<MaintenanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading &&
              provider.records.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null &&
              provider.records.isEmpty) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: () {
                provider.loadRecords(widget.assetId);
              },
            );
          }

          if (provider.records.isEmpty) {
            return _EmptyView(
              onAdd: _addRecord,
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              return provider.loadRecords(widget.assetId);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              children: [
                _TotalCostCard(
                  totalCost: provider.totalCost,
                ),
                const SizedBox(height: 16),
                ...provider.records.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: _MaintenanceCard(
                      record: record,
                      onEdit: () => _editRecord(record),
                      onDelete: () => _deleteRecord(record),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มประวัติ'),
      ),
    );
  }
}

class _TotalCostCard extends StatelessWidget {
  const _TotalCostCard({
    required this.totalCost,
  });

  final double totalCost;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              child: Icon(
                Icons.build_outlined,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'ค่าใช้จ่ายซ่อมบำรุงทั้งหมด',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '฿${totalCost.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final MaintenanceRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          8,
          14,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .secondaryContainer,
              child: Icon(
                Icons.build_outlined,
                color: Theme.of(context)
                    .colorScheme
                    .onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    record.type,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(record.date),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                  if (record.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      record.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'ค่าใช้จ่าย ฿${record.cost.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (record.note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'หมายเหตุ: ${record.note}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'ตัวเลือก',
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                  case 'delete':
                    onDelete();
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.build_circle_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 20),
            Text(
              'ยังไม่มีประวัติการซ่อม',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'บันทึกการซ่อมบำรุงเพื่อเก็บประวัติและค่าใช้จ่ายของทรัพย์สิน',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มประวัติ'),
            ),
          ],
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
  final VoidCallback onRetry;

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