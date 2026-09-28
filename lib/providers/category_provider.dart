import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../data/database/app_database.dart';
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._repository);

  final CategoryRepository _repository;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => List.unmodifiable(_categories);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadCategories() async {
    _setLoading(true);

    try {
      _errorMessage = null;
      _categories = await _repository.getAllCategories();
    } catch (error) {
      _errorMessage = 'ไม่สามารถโหลดหมวดหมู่ได้';
      debugPrint('CategoryProvider.loadCategories: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addCategory(String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      _errorMessage = 'กรุณาระบุชื่อหมวดหมู่';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.insertCategory(
        CategoriesCompanion.insert(
          name: trimmedName,
          createdAt: DateTime.now(),
        ),
      );

      _categories = await _repository.getAllCategories();

      return true;
    } catch (error) {
      _errorMessage = _getCategoryError(error);
      debugPrint('CategoryProvider.addCategory: $error');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCategory(int id, String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      _errorMessage = 'กรุณาระบุชื่อหมวดหมู่';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      _errorMessage = null;

      final existingCategory = await _findCategory(id);

      if (existingCategory == null) {
        _errorMessage = 'ไม่พบหมวดหมู่ที่ต้องการแก้ไข';
        return false;
      }

      final updatedCategory = CategoriesCompanion(
        id: Value(existingCategory.id),
        name: Value(trimmedName),
        createdAt: Value(existingCategory.createdAt),
      );

      await _repository.updateCategory(updatedCategory);

      _categories = await _repository.getAllCategories();

      return true;
    } catch (error) {
      _errorMessage = _getCategoryError(error);
      debugPrint('CategoryProvider.updateCategory: $error');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCategory(int id) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final deleted = await _repository.deleteCategory(id);

      if (!deleted) {
        _errorMessage =
            'ไม่สามารถลบหมวดหมู่นี้ได้ เนื่องจากมีทรัพย์สินใช้งานอยู่';
        return false;
      }

      _categories = await _repository.getAllCategories();

      return true;
    } catch (error) {
      _errorMessage = _getCategoryError(error);
      debugPrint('CategoryProvider.deleteCategory: $error');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<Category?> _findCategory(int id) async {
    for (final category in _categories) {
      if (category.id == id) {
        return category;
      }
    }

    return null;
  }

  String _getCategoryError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('unique') || message.contains('constraint')) {
      return 'มีหมวดหมู่นี้อยู่แล้ว';
    }

    return 'เกิดข้อผิดพลาดในการจัดการหมวดหมู่';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}