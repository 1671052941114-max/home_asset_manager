import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/maintenance_records.dart';

part 'maintenance_dao.g.dart';

@DriftAccessor(tables: [MaintenanceRecords])
class MaintenanceDao extends DatabaseAccessor<AppDatabase>
    with _$MaintenanceDaoMixin {
  MaintenanceDao(super.db);

  /// ดึงประวัติการซ่อมทั้งหมดของทรัพย์สิน
  Future<List<MaintenanceRecord>> getByAssetId(
    int assetId,
  ) {
    return (select(maintenanceRecords)
          ..where(
            (table) => table.assetId.equals(assetId),
          )
          ..orderBy([
            (table) => OrderingTerm.desc(table.date),
            (table) => OrderingTerm.desc(table.id),
          ]))
        .get();
  }

  /// ดึงประวัติการซ่อมแบบ Stream
  Stream<List<MaintenanceRecord>> watchByAssetId(
    int assetId,
  ) {
    return (select(maintenanceRecords)
          ..where(
            (table) => table.assetId.equals(assetId),
          )
          ..orderBy([
            (table) => OrderingTerm.desc(table.date),
            (table) => OrderingTerm.desc(table.id),
          ]))
        .watch();
  }

  /// ดึงประวัติรายการเดียว
  Future<MaintenanceRecord?> getById(
    int id,
  ) {
    return (select(maintenanceRecords)
          ..where(
            (table) => table.id.equals(id),
          ))
        .getSingleOrNull();
  }

  /// เพิ่มประวัติการซ่อม
  Future<int> insertRecord(
    MaintenanceRecordsCompanion record,
  ) {
    return into(maintenanceRecords).insert(record);
  }

  /// แก้ไขประวัติการซ่อม
  Future<bool> updateRecord(
    MaintenanceRecordsCompanion record,
  ) {
    return update(maintenanceRecords).replace(record);
  }

  /// ลบประวัติการซ่อม
  Future<int> deleteRecord(
    int id,
  ) {
    return (delete(maintenanceRecords)
          ..where(
            (table) => table.id.equals(id),
          ))
        .go();
  }

  /// คำนวณค่าใช้จ่ายซ่อมทั้งหมดของทรัพย์สิน
  Future<double> getTotalCostByAssetId(
    int assetId,
  ) async {
    final records = await getByAssetId(assetId);

    return records.fold<double>(
      0,
      (total, record) => total + record.cost,
    );
  }
}