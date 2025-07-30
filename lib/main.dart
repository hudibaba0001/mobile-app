import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Old models (kept for migration compatibility)
import 'models/travel_time_entry.dart';
import 'models/location.dart';
// New unified Entry model
import 'models/entry.dart';
// Migration service
import 'services/entry_migration_service.dart';
// New unified services (replacing old TravelService)
import 'services/entry_service.dart';
import 'services/sync_service.dart';
// App configuration
import 'utils/constants.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
// Updated providers (EntryProvider replaces TravelProvider)
import 'providers/entry_provider.dart';
import 'providers/location_provider.dart';
import 'providers/search_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/app_state_provider.dart';
// New settings and contract providers
import 'providers/settings_provider.dart';
import 'providers/contract_provider.dart';
// Repositories (still needed for location management)
import 'repositories/hive_location_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive and register adapters
  await Hive.initFlutter();
  
  // Register old adapters (kept for migration compatibility)
  Hive.registerAdapter(TravelTimeEntryAdapter());
  Hive.registerAdapter(LocationAdapter());
  
  // Register new unified Entry adapters
  Hive.registerAdapter(EntryAdapter());
  Hive.registerAdapter(EntryTypeAdapter());
  Hive.registerAdapter(ShiftAdapter());
  
  // Initialize services before creating providers
  final entryService = EntryService();
  final syncService = SyncService();
  
  // Access shared preferences for migration flag
  final prefs = await SharedPreferences.getInstance();
  final didMigrate = prefs.getBool('didMigrate') ?? false;
  
  // If not migrated, show migration flow
  if (!didMigrate) {
    runApp(MaterialApp(
      title: 'Travel Time Logger - Migration',
      theme: ThemeData.light(),
      home: _MigrationScreen(onComplete: () async {
        // Mark migration as done and start app
        await prefs.setBool('didMigrate', true);
        runApp(_buildMainApp(entryService, syncService));
      }),
    ));
  } else {
    // Normal app startup with unified services
    runApp(_buildMainApp(entryService, syncService));
  }
}

/// Build the main app with all providers using unified Entry model
/// Updated to use EntryProvider instead of TravelProvider
Widget _buildMainApp(EntryService entryService, SyncService syncService) {
  return MultiProvider(
    providers: [
      // Core app providers (settings must be initialized early)
      ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
      ChangeNotifierProvider(create: (_) => ContractProvider()..init()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AppStateProvider()),
      
      // Service providers (dependency injection)
      Provider<EntryService>.value(value: entryService),
      Provider<SyncService>.value(value: syncService),
      
      // Repository providers
      Provider<HiveLocationRepository>(
        create: (_) => HiveLocationRepository(),
      ),
      
      // State management providers (EntryProvider replaces TravelProvider)
      ChangeNotifierProvider(
        create: (_) => EntryProvider(
          entryService: entryService,
        ),
      ),
      
      // Location provider (updated to work with new architecture)
      ChangeNotifierProxyProvider<HiveLocationRepository, LocationProvider>(
        create: (context) => LocationProvider(
          repository: Provider.of<HiveLocationRepository>(context, listen: false),
        ),
        update: (context, repository, previous) => 
            previous ?? LocationProvider(repository: repository),
      ),
      
      // UI state providers
      ChangeNotifierProvider(create: (_) => SearchProvider()),
      ChangeNotifierProvider(create: (_) => FilterProvider()),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    ),
  );
}

/// A simple full-screen widget that runs migration, showing progress and errors if any.
class _MigrationScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const _MigrationScreen({required this.onComplete});
  
  @override
  State<_MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<_MigrationScreen> {
  String _message = 'Preparing migration...';
  bool _isComplete = false;
  
  @override
  void initState() {
    super.initState();
    _runMigration();
  }
  
  Future<void> _runMigration() async {
    try {
      setState(() => _message = 'Migrating data...');
      
      final migrationService = EntryMigrationService();
      final result = await migrationService.migrate();
      
      setState(() {
        _message = 'Migrated ${result.migrationCount} entries in ${result.duration.inSeconds}s';
        _isComplete = true;
      });
      
    } catch (e) {
      setState(() {
        _message = 'Migration failed: $e';
        _isComplete = true;
      });
    }
    
    // Short delay to let user read the message
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      widget.onComplete();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isComplete) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
            ],
            Text(
              _message,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (_isComplete) ...[
              const SizedBox(height: 16),
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}