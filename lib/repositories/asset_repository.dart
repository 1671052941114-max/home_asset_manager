import '../data/database/app_database.dart';
import '../data/database/daos/asset_dao.dart';

class AssetRepository {
  AssetRepository(this._dao);

  final AssetDao _dao;

  Future<List<Asset>> getAllAssets() {
    return _dao.getAllAssets();
  }

  Stream<List<Asset>> watchAllAssets() {
    return _dao.watchAllAssets();
  }

  Future<Asset?> getAssetById(int id) {
    return _dao.getAssetById(id);
  }

  Future<int> insertAsset(AssetsCompanion asset) {
    return _dao.insertAsset(asset);
  }

  Future<bool> updateAsset(AssetsCompanion asset) {
    return _dao.updateAsset(asset);
  }

  Future<int> deleteAsset(int id) {
    return _dao.deleteAsset(id);
  }
}