import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:home_asset_manager/data/database/app_database.dart';
import 'package:home_asset_manager/data/database/daos/asset_dao.dart';
import 'package:home_asset_manager/data/database/daos/category_dao.dart';
import 'package:home_asset_manager/data/database/daos/location_dao.dart';
import 'package:home_asset_manager/providers/asset_provider.dart';
import 'package:home_asset_manager/providers/category_provider.dart';
import 'package:home_asset_manager/providers/location_provider.dart';
import 'package:home_asset_manager/providers/theme_provider.dart';
import 'package:home_asset_manager/repositories/asset_repository.dart';
import 'package:home_asset_manager/repositories/category_repository.dart';
import 'package:home_asset_manager/repositories/location_repository.dart';
import 'package:home_asset_manager/main.dart';

void main() {
  testWidgets('Home Asset Manager loads', (tester) async {
    final database = AppDatabase(
      NativeDatabase.memory(),
    );

    final assetRepository = AssetRepository(
      AssetDao(database),
    );

    final categoryRepository = CategoryRepository(
      CategoryDao(database),
    );

    final locationRepository = LocationRepository(
      LocationDao(database),
    );

    final assetProvider = AssetProvider(
      assetRepository,
    );

    final categoryProvider = CategoryProvider(
      categoryRepository,
    );

    final locationProvider = LocationProvider(
      locationRepository,
    );

    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: assetProvider,
          ),
          ChangeNotifierProvider.value(
            value: categoryProvider,
          ),
          ChangeNotifierProvider.value(
            value: locationProvider,
          ),
          ChangeNotifierProvider.value(
            value: themeProvider,
          ),
        ],
        child: const HomeAssetManagerApp(),
      ),
    );

    await tester.pump();

    expect(
      find.text('Home Asset Manager'),
      findsOneWidget,
    );

    await database.close();
  });
}