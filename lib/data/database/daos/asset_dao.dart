import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/assets.dart';

part 'asset_dao.g.dart';

@DriftAccessor(tables: [Assets])
class AssetDao extends DatabaseAccessor<AppDatabase>
    with _$AssetDaoMixin {
  AssetDao(super.db);

  Future<List<Asset>> getAllAssets() {
    return (select(assets)
          ..orderBy([
            (table) => OrderingTerm.desc(table.createdAt),
          ]))
        .get();
  }

  Stream<List<Asset>> watchAllAssets() {
    return (select(assets)
          ..orderBy([
            (table) => OrderingTerm.desc(table.createdAt),
          ]))
        .watch();
  }

  Future<Asset?> getAssetById(int id) {
    return (select(assets)..where((table) => table.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertAsset(AssetsCompanion asset) {
    return into(assets).insert(asset);
  }

  Future<bool> updateAsset(AssetsCompanion asset) {
    return update(assets).replace(asset);
  }

  Future<int> deleteAsset(int id) {
    return (delete(assets)..where((table) => table.id.equals(id))).go();
  }
}