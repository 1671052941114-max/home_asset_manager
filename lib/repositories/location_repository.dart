import '../data/database/app_database.dart';
import '../data/database/daos/location_dao.dart';

class LocationRepository {
  LocationRepository(this._dao);

  final LocationDao _dao;

  Future<List<Location>> getAllLocations() {
    return _dao.getAllLocations();
  }

  Stream<List<Location>> watchAllLocations() {
    return _dao.watchAllLocations();
  }

  Future<int> insertLocation(LocationsCompanion location) {
    return _dao.insertLocation(location);
  }

  Future<bool> updateLocation(LocationsCompanion location) {
    return _dao.updateLocation(location);
  }

  Future<bool> deleteLocation(int id) {
    return _dao.deleteLocation(id);
  }
}