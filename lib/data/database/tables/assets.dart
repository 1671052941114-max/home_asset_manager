import 'package:drift/drift.dart';

import 'categories.dart';
import 'locations.dart';

class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  IntColumn get categoryId =>
      integer().references(Categories, #id)();

  IntColumn get locationId =>
      integer().references(Locations, #id)();

  RealColumn get purchasePrice => real()();

  DateTimeColumn get purchaseDate => dateTime().nullable()();

  DateTimeColumn get warrantyEndDate => dateTime().nullable()();

  TextColumn get condition => text()();

  TextColumn get serialNumber => text().nullable().unique()();

  TextColumn get imagePath => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}