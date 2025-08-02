import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// Old models (kept for migration compatibility)
import 'models/travel_time_entry.dart';
// Firebase services
import 'services/auth_service.dart';
import 'services/admin_api_service.dart';
// App configuration
import 'utils/constants.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
// Providers
import 'providers/theme_provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/contract_provider.dart';
import 'providers/location_provider.dart';
import 'providers/travel_provider.dart';
import 'viewmodels/analytics_view_model.dart';
// Repositories
import 'repositories/repository_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize repositories
  final repositoryProvider = RepositoryProvider();
  await repositoryProvider.initialize();

  // Initialize services
  final authService = AuthService();
  final adminApiService = AdminApiService();

  // Start the app
  runApp(
    _buildMainApp(
      authService,
      repositoryProvider,
      adminApiService,
    ),
  );
}

/// Build the main app with all providers using unified Entry model
/// Updated to use EntryProvider instead of TravelProvider
Widget _buildMainApp(
  AuthService authService,
  RepositoryProvider repositoryProvider,
  AdminApiService adminApiService,
) {
  return MultiProvider(
    providers: [
      // Core app providers
      ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
      ChangeNotifierProvider(create: (_) => ContractProvider()..init()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LocationProvider()),
      ChangeNotifierProvider(create: (_) => TravelProvider()),
      ChangeNotifierProvider(create: (_) => AnalyticsViewModel(adminApiService)),
      // Authentication services
      Provider<AuthService>.value(value: authService),
      ChangeNotifierProvider(create: (_) => AppStateProvider()),
      // Repository provider
      Provider<RepositoryProvider>.value(value: repositoryProvider),
      // API services
      Provider<AdminApiService>.value(value: adminApiService),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          title: 'KvikTime',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    ),
  );
}


