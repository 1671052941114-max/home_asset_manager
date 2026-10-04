import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../providers/maintenance_provider.dart';

class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({
    super.key,
    required this.assetId,
    required this.assetName,
    this.record,
  });

  final int assetId;
  final String assetName;
  final MaintenanceRecord? record;

  bool get isEditing => record != null;

  @override
  State<MaintenanceFormScreen> createState() =>
      _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState
    extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _typeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _costController;
  late final TextEditingController _noteController;

  late DateTime _selectedDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    _typeController = TextEditingController(
      text: record?.type ?? '',
    );

    _descriptionController = TextEditingController(
      text: record?.description ?? '',
    );

    _costController = TextEditingController(
      text: record != null
          ? record.cost.toStringAsFixed(2)
          : '',
    );

    _noteController = TextEditingController(
      text: record?.note ?? '',
    );

    _selectedDate = record?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'เลือกวันที่ซ่อม',
      cancelText: 'ยกเลิก',
      confirmText: 'เลือก',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selected;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final costText = _costController.text.trim();

    final cost = double.tryParse(costText);

    if (cost == null || cost < 0) {
      _showMessage('กรุณาระบุค่าใช้จ่ายให้ถูกต้อง');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<MaintenanceProvider>();

    final success = widget.isEditing
        ? await provider.updateRecord(
            assetId: widget.assetId,
            recordId: widget.record!.id,
            date: _selectedDate,
            type: _typeController.text.trim(),
            description: _descriptionController.text.trim(),
            cost: cost,
            note: _noteController.text.trim(),
          )
        : await provider.addRecord(
            assetId: widget.assetId,
            date: _selectedDate,
            type: _typeController.text.trim(),
            description: _descriptionController.text.trim(),
            cost: cost,
            note: _noteController.text.trim(),
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    _showMessage(
      provider.errorMessage ??
          'ไม่สามารถบันทึกประวัติการซ่อมได้',
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'แก้ไขประวัติการซ่อม'
              : 'เพิ่มประวัติการซ่อม',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            32,
          ),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                ),
                title: const Text(
                  'ทรัพย์สิน',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                subtitle: Text(
                  widget.assetName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'ข้อมูลการซ่อม',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _typeController,
              textInputAction: TextInputAction.next,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'ประเภทการซ่อม',
                hintText: 'เช่น เปลี่ยนอะไหล่, ทำความสะอาด',
                prefixIcon: Icon(
                  Icons.build_outlined,
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'กรุณาระบุประเภทการซ่อม';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            InkWell(
              onTap: _isSaving ? null : _selectDate,
              borderRadius: BorderRadius.circular(12),
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

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                hintText: 'รายละเอียดเกี่ยวกับการซ่อม',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 55,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'ค่าใช้จ่าย',
                hintText: '0.00',
                prefixIcon: Icon(
                  Icons.payments_outlined,
                ),
                prefixText: '฿ ',
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'กรุณาระบุค่าใช้จ่าย';
                }

                final cost = double.tryParse(
                  value.trim(),
                );

                if (cost == null) {
                  return 'กรุณาระบุตัวเลขให้ถูกต้อง';
                }

                if (cost < 0) {
                  return 'ค่าใช้จ่ายต้องไม่ติดลบ';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _noteController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isSaving,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'หมายเหตุ',
                hintText: 'ข้อมูลเพิ่มเติม (ถ้ามี)',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 32,
                  ),
                  child: Icon(
                    Icons.notes_outlined,
                  ),
                ),
              ),
              onFieldSubmitted: (_) {
                if (!_isSaving) {
                  _save();
                }
              },
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                      ),
                label: Text(
                  _isSaving
                      ? 'กำลังบันทึก...'
                      : isEditing
                          ? 'บันทึกการแก้ไข'
                          : 'บันทึกประวัติ',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}