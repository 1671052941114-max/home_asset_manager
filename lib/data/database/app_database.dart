import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/asset_dao.dart';
import 'daos/category_dao.dart';
import 'daos/location_dao.dart';
import 'tables/assets.dart';
import 'tables/categories.dart';
import 'tables/locations.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    Locations,
    Assets,
  ],
  daos: [
    AssetDao,
    CategoryDao,
    LocationDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static Future<AppDatabase> open() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      p.join(
        directory.path,
        'home_asset_manager.sqlite',
      ),
    );

    return AppDatabase(
      NativeDatabase.createInBackground(file),
    );
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Database schema is still under development.
          //
          // Future schema changes will be handled here
          // with explicit migrations.
        },
      );
}