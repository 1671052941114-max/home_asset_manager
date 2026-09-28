import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/assets.dart';
import '../tables/categories.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories, Assets])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAllCategories() {
    return (select(categories)
          ..orderBy([
            (table) => OrderingTerm.asc(table.name),
          ]))
        .get();
  }

  Stream<List<Category>> watchAllCategories() {
    return (select(categories)
          ..orderBy([
            (table) => OrderingTerm.asc(table.name),
          ]))
        .watch();
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  Future<bool> updateCategory(CategoriesCompanion category) {
    return update(categories).replace(category);
  }

  Future<bool> isCategoryInUse(int categoryId) async {
    final query = select(assets)
      ..where((table) => table.categoryId.equals(categoryId))
      ..limit(1);

    final asset = await query.getSingleOrNull();

    return asset != null;
  }

  Future<bool> deleteCategory(int id) async {
    final inUse = await isCategoryInUse(id);

    if (inUse) {
      return false;
    }

    final deletedRows =
        await (delete(categories)..where((table) => table.id.equals(id))).go();

    return deletedRows > 0;
  }
}