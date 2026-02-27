// ignore_for_file: avoid_print
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'config/supabase_config.dart';
import 'config/app_router_prod.dart';
import 'config/app_theme.dart';
import 'providers/app_state_provider.dart';
import 'providers/contract_provider.dart';
import 'providers/local_entry_provider.dart';
import 'providers/network_status_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/travel_provider.dart';
import 'providers/entry_provider.dart';
import 'providers/location_provider.dart';
import 'providers/time_provider.dart';
import 'providers/absence_provider.dart';
import 'providers/balance_adjustment_provider.dart';
import 'services/supabase_auth_service.dart';
import 'repositories/balance_adjustment_repository.dart';
import 'repositories/supabase_location_repository.dart';
import 'services/supabase_absence_service.dart';
import 'repositories/user_red_day_repository.dart';
import 'services/holiday_service.dart';
import 'services/reminder_service.dart';
import 'services/travel_cache_service.dart';
import 'services/legacy_hive_migration_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/sync_queue_service.dart';
import 'repositories/location_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/entry.dart';
import 'models/location.dart';
import 'models/absence.dart';
import 'models/balance_adjustment.dart';
import 'models/user_red_day.dart';
import 'models/absence_entry_adapter.dart';
import 'models/balance_adjustment_adapter.dart';
import 'models/user_red_day_adapter.dart';
import 'utils/constants.dart';

void _configureReleaseLogging() {
  if (!kReleaseMode) return;
  debugPrint = (String? message, {int? wrapWidth}) {};
}

const _startupNetworkTimeout = Duration(seconds: 15);
const _startupMigrationTimeout = Duration(seconds: 20);

void main() async {
  // Add this line to use "clean" URLs
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();
  _configureReleaseLogging();

  await CrashReportingService.initialize(entrypoint: 'main_prod');

  try {
    await _bootstrapAndRunApp();
  } catch (error, stackTrace) {
    await CrashReportingService.recordFatal(
      error,
      stackTrace,
      reason: 'main_prod_bootstrap_failed',
    );
    rethrow;
  }
}

Future<void> _bootstrapAndRunApp() async {
  await CrashReportingService.log('startup_prod:bootstrap_begin');

  await Hive.initFlutter();
  Hive.registerAdapter(TravelLegAdapter());
  Hive.registerAdapter(ShiftAdapter());
  Hive.registerAdapter(EntryAdapter());
  Hive.registerAdapter(EntryTypeAdapter());
  Hive.registerAdapter(LocationAdapter());
  Hive.registerAdapter(AbsenceEntryAdapter());
  Hive.registerAdapter(BalanceAdjustmentAdapter());
  Hive.registerAdapter(UserRedDayAdapter());

  const locationBoxResetKey = 'locations_box_typeid_reset_v1';
  final prefs = await SharedPreferences.getInstance();
  final didResetLocationBox = prefs.getBool(locationBoxResetKey) ?? false;
  if (!didResetLocationBox) {
    try {
      await Hive.deleteBoxFromDisk(AppConstants.locationsBox);
    } catch (e) {
      debugPrint('Location box reset skipped: $e');
    }
    await prefs.setBool(locationBoxResetKey, true);
  }

  // Open Hive boxes for cached data
  final locationBoxFuture = Hive.openBox<Location>(AppConstants.locationsBox);
  final absenceBoxFuture = Hive.openBox<AbsenceEntry>('absences_cache');
  final adjustmentBoxFuture =
      Hive.openBox<BalanceAdjustment>('balance_adjustments_cache');
  final redDayBoxFuture = Hive.openBox<UserRedDay>('user_red_days_cache');

  final locationBox = await locationBoxFuture;
  final locationRepository = LocationRepository(locationBox);
  final absenceBox = await absenceBoxFuture;
  final adjustmentBox = await adjustmentBoxFuture;
  final redDayBox = await redDayBoxFuture;

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize SupabaseAuthService first
  final authService = SupabaseAuthService();
  await authService.initialize();

  // Run legacy Hive migration before EntryProvider loads data
  final migrationService = LegacyHiveMigrationService();
  final userId = authService.currentUser?.id;
  if (userId != null) {
    try {
      await migrationService
          .migrateIfNeeded(userId)
          .timeout(_startupMigrationTimeout);
    } catch (error, stackTrace) {
      await CrashReportingService.recordNonFatal(
        error,
        stackTrace,
        reason: 'startup_prod_legacy_migration_failed',
      );
    }
  }

  // Initialize independent providers in parallel
  final syncQueueService = SyncQueueService();
  await syncQueueService.init();
  final contractProvider = ContractProvider(syncQueue: syncQueueService);
  final settingsProvider = SettingsProvider();
  final reminderService = ReminderService();

  await Future.wait([
    contractProvider.init(),
    settingsProvider.init(),
  ]);

  // Set up Supabase dependencies for settings (pull-before-push)
  final supabase = SupabaseConfig.client;
  settingsProvider.setSupabaseDeps(supabase, userId);

  // Create Supabase repository for locations
  final supabaseLocationRepo = SupabaseLocationRepository(supabase);

  // Start the app immediately so the UI renders without waiting for network.
  // Cloud data is loaded in the background after the first frame.
  await CrashReportingService.log('startup_prod:run_app');
  runApp(
    MyApp(
      authService: authService,
      contractProvider: contractProvider,
      settingsProvider: settingsProvider,
      reminderService: reminderService,
      locationRepository: locationRepository,
      supabaseLocationRepo: supabaseLocationRepo,
      syncQueueService: syncQueueService,
      absenceBox: absenceBox,
      adjustmentBox: adjustmentBox,
      redDayBox: redDayBox,
    ),
  );
}

class MyApp extends StatelessWidget {
  final SupabaseAuthService authService;
  final ContractProvider contractProvider;
  final SettingsProvider settingsProvider;
  final ReminderService reminderService;
  final LocationRepository locationRepository;
  final SupabaseLocationRepository supabaseLocationRepo;
  final SyncQueueService syncQueueService;
  final Box<AbsenceEntry> absenceBox;
  final Box<BalanceAdjustment> adjustmentBox;
  final Box<UserRedDay> redDayBox;

  const MyApp({
    super.key,
    required this.authService,
    required this.contractProvider,
    required this.settingsProvider,
    required this.reminderService,
    required this.locationRepository,
    required this.supabaseLocationRepo,
    required this.syncQueueService,
    required this.absenceBox,
    required this.adjustmentBox,
    required this.redDayBox,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SupabaseAuthService>.value(value: authService),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
        ),
        Provider<ReminderService>.value(value: reminderService),
        // Network status provider (for offline/online detection)
        ChangeNotifierProvider(create: (_) => NetworkStatusProvider()),
        ChangeNotifierProvider<SyncQueueService>.value(value: syncQueueService),
        // Existing providers
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider<ContractProvider>.value(
          value: contractProvider,
        ),
        ChangeNotifierProvider(create: (_) => LocalEntryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<SupabaseAuthService, HolidayService>(
          create: (_) {
            final service = HolidayService();
            service.initHive(redDayBox);
            return service;
          },
          update: (context, authService, previous) {
            final holidayService = previous ?? HolidayService();
            final userId = authService.currentUser?.id;
            holidayService.initialize(
              repository: UserRedDayRepository(),
              userId: userId,
            );
            // Load current year's personal red days if authenticated
            if (userId != null) {
              holidayService.loadPersonalRedDays(DateTime.now().year);
            }
            return holidayService;
          },
        ),
        ChangeNotifierProvider(create: (_) => TravelProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = LocationProvider(locationRepository);
          // Set up Supabase sync (pull-before-push)
          provider.setSupabaseDeps(supabaseLocationRepo, authService);
          provider.refreshLocations();
          if (authService.currentUser != null) {
            provider.loadFromCloud();
          }
          return provider;
        }),
        ChangeNotifierProxyProvider2<SupabaseAuthService, SyncQueueService,
            EntryProvider>(
          create: (context) => EntryProvider(
            context.read<SupabaseAuthService>(),
            syncQueue: context.read<SyncQueueService>(),
          ),
          update: (context, authService, syncQueue, previous) =>
              previous ?? EntryProvider(authService, syncQueue: syncQueue),
        ),
        // AbsenceProvider depends on SupabaseAuthService
        ChangeNotifierProxyProvider2<SupabaseAuthService, SyncQueueService,
            AbsenceProvider>(
          create: (context) {
            final authService = context.read<SupabaseAuthService>();
            final absenceService = SupabaseAbsenceService();
            final provider = AbsenceProvider(
              authService,
              absenceService,
              syncQueue: context.read<SyncQueueService>(),
            );
            provider.initHive(absenceBox);
            return provider;
          },
          update: (context, authService, syncQueue, previous) =>
              previous ??
              AbsenceProvider(
                authService,
                SupabaseAbsenceService(),
                syncQueue: syncQueue,
              ),
        ),
        // BalanceAdjustmentProvider depends on SupabaseAuthService
        ChangeNotifierProxyProvider2<SupabaseAuthService, SyncQueueService,
            BalanceAdjustmentProvider>(
          create: (context) {
            final authService = context.read<SupabaseAuthService>();
            final supabase = SupabaseConfig.client;
            final repository = BalanceAdjustmentRepository(supabase);
            final provider = BalanceAdjustmentProvider(
              authService,
              repository,
              syncQueue: context.read<SyncQueueService>(),
            );
            provider.initHive(adjustmentBox);
            return provider;
          },
          update: (context, authService, syncQueue, previous) {
            if (previous != null) return previous;
            final supabase = SupabaseConfig.client;
            final repository = BalanceAdjustmentRepository(supabase);
            return BalanceAdjustmentProvider(
              authService,
              repository,
              syncQueue: syncQueue,
            );
          },
        ),
        ChangeNotifierProxyProvider5<
            EntryProvider,
            ContractProvider,
            AbsenceProvider,
            BalanceAdjustmentProvider,
            HolidayService,
            TimeProvider>(
          create: (context) => TimeProvider(
            context.read<EntryProvider>(),
            context.read<ContractProvider>(),
            context.read<AbsenceProvider>(),
            context.read<BalanceAdjustmentProvider>(),
            context.read<HolidayService>(),
          ),
          update: (context, entryProvider, contractProvider, absenceProvider,
                  adjustmentProvider, holidayService, previous) =>
              previous ??
              TimeProvider(entryProvider, contractProvider, absenceProvider,
                  adjustmentProvider, holidayService),
        ),
        // Services
        Provider(create: (_) => TravelCacheService()..init()),
      ],
      child: _NetworkSyncSetup(
        child: Consumer2<ThemeProvider, SettingsProvider>(
          builder: (context, themeProvider, settingsProvider, child) {
            return MaterialApp.router(
              title: 'KvikTime',
              theme: AppTheme.lightTheme,
              themeMode: ThemeMode.light,
              routerConfig: AppRouter.router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(
                      themeProvider.textScaleFactor,
                    ),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              // Localization configuration
              locale: settingsProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Widget that sets up network connectivity callbacks for auto-sync
class _NetworkSyncSetup extends StatefulWidget {
  final Widget child;

  const _NetworkSyncSetup({required this.child});

  @override
  State<_NetworkSyncSetup> createState() => _NetworkSyncSetupState();
}

class _NetworkSyncSetupState extends State<_NetworkSyncSetup> {
  SupabaseAuthService? _authService;
  String? _lastAuthUserId;

  @override
  void initState() {
    super.initState();
    // Set up connectivity restored callback after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityCallback();
    });
  }

  @override
  void dispose() {
    _authService?.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _setupConnectivityCallback() {
    final networkProvider = context.read<NetworkStatusProvider>();
    final entryProvider = context.read<EntryProvider>();
    final absenceProvider = context.read<AbsenceProvider>();
    final adjustmentProvider = context.read<BalanceAdjustmentProvider>();
    final contractProvider = context.read<ContractProvider>();

    // Register callback to sync pending operations when connectivity is restored
    networkProvider.addOnConnectivityRestoredCallback(() async {
      debugPrint(
          'main_prod: Connectivity restored, processing pending sync...');
      final entryResult = await entryProvider.processPendingSync();
      final absenceResult = await absenceProvider.processPendingSync();
      final adjustmentResult = await adjustmentProvider.processPendingSync();
      final contractResult = await contractProvider.processPendingSync();
      final succeeded = entryResult.succeeded +
          absenceResult.succeeded +
          adjustmentResult.succeeded +
          contractResult.succeeded;
      if (succeeded > 0) {
        debugPrint('main_prod: Auto-synced $succeeded pending operations');
      }
    });

    _authService = context.read<SupabaseAuthService>();
    _lastAuthUserId = _authService?.currentUser?.id;
    _authService?.removeListener(_onAuthStateChanged);
    _authService?.addListener(_onAuthStateChanged);

    // Load cloud data now that the UI is visible (deferred from main()).
    unawaited(_loadCloudData());
  }

  Future<void> _loadCloudData() async {
    if (!mounted) return;
    final authService = context.read<SupabaseAuthService>();
    final userId = authService.currentUser?.id;
    if (userId == null) return;

    final contractProvider = context.read<ContractProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final reminderService = context.read<ReminderService>();

    try {
      await contractProvider.loadFromSupabase().timeout(_startupNetworkTimeout);
    } catch (error, stackTrace) {
      await CrashReportingService.recordNonFatal(
        error,
        stackTrace,
        reason: 'startup_prod_deferred_contract_load_failed',
      );
      debugPrint('main_prod: Deferred contract load failed: $error');
    }

    try {
      await settingsProvider.loadFromCloud().timeout(_startupNetworkTimeout);
    } catch (error, stackTrace) {
      await CrashReportingService.recordNonFatal(
        error,
        stackTrace,
        reason: 'startup_prod_deferred_settings_load_failed',
      );
      debugPrint('main_prod: Deferred settings load failed: $error');
    }

    if (!mounted) return;
    try {
      await reminderService.applySettings(settingsProvider);
    } catch (error, stackTrace) {
      await CrashReportingService.recordNonFatal(
        error,
        stackTrace,
        reason: 'startup_prod_deferred_reminder_apply_failed',
      );
      debugPrint('main_prod: Deferred reminder apply failed: $error');
    }
  }

  void _onAuthStateChanged() {
    final authService = _authService;
    if (authService == null) return;

    final currentUserId = authService.currentUser?.id;
    final previousUserId = _lastAuthUserId;
    if (currentUserId == previousUserId) {
      return;
    }

    _lastAuthUserId = currentUserId;
    unawaited(_handleAuthUserSwitch(
      previousUserId: previousUserId,
      currentUserId: currentUserId,
    ));
  }

  Future<void> _handleAuthUserSwitch({
    required String? previousUserId,
    required String? currentUserId,
  }) async {
    if (!mounted) return;
    debugPrint(
        'main_prod: Auth user changed from $previousUserId to $currentUserId, resetting providers...');

    await context.read<EntryProvider>().handleAuthUserChanged(
          previousUserId: previousUserId,
          currentUserId: currentUserId,
        );
    if (!mounted) return;

    await context.read<AbsenceProvider>().handleAuthUserChanged(
          previousUserId: previousUserId,
          currentUserId: currentUserId,
        );
    if (!mounted) return;

    await context.read<BalanceAdjustmentProvider>().handleAuthUserChanged(
          previousUserId: previousUserId,
          currentUserId: currentUserId,
        );
    if (!mounted) return;

    await context.read<LocationProvider>().handleAuthUserChanged(
          previousUserId: previousUserId,
          currentUserId: currentUserId,
        );
    if (!mounted) return;

    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.handleAuthUserChanged(currentUserId);
    if (!mounted) return;

    await context.read<ReminderService>().applySettings(settingsProvider);
    if (!mounted) return;

    await context.read<ContractProvider>().handleAuthUserChanged(currentUserId);
    if (!mounted) return;

    await context.read<TravelProvider>().handleAuthUserChanged();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
