import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import '../data/database/app_database.dart';
import '../repositories/maintenance_repository.dart';

class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider(this._repository);

  final MaintenanceRepository _repository;

  List<MaintenanceRecord> _records = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  double _totalCost = 0;

  List<MaintenanceRecord> get records =>
      List.unmodifiable(_records);

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  double get totalCost => _totalCost;

  /// โหลดประวัติการซ่อมของทรัพย์สิน
  Future<void> loadRecords(int assetId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await _repository.getByAssetId(assetId);
      _totalCost = await _repository.getTotalCostByAssetId(assetId);
    } catch (error) {
      _errorMessage = 'ไม่สามารถโหลดประวัติการซ่อมได้';
      debugPrint(
        'MaintenanceProvider.loadRecords: $error',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// เพิ่มประวัติการซ่อม
  Future<bool> addRecord({
    required int assetId,
    required DateTime date,
    required String type,
    String? description,
    required double cost,
    String? note,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final record = MaintenanceRecordsCompanion(
        assetId: Value(assetId),
        date: Value(date),
        type: Value(type),
        description: Value(
          _nullableText(description),
        ),
        cost: Value(cost),
        note: Value(
          _nullableText(note),
        ),
        createdAt: Value(DateTime.now()),
      );

      await _repository.insertRecord(record);

      await _refreshRecords(assetId);

      return true;
    } catch (error) {
      _errorMessage = 'ไม่สามารถเพิ่มประวัติการซ่อมได้';

      debugPrint(
        'MaintenanceProvider.addRecord: $error',
      );

      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// แก้ไขประวัติการซ่อม
  Future<bool> updateRecord({
    required int assetId,
    required int recordId,
    required DateTime date,
    required String type,
    String? description,
    required double cost,
    String? note,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existing = await _repository.getById(recordId);

      if (existing == null) {
        _errorMessage = 'ไม่พบประวัติการซ่อมที่ต้องการแก้ไข';
        return false;
      }

      final record = MaintenanceRecordsCompanion(
        id: Value(recordId),
        assetId: Value(assetId),
        date: Value(date),
        type: Value(type),
        description: Value(
          _nullableText(description),
        ),
        cost: Value(cost),
        note: Value(
          _nullableText(note),
        ),
        createdAt: Value(existing.createdAt),
      );

      final updated = await _repository.updateRecord(record);

      if (!updated) {
        _errorMessage = 'ไม่สามารถแก้ไขประวัติการซ่อมได้';
        return false;
      }

      await _refreshRecords(assetId);

      return true;
    } catch (error) {
      _errorMessage = 'ไม่สามารถแก้ไขประวัติการซ่อมได้';

      debugPrint(
        'MaintenanceProvider.updateRecord: $error',
      );

      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// ลบประวัติการซ่อม
  Future<bool> deleteRecord({
    required int assetId,
    required int recordId,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deletedRows = await _repository.deleteRecord(
        recordId,
      );

      if (deletedRows == 0) {
        _errorMessage = 'ไม่พบประวัติการซ่อมที่ต้องการลบ';
        return false;
      }

      await _refreshRecords(assetId);

      return true;
    } catch (error) {
      _errorMessage = 'ไม่สามารถลบประวัติการซ่อมได้';

      debugPrint(
        'MaintenanceProvider.deleteRecord: $error',
      );

      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _refreshRecords(int assetId) async {
    _records = await _repository.getByAssetId(assetId);

    _totalCost = await _repository.getTotalCostByAssetId(
      assetId,
    );
  }

  String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }
}