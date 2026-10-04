import 'package:drift/wasm.dart';

import 'app_database.dart';

Future<AppDatabase> openDatabase() async {
  final result = await WasmDatabase.open(
    databaseName: 'home_asset_manager',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );

  return AppDatabase(
    result.resolvedExecutor,
  );
}