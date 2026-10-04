import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';

import '../data/database/app_database.dart';

class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  static const int backupVersion = 1;

  Future<Uri?> exportBackup() async {
    final categories = await _database.select(_database.categories).get();
    final locations = await _database.select(_database.locations).get();
    final assets = await _database.select(_database.assets).get();
    final maintenanceRecords =
        await _database.select(_database.maintenanceRecords).get();

    final backup = {
      'backupVersion': backupVersion,
      'appName': 'Home Asset Manager',
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories
          .map(
            (category) => {
              'id': category.id,
              'name': category.name,
              'createdAt': category.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'locations': locations
          .map(
            (location) => {
              'id': location.id,
              'name': location.name,
              'createdAt': location.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'assets': assets
          .map(
            (asset) => {
              'id': asset.id,
              'name': asset.name,
              'description': asset.description,
              'categoryId': asset.categoryId,
              'locationId': asset.locationId,
              'purchasePrice': asset.purchasePrice,
              'purchaseDate':
                  asset.purchaseDate?.toIso8601String(),
              'warrantyEndDate':
                  asset.warrantyEndDate?.toIso8601String(),
              'condition': asset.condition,
              'serialNumber': asset.serialNumber,
              'imagePath': asset.imagePath,
              'isFavorite': asset.isFavorite,
              'createdAt': asset.createdAt.toIso8601String(),
              'updatedAt': asset.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      'maintenanceRecords': maintenanceRecords
          .map(
            (record) => {
              'id': record.id,
              'assetId': record.assetId,
              'date': record.date.toIso8601String(),
              'type': record.type,
              'description': record.description,
              'cost': record.cost,
              'note': record.note,
              'createdAt': record.createdAt.toIso8601String(),
            },
          )
          .toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

    final defaultName =
        'home_asset_manager_backup_${_fileDate()}.json';

    final savedPath = await FilePicker.saveFile(
      dialogTitle: 'บันทึกข้อมูลสำรอง',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: utf8.encode(jsonString),
    );

    if (savedPath == null) {
      return null;
    }

    return savedPath;
  }

  Future<BackupPreview?> pickBackupFile() async {
  final files = await FilePicker.pickFiles(
    dialogTitle: 'เลือกไฟล์ข้อมูลสำรอง',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (files.isEmpty) {
    return null;
  }

  final file = files.first;

  final filePath = file.path;

  if (filePath == null || filePath.isEmpty) {
    throw const FormatException(
      'ไม่สามารถอ่านไฟล์ข้อมูลสำรองได้',
    );
  }

  final jsonText = await File(filePath).readAsString();

  final decoded = jsonDecode(jsonText);

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException(
      'รูปแบบไฟล์ข้อมูลสำรองไม่ถูกต้อง',
    );
  }

  _validateBackup(decoded);

  return BackupPreview(
    fileName: file.name,
    data: decoded,
  );
}

  Future<void> restoreBackup(
    Map<String, dynamic> data,
  ) async {
    _validateBackup(data);

    final categories =
        _parseCategories(data['categories']);

    final locations =
        _parseLocations(data['locations']);

    final assets =
        _parseAssets(data['assets']);

    final maintenanceRecords =
        _parseMaintenanceRecords(
      data['maintenanceRecords'],
    );

    await _database.transaction(() async {
      // ลบจากตารางลูกก่อน
      await _database.delete(
        _database.maintenanceRecords,
      ).go();

      await _database.delete(
        _database.assets,
      ).go();

      await _database.delete(
        _database.categories,
      ).go();

      await _database.delete(
        _database.locations,
      ).go();

      // เพิ่มตารางแม่ก่อน
      await _database.batch((batch) {
        batch.insertAll(
          _database.categories,
          categories,
        );

        batch.insertAll(
          _database.locations,
          locations,
        );

        batch.insertAll(
          _database.assets,
          assets,
        );

        batch.insertAll(
          _database.maintenanceRecords,
          maintenanceRecords,
        );
      });
    });
  }

  void _validateBackup(
    Map<String, dynamic> data,
  ) {
    final version = data['backupVersion'];

    if (version is! int) {
      throw const FormatException(
        'ไม่พบเวอร์ชันของไฟล์ข้อมูลสำรอง',
      );
    }

    if (version != backupVersion) {
      throw FormatException(
        'ไม่รองรับไฟล์ข้อมูลสำรองเวอร์ชัน $version',
      );
    }

    const requiredKeys = [
      'categories',
      'locations',
      'assets',
      'maintenanceRecords',
    ];

    for (final key in requiredKeys) {
      if (data[key] is! List) {
        throw FormatException(
          'ข้อมูล "$key" ในไฟล์ไม่ถูกต้อง',
        );
      }
    }
  }

  List<CategoriesCompanion> _parseCategories(
    dynamic value,
  ) {
    final list = value as List;

    return list.map((item) {
      final map = _asMap(item);

      return CategoriesCompanion.insert(
        id: Value(_requiredInt(map, 'id')),
        name: _requiredString(map, 'name'),
        createdAt: _requiredDateTime(map, 'createdAt'),
      );
    }).toList();
  }

  List<LocationsCompanion> _parseLocations(
    dynamic value,
  ) {
    final list = value as List;

    return list.map((item) {
      final map = _asMap(item);

      return LocationsCompanion.insert(
        id: Value(_requiredInt(map, 'id')),
        name: _requiredString(map, 'name'),
        createdAt: _requiredDateTime(map, 'createdAt'),
      );
    }).toList();
  }

  List<AssetsCompanion> _parseAssets(
    dynamic value,
  ) {
    final list = value as List;

    return list.map((item) {
      final map = _asMap(item);

      return AssetsCompanion.insert(
        id: Value(_requiredInt(map, 'id')),
        name: _requiredString(map, 'name'),
        description: Value(
          map['description'] as String?,
        ),
        categoryId: _requiredInt(
          map,
          'categoryId',
        ),
        locationId: _requiredInt(
          map,
          'locationId',
        ),
        purchasePrice: _requiredDouble(
          map,
          'purchasePrice',
        ),
        purchaseDate: Value(
          _optionalDateTime(
            map['purchaseDate'],
          ),
        ),
        warrantyEndDate: Value(
          _optionalDateTime(
            map['warrantyEndDate'],
          ),
        ),
        condition: _requiredString(
          map,
          'condition',
        ),
        serialNumber: Value(
          map['serialNumber'] as String?,
        ),
        imagePath: Value(
          map['imagePath'] as String?,
        ),
        isFavorite: Value(
          map['isFavorite'] == true,
        ),
        createdAt: _requiredDateTime(
          map,
          'createdAt',
        ),
        updatedAt: _requiredDateTime(
          map,
          'updatedAt',
        ),
      );
    }).toList();
  }

  List<MaintenanceRecordsCompanion>
      _parseMaintenanceRecords(
    dynamic value,
  ) {
    final list = value as List;

    return list.map((item) {
      final map = _asMap(item);

      return MaintenanceRecordsCompanion.insert(
        id: Value(_requiredInt(map, 'id')),
        assetId: _requiredInt(
          map,
          'assetId',
        ),
        date: _requiredDateTime(
          map,
          'date',
        ),
        type: _requiredString(
          map,
          'type',
        ),
        description: Value(
          map['description'] as String?,
        ),
        cost: Value(
          _requiredDouble(map, 'cost'),
        ),
        note: Value(
          map['note'] as String?,
        ),
        createdAt: _requiredDateTime(
          map,
          'createdAt',
        ),
      );
    }).toList();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is! Map) {
      throw const FormatException(
        'พบข้อมูลบางรายการที่มีรูปแบบไม่ถูกต้อง',
      );
    }

    return Map<String, dynamic>.from(value);
  }

  int _requiredInt(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = map[key];

    if (value is int) {
      return value;
    }

    throw FormatException(
      'ข้อมูล "$key" ไม่ถูกต้อง',
    );
  }

  double _requiredDouble(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = map[key];

    if (value is num) {
      return value.toDouble();
    }

    throw FormatException(
      'ข้อมูล "$key" ไม่ถูกต้อง',
    );
  }

  String _requiredString(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = map[key];

    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException(
      'ข้อมูล "$key" ไม่ถูกต้อง',
    );
  }

  DateTime _requiredDateTime(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = map[key];

    if (value is String) {
      final date = DateTime.tryParse(value);

      if (date != null) {
        return date;
      }
    }

    throw FormatException(
      'ข้อมูล "$key" ไม่ถูกต้อง',
    );
  }

  DateTime? _optionalDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    throw const FormatException(
      'รูปแบบวันที่ไม่ถูกต้อง',
    );
  }

  String _fileDate() {
    final now = DateTime.now();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${now.year}'
        '${twoDigits(now.month)}'
        '${twoDigits(now.day)}_'
        '${twoDigits(now.hour)}'
        '${twoDigits(now.minute)}'
        '${twoDigits(now.second)}';
  }
}

class BackupPreview {
  const BackupPreview({
    required this.fileName,
    required this.data,
  });

  final String fileName;
  final Map<String, dynamic> data;

  int get categoryCount =>
      (data['categories'] as List).length;

  int get locationCount =>
      (data['locations'] as List).length;

  int get assetCount =>
      (data['assets'] as List).length;

  int get maintenanceCount =>
      (data['maintenanceRecords'] as List).length;
}