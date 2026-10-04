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
  Asset? _editingAsset;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      context.read<LocationProvider>().loadLocations();

      if (widget.assetId != null) {
        _loadAsset();
      }
    });
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
        _showMessage('ไม่พบทรัพย์สินที่ต้องการแก้ไข');
        Navigator.of(context).pop();
        return;
      }

      _nameController.text = asset.name;
      _priceController.text = asset.purchasePrice.toStringAsFixed(2);
      _serialController.text = asset.serialNumber ?? '';
      _descriptionController.text = asset.description ?? '';

      _editingAsset = asset;
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

      _showMessage('ไม่สามารถโหลดข้อมูลทรัพย์สินได้');
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
      helpText: 'เลือกวันที่ซื้อ',
      cancelText: 'ยกเลิก',
      confirmText: 'เลือก',
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
      initialDate:
          _warrantyEndDate ?? _purchaseDate ?? DateTime.now(),
      firstDate: _purchaseDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'เลือกวันหมดประกัน',
      cancelText: 'ยกเลิก',
      confirmText: 'เลือก',
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
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  leading: Icon(Icons.photo_camera_back_outlined),
                  title: Text(
                    'เลือกรูปภาพ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                  ),
                  title: const Text('ถ่ายรูปด้วยกล้อง'),
                  onTap: () {
                    Navigator.of(context).pop(
                      ImageSource.camera,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                  ),
                  title: const Text('เลือกจาก Gallery'),
                  onTap: () {
                    Navigator.of(context).pop(
                      ImageSource.gallery,
                    );
                  },
                ),
              ],
            ),
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

  void _removeImage() {
    setState(() {
      _imagePath = null;
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
      name: drift.Value(
        _nameController.text.trim(),
      ),
      description: drift.Value(
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
      categoryId: drift.Value(
        _selectedCategoryId!,
      ),
      locationId: drift.Value(
        _selectedLocationId!,
      ),
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
      createdAt: widget.isEditMode
          ? drift.Value(_editingAsset!.createdAt)
          : drift.Value(now),
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
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
      return _ImagePlaceholder(
        onTap: _pickImage,
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
          return _BrokenImageView(
            onTap: _pickImage,
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _BrokenImageView(
                  onTap: _pickImage,
                );
              },
            ),
            Positioned(
              right: 10,
              top: 10,
              child: _ImageActionButton(
                icon: Icons.delete_outline,
                tooltip: 'ลบรูปภาพ',
                onPressed: _removeImage,
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: FilledButton.tonalIcon(
                onPressed: _pickImage,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                ),
                label: const Text('เปลี่ยนรูป'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.35,
            child: Container(
              color: colorScheme.surfaceContainerHighest,
              child: _buildImagePreview(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              16,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _imagePath == null
                        ? 'เพิ่มรูปภาพทรัพย์สิน'
                        : 'รูปภาพทรัพย์สิน',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (_imagePath == null)
                  OutlinedButton(
                    onPressed: _pickImage,
                    child: const Text('เลือกรูป'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<String>(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditMode
                ? 'แก้ไขทรัพย์สิน'
                : 'เพิ่มทรัพย์สิน',
          ),
        ),
        body: const Center(
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
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            32,
          ),
          children: [
            _buildImageSection(context),

            const SizedBox(height: 16),

            _buildSection(
              context: context,
              icon: Icons.inventory_2_outlined,
              title: 'ข้อมูลพื้นฐาน',
              subtitle: 'ระบุชื่อ หมวดหมู่ และสถานที่จัดเก็บ',
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อทรัพย์สิน',
                    hintText: 'เช่น MacBook Air M2',
                    prefixIcon: Icon(
                      Icons.inventory_2_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
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
                    prefixIcon: Icon(
                      Icons.category_outlined,
                    ),
                  ),
                  items: categoryProvider.categories.map(
                    (category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    },
                  ).toList(),
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
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                    ),
                  ),
                  items: locationProvider.locations.map(
                    (location) {
                      return DropdownMenuItem<int>(
                        value: location.id,
                        child: Text(location.name),
                      );
                    },
                  ).toList(),
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
              ],
            ),

            const SizedBox(height: 16),

            _buildSection(
              context: context,
              icon: Icons.payments_outlined,
              title: 'ข้อมูลการซื้อ',
              subtitle: 'ราคา วันที่ซื้อ และข้อมูลการรับประกัน',
              children: [
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'ราคาซื้อ',
                    hintText: '0.00',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                    ),
                    suffixText: 'บาท',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'กรุณากรอกราคา';
                    }

                    final price =
                        double.tryParse(value.trim());

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

                if (_warrantyEndDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ระบบจะแจ้งเตือนเมื่อใกล้หมดประกัน',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            _buildSection(
              context: context,
              icon: Icons.description_outlined,
              title: 'สภาพและรายละเอียด',
              subtitle: 'ข้อมูลเพิ่มเติมสำหรับใช้ระบุทรัพย์สิน',
              children: [
                _buildConditionDropdown(),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _serialController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number',
                    hintText: 'ถ้ามี',
                    prefixIcon: Icon(
                      Icons.qr_code_2_outlined,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียด',
                    hintText: 'รายละเอียดเพิ่มเติมของทรัพย์สิน',
                    prefixIcon: Icon(
                      Icons.notes_outlined,
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (assetProvider.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context)
                          .colorScheme
                          .onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        assetProvider.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: assetProvider.isLoading
                    ? null
                    : _saveAsset,
                icon: assetProvider.isLoading
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
                  assetProvider.isLoading
                      ? 'กำลังบันทึก...'
                      : widget.isEditMode
                          ? 'บันทึกการแก้ไข'
                          : 'บันทึกทรัพย์สิน',
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.isEditMode
                  ? 'ตรวจสอบข้อมูลให้เรียบร้อยก่อนบันทึกการแก้ไข'
                  : 'กรอกข้อมูลที่จำเป็นให้ครบก่อนบันทึก',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final hasValue = value != 'ยังไม่ได้เลือก';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: Icon(
            Icons.calendar_month_outlined,
            color: colorScheme.outline,
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: hasValue
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'เพิ่มรูปภาพ',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'แตะเพื่อถ่ายรูปหรือเลือกจาก Gallery',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokenImageView extends StatelessWidget {
  const _BrokenImageView({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 44,
              color: colorScheme.error,
            ),
            const SizedBox(height: 8),
            const Text('ไม่พบไฟล์รูปภาพ'),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.refresh),
              label: const Text('เลือกรูปใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  const _ImageActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        icon: Icon(icon),
      ),
    );
  }
}