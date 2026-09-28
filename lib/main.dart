import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database_provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDatabaseProvider = await AppDatabaseProvider.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: appDatabaseProvider.assetProvider,
        ),
        ChangeNotifierProvider.value(
          value: appDatabaseProvider.categoryProvider,
        ),
        ChangeNotifierProvider.value(
          value: appDatabaseProvider.locationProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const HomeAssetManagerApp(),
    ),
  );
}

class HomeAssetManagerApp extends StatelessWidget {
  const HomeAssetManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Home Asset Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      home: const AppShell(),
    );
  }
}