import 'package:drift/drift.dart';

import 'assets.dart';

class MaintenanceRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get assetId =>
      integer().references(Assets, #id)();

  DateTimeColumn get date => dateTime()();

  TextColumn get type => text()();

  TextColumn get description => text().nullable()();

  RealColumn get cost => real().withDefault(
        const Constant(0),
      )();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}