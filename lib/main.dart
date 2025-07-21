import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/travel_time_entry.dart';
import 'models/location.dart';
import 'services/migration_service.dart';
import 'utils/constants.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'providers/travel_provider.dart';
import 'providers/location_provider.dart';
import 'providers/search_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/app_state_provider.dart';
import 'repositories/hive_travel_repository.dart';
import 'repositories/hive_location_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(TravelTimeEntryAdapter());
  Hive.registerAdapter(LocationAdapter());
  
  // Open boxes
  await Hive.openBox<TravelTimeEntry>(AppConstants.travelEntriesBox);
  await Hive.openBox<Location>(AppConstants.locationsBox);
  
  // Run migration if needed
  await MigrationService.migrateIfNeeded();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories
        Provider<HiveTravelRepository>(
          create: (_) => HiveTravelRepository(),
        ),
        Provider<HiveLocationRepository>(
          create: (_) => HiveLocationRepository(),
        ),
        
        // State providers
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<AppStateProvider>(
          create: (_) => AppStateProvider(),
        ),
        ChangeNotifierProxyProvider<HiveTravelRepository, TravelProvider>(
          create: (context) => TravelProvider(
            repository: Provider.of<HiveTravelRepository>(context, listen: false),
          ),
          update: (context, repository, previous) => previous ?? TravelProvider(repository: repository),
        ),
        ChangeNotifierProxyProvider<HiveLocationRepository, LocationProvider>(
          create: (context) => LocationProvider(
            repository: Provider.of<HiveLocationRepository>(context, listen: false),
          ),
          update: (context, repository, previous) => previous ?? LocationProvider(repository: repository),
        ),
        ChangeNotifierProvider<SearchProvider>(
          create: (_) => SearchProvider(),
        ),
        ChangeNotifierProvider<FilterProvider>(
          create: (_) => FilterProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Travel Time Tracker',
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
}





