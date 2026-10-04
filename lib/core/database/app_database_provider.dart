import '../../data/database/app_database.dart';
import '../../data/database/daos/asset_dao.dart';
import '../../data/database/daos/category_dao.dart';
import '../../data/database/daos/location_dao.dart';
import '../../repositories/asset_repository.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/location_repository.dart';
import '../../providers/asset_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../repositories/maintenance_repository.dart';
import '../../data/database/daos/maintenance_dao.dart';

class AppDatabaseProvider {
  AppDatabaseProvider._(this.database);

  final AppDatabase database;

  late final AssetRepository assetRepository = AssetRepository(
    AssetDao(database),
  );

  late final CategoryRepository categoryRepository = CategoryRepository(
    CategoryDao(database),
  );

  late final LocationRepository locationRepository = LocationRepository(
    LocationDao(database),
  );

  late final AssetProvider assetProvider = AssetProvider(
    assetRepository,
  );

  late final CategoryProvider categoryProvider = CategoryProvider(
    categoryRepository,
  );

  late final LocationProvider locationProvider = LocationProvider(
    locationRepository,
  );
  late final MaintenanceRepository maintenanceRepository =
    MaintenanceRepository(
  MaintenanceDao(database),
);

late final MaintenanceProvider maintenanceProvider =
    MaintenanceProvider(
  maintenanceRepository,
);

  static Future<AppDatabaseProvider> create() async {
    final database = await AppDatabase.open();

    return AppDatabaseProvider._(database);
  }

  Future<void> close() {
    return database.close();
  }
}