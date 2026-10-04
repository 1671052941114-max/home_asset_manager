import '../data/database/app_database.dart';
import '../data/database/daos/maintenance_dao.dart';

class MaintenanceRepository {
  MaintenanceRepository(this._dao);

  final MaintenanceDao _dao;

  Future<List<MaintenanceRecord>> getByAssetId(
    int assetId,
  ) {
    return _dao.getByAssetId(assetId);
  }

  Stream<List<MaintenanceRecord>> watchByAssetId(
    int assetId,
  ) {
    return _dao.watchByAssetId(assetId);
  }

  Future<MaintenanceRecord?> getById(
    int id,
  ) {
    return _dao.getById(id);
  }

  Future<int> insertRecord(
    MaintenanceRecordsCompanion record,
  ) {
    return _dao.insertRecord(record);
  }

  Future<bool> updateRecord(
    MaintenanceRecordsCompanion record,
  ) {
    return _dao.updateRecord(record);
  }

  Future<int> deleteRecord(
    int id,
  ) {
    return _dao.deleteRecord(id);
  }

  Future<double> getTotalCostByAssetId(
    int assetId,
  ) {
    return _dao.getTotalCostByAssetId(assetId);
  }
}