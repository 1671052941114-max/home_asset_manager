import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/assets.dart';
import '../tables/locations.dart';

part 'location_dao.g.dart';

@DriftAccessor(tables: [Locations, Assets])
class LocationDao extends DatabaseAccessor<AppDatabase>
    with _$LocationDaoMixin {
  LocationDao(super.db);

  Future<List<Location>> getAllLocations() {
    return (select(locations)
          ..orderBy([
            (table) => OrderingTerm.asc(table.name),
          ]))
        .get();
  }

  Stream<List<Location>> watchAllLocations() {
    return (select(locations)
          ..orderBy([
            (table) => OrderingTerm.asc(table.name),
          ]))
        .watch();
  }

  Future<int> insertLocation(LocationsCompanion location) {
    return into(locations).insert(location);
  }

  Future<bool> updateLocation(LocationsCompanion location) {
    return update(locations).replace(location);
  }

  Future<bool> isLocationInUse(int locationId) async {
    final query = select(assets)
      ..where((table) => table.locationId.equals(locationId))
      ..limit(1);

    final asset = await query.getSingleOrNull();

    return asset != null;
  }

  Future<bool> deleteLocation(int id) async {
    final inUse = await isLocationInUse(id);

    if (inUse) {
      return false;
    }

    final deletedRows =
        await (delete(locations)..where((table) => table.id.equals(id))).go();

    return deletedRows > 0;
  }
}