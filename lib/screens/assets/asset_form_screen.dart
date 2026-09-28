import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/image_service.dart';
import '../../data/database/app_database.dart';
import '../../providers/asset_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/location_provider.dart';

class AssetFormScreen extends StatefulWidget {
  const AssetFormScreen({
    super.key,
    this.assetId,
  });

  final int? assetId;

  bool get isEditMode => assetId != null;

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _serialController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedLocationId;

  DateTime? _purchaseDate;
  DateTime? _warrantyEndDate;

  String _condition = 'ดี';
  String? _imagePath;

  final List<String> _conditions = [
    'ใหม่',
    'ดี',
    'พอใช้',
    'ชำรุด',
  ];

  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();

    if (widget.assetId != null) {
      _loadAsset();
    }
  }

  Future<void> _loadAsset() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final asset = await context.read<AssetProvider>().getAssetById(
            widget.assetId!,
          );

      if (!mounted) {
        return;
      }

      if (asset == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบทรัพย์สินที่ต้องการแก้ไข'),
          ),
        );

        Navigator.of(context).pop();
        return;
      }

      _nameController.text = asset.name;
      _priceController.text = asset.purchasePrice.toStringAsFixed(2);
      _serialController.text = asset.serialNumber ?? '';
      _descriptionController.text = asset.description ?? '';

      _imagePath = asset.imagePath;

      _selectedCategoryId = asset.categoryId;
      _selectedLocationId = asset.locationId;

      _purchaseDate = asset.purchaseDate;
      _warrantyEndDate = asset.warrantyEndDate;

      _condition = asset.condition;
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถโหลดข้อมูลทรัพย์สินได้'),
        ),
      );

      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _serialController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectPurchaseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _purchaseDate = selected;

        if (_warrantyEndDate != null &&
            _warrantyEndDate!.isBefore(selected)) {
          _warrantyEndDate = null;
        }
      });
    }
  }

  Future<void> _selectWarrantyEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _warrantyEndDate ?? _purchaseDate ?? DateTime.now(),
      firstDate: _purchaseDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _warrantyEndDate = selected;
      });
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('ถ่ายรูปด้วยกล้อง'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('เลือกจาก Gallery'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) {
      return;
    }

    final String? path;

    try {
      if (source == ImageSource.camera) {
        path = await ImageService.instance.takePhoto();
      } else {
        path = await ImageService.instance.pickFromGallery();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('ไม่สามารถเลือกรูปภาพได้');
      return;
    }

    if (!mounted || path == null) {
      return;
    }

    setState(() {
      _imagePath = path;
    });
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      _showMessage('กรุณาเลือกหมวดหมู่');
      return;
    }

    if (_selectedLocationId == null) {
      _showMessage('กรุณาเลือกสถานที่');
      return;
    }

    if (_warrantyEndDate != null &&
        _purchaseDate != null &&
        _warrantyEndDate!.isBefore(_purchaseDate!)) {
      _showMessage('วันหมดประกันต้องไม่ก่อนวันที่ซื้อ');
      return;
    }

    final price = double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null || price < 0) {
      _showMessage('กรุณากรอกราคาที่ถูกต้อง');
      return;
    }

    final now = DateTime.now();

    final asset = AssetsCompanion(
      id: widget.assetId == null
          ? const drift.Value.absent()
          : drift.Value(widget.assetId!),
      name: drift.Value(_nameController.text.trim()),
      description: drift.Value(
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
      categoryId: drift.Value(_selectedCategoryId!),
      locationId: drift.Value(_selectedLocationId!),
      purchasePrice: drift.Value(price),
      purchaseDate: drift.Value(_purchaseDate),
      warrantyEndDate: drift.Value(_warrantyEndDate),
      condition: drift.Value(_condition),
      serialNumber: drift.Value(
        _serialController.text.trim().isEmpty
            ? null
            : _serialController.text.trim(),
      ),
      imagePath: drift.Value(_imagePath),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    final provider = context.read<AssetProvider>();

    final bool success;

    if (widget.assetId == null) {
      success = await provider.addAsset(asset);
    } else {
      success = await provider.updateAsset(asset);
    }

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage(
        widget.isEditMode
            ? 'แก้ไขทรัพย์สินเรียบร้อยแล้ว'
            : 'เพิ่มทรัพย์สินเรียบร้อยแล้ว',
      );

      Navigator.of(context).pop();
    } else {
      _showMessage(
        provider.errorMessage ?? 'ไม่สามารถบันทึกข้อมูลได้',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'ยังไม่ได้เลือก';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
Widget _buildImagePreview() {
  final path = _imagePath;

  if (path == null || path.isEmpty) {
    return const Icon(
      Icons.add_a_photo_outlined,
      size: 48,
    );
  }

  final file = File(path);

  return FutureBuilder<bool>(
    future: file.exists(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (snapshot.data != true) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            const Text('ไม่พบไฟล์รูปภาพ'),
          ],
        );
      }

      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              const Text('ไม่สามารถแสดงรูปภาพได้'),
            ],
          );
        },
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final categoryProvider = context.watch<CategoryProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final assetProvider = context.watch<AssetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditMode
              ? 'แก้ไขทรัพย์สิน'
              : 'เพิ่มทรัพย์สิน',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImagePreview(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'ชื่อทรัพย์สิน',
                hintText: 'เช่น MacBook Air M2',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อทรัพย์สิน';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: categoryProvider.categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'กรุณาเลือกหมวดหมู่';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: _selectedLocationId,
              decoration: const InputDecoration(
                labelText: 'สถานที่',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: locationProvider.locations.map((location) {
                return DropdownMenuItem<int>(
                  value: location.id,
                  child: Text(location.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocationId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'กรุณาเลือกสถานที่';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'ราคาซื้อ',
                hintText: '0.00',
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: 'บาท',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกราคา';
                }

                final price = double.tryParse(value.trim());

                if (price == null || price < 0) {
                  return 'กรุณากรอกราคาที่ถูกต้อง';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _DateField(
              label: 'วันที่ซื้อ',
              value: _formatDate(_purchaseDate),
              icon: Icons.calendar_today_outlined,
              onTap: _selectPurchaseDate,
            ),

            const SizedBox(height: 16),

            _DateField(
              label: 'วันหมดประกัน',
              value: _formatDate(_warrantyEndDate),
              icon: Icons.verified_outlined,
              onTap: _selectWarrantyEndDate,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(
                labelText: 'สภาพทรัพย์สิน',
                prefixIcon: Icon(Icons.build_outlined),
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem<String>(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _condition = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _serialController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Serial Number',
                hintText: 'ถ้ามี',
                prefixIcon: Icon(Icons.qr_code_2_outlined),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                hintText: 'รายละเอียดเพิ่มเติม',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: assetProvider.isLoading ? null : _saveAsset,
              icon: assetProvider.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                assetProvider.isLoading
                    ? 'กำลังบันทึก...'
                    : 'บันทึกทรัพย์สิน',
              ),
            ),

            if (assetProvider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                assetProvider.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        child: Text(value),
      ),
    );
  }
}