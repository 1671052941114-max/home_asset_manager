import '../data/database/app_database.dart';
import '../data/database/daos/category_dao.dart';

class CategoryRepository {
  CategoryRepository(this._dao);

  final CategoryDao _dao;

  Future<List<Category>> getAllCategories() {
    return _dao.getAllCategories();
  }

  Stream<List<Category>> watchAllCategories() {
    return _dao.watchAllCategories();
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return _dao.insertCategory(category);
  }

  Future<bool> updateCategory(CategoriesCompanion category) {
    return _dao.updateCategory(category);
  }

  Future<bool> deleteCategory(int id) {
    return _dao.deleteCategory(id);
  }
}