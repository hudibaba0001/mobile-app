import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
// Firebase services
import 'services/auth_service.dart';
import 'services/storage_service.dart';
// Dummy services for testing (keeping for debug purposes)
import 'services/dummy_auth_service.dart';
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

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive and register adapters
  await Hive.initFlutter();

  // Register old adapters (kept for migration compatibility)
  Hive.registerAdapter(TravelTimeEntryAdapter());
  Hive.registerAdapter(LocationAdapter());

  // Register new unified Entry adapters
  Hive.registerAdapter(EntryAdapter());
  Hive.registerAdapter(EntryTypeAdapter());
  Hive.registerAdapter(ShiftAdapter());

  // Open Hive boxes
  await Future.wait([
    Hive.openBox<Location>(AppConstants.locationsBox),
    Hive.openBox<TravelTimeEntry>(AppConstants.travelEntriesBox),
    Hive.openBox(AppConstants.appSettingsBox),
  ]);

  // Initialize repositories and services
  final locationRepository = HiveLocationRepository();
  final entryService = EntryService(locationRepository: locationRepository);
  final syncService = SyncService();
  // Initialize services (using real Firebase auth)
  final authService = AuthService();
  final storageService = StorageService();

  // Keep dummy auth service for debug purposes
  final dummyAuthService = DummyAuthService();
  await dummyAuthService.initialize();

  // Access shared preferences for migration flag
  final prefs = await SharedPreferences.getInstance();
  final didMigrate = prefs.getBool('didMigrate') ?? false;

  // If not migrated, show migration flow
  if (!didMigrate) {
    runApp(
      MaterialApp(
        title: 'Travel Time Logger - Migration',
        theme: ThemeData.light(),
        home: _MigrationScreen(
          onComplete: () async {
            // Mark migration as done and start app
            await prefs.setBool('didMigrate', true);
            runApp(
              _buildMainApp(
                entryService,
                syncService,
                authService,
                storageService,
                dummyAuthService,
              ),
            );
          },
        ),
      ),
    );
  } else {
    // Normal app startup with unified services
    runApp(
      _buildMainApp(
        entryService,
        syncService,
        authService,
        storageService,
        dummyAuthService,
      ),
    );
  }
}

/// Build the main app with all providers using unified Entry model
/// Updated to use EntryProvider instead of TravelProvider
Widget _buildMainApp(
  EntryService entryService,
  SyncService syncService,
  AuthService authService,
  StorageService storageService,
  DummyAuthService dummyAuthService,
) {
  return MultiProvider(
    providers: [
      // Core app providers (settings must be initialized early)
      ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
      ChangeNotifierProvider(create: (_) => ContractProvider()..init()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      // Authentication services
      Provider<AuthService>.value(value: authService),
      ChangeNotifierProvider<DummyAuthService>.value(value: dummyAuthService),
      ChangeNotifierProvider(create: (_) => AppStateProvider()),

      // Service providers (dependency injection)
      Provider<EntryService>.value(value: entryService),
      Provider<SyncService>.value(value: syncService),
      // Storage service provider
      Provider<StorageService>.value(value: storageService),

      // Repository providers
      Provider<HiveLocationRepository>(create: (_) => HiveLocationRepository()),

      // State management providers (EntryProvider replaces TravelProvider)
      ChangeNotifierProvider(
        create: (_) => EntryProvider(entryService: entryService),
      ),

      // Location provider (updated to work with new architecture)
      ChangeNotifierProxyProvider<HiveLocationRepository, LocationProvider>(
        create: (context) => LocationProvider(
          repository: Provider.of<HiveLocationRepository>(
            context,
            listen: false,
          ),
        ),
        update: (context, repository, previous) =>
            previous ?? LocationProvider(repository: repository),
      ),

      // UI state providers
      ChangeNotifierProvider(create: (_) => SearchProvider()),
      ChangeNotifierProvider(create: (_) => FilterProvider()),
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
        _message =
            'Migrated ${result.migrationCount} entries in ${result.duration.inSeconds}s';
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
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ],
          ],
        ),
      ),
    );
  }
}
