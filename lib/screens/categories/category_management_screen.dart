import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/category_provider.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}
class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({
    required this.title,
    required this.initialName,
    required this.onCancel,
  });

  final String title;
  final String initialName;
  final VoidCallback onCancel;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
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
          labelText: 'ชื่อหมวดหมู่',
          hintText: 'เช่น เครื่องใช้ไฟฟ้า',
          prefixIcon: Icon(Icons.category_outlined),
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

class _CategoryManagementScreenState
    extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  Future<void> _showCategoryDialog({
  int? categoryId,
  String? initialName,
}) async {
  final isEditing = categoryId != null;

  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return _CategoryDialog(
        title: isEditing ? 'แก้ไขหมวดหมู่' : 'เพิ่มหมวดหมู่',
        initialName: initialName ?? '',
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
      'กรุณาระบุชื่อหมวดหมู่',
      isError: true,
    );
    return;
  }

  final provider = context.read<CategoryProvider>();

  final bool success = isEditing
      ? await provider.updateCategory(
          categoryId,
          trimmedName,
        )
      : await provider.addCategory(trimmedName);

  if (!mounted) {
    return;
  }

  if (success) {
    _showMessage(
      isEditing
          ? 'แก้ไขหมวดหมู่เรียบร้อยแล้ว'
          : 'เพิ่มหมวดหมู่เรียบร้อยแล้ว',
    );
  } else {
    _showMessage(
      provider.errorMessage ?? 'ไม่สามารถบันทึกหมวดหมู่ได้',
      isError: true,
    );
  }
}

  Future<void> _confirmDelete(
    int categoryId,
    String categoryName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบหมวดหมู่'),
          content: Text(
            'คุณต้องการลบหมวดหมู่ "$categoryName" หรือไม่?',
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

    final provider = context.read<CategoryProvider>();

    final success = await provider.deleteCategory(categoryId);

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage('ลบหมวดหมู่เรียบร้อยแล้ว');
    } else {
      _showMessage(
        provider.errorMessage ?? 'ไม่สามารถลบหมวดหมู่ได้',
        isError: true,
      );
    }
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
        title: const Text('จัดการหมวดหมู่'),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.categories.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: provider.loadCategories,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              itemCount: provider.categories.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 8);
              },
              itemBuilder: (context, index) {
                final category = provider.categories[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      child: const Icon(
                        Icons.category_outlined,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'สร้างเมื่อ ${_formatDate(category.createdAt)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'ตัวเลือก',
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showCategoryDialog(
                            categoryId: category.id,
                            initialName: category.name,
                          );
                        }

                        if (value == 'delete') {
                          _confirmDelete(
                            category.id,
                            category.name,
                          );
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('แก้ไข'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline),
                              title: Text('ลบ'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCategoryDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มหมวดหมู่'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีหมวดหมู่',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'เพิ่มหมวดหมู่เพื่อใช้จัดกลุ่มทรัพย์สินของคุณ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                _showCategoryDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มหมวดหมู่'),
            ),
          ],
        ),
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