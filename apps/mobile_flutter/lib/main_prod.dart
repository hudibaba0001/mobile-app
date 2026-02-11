// ignore_for_file: avoid_print
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
import 'providers/email_settings_provider.dart';
import 'providers/local_entry_provider.dart';
import 'providers/locale_provider.dart';
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
import 'repositories/supabase_email_settings_repository.dart';
import 'services/supabase_absence_service.dart';
import 'repositories/user_red_day_repository.dart';
import 'services/holiday_service.dart';
import 'services/travel_cache_service.dart';
import 'services/legacy_hive_migration_service.dart';
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

void main() async {
  // Add this line to use "clean" URLs
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

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

  final locationBox = await Hive.openBox<Location>(AppConstants.locationsBox);
  final locationRepository = LocationRepository(locationBox);

  // Open Hive boxes for cached data
  final absenceBox = await Hive.openBox<AbsenceEntry>('absences_cache');
  final adjustmentBox =
      await Hive.openBox<BalanceAdjustment>('balance_adjustments_cache');
  final redDayBox = await Hive.openBox<UserRedDay>('user_red_days_cache');

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize SupabaseAuthService first
  final authService = SupabaseAuthService();
  await authService.initialize();

  // Run legacy Hive migration before EntryProvider loads data
  final migrationService = LegacyHiveMigrationService();
  final userId = authService.currentUser?.id;
  if (userId != null) {
    await migrationService.migrateIfNeeded(userId);
  }

  // Initialize LocaleProvider
  final localeProvider = LocaleProvider();
  await localeProvider.init();

  final contractProvider = ContractProvider();
  await contractProvider.init();

  // If user is already authenticated, load contract settings from Supabase
  if (userId != null) {
    await contractProvider.loadFromSupabase();
  }

  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  // Set up Supabase dependencies for settings (pull-before-push)
  final supabase = SupabaseConfig.client;
  settingsProvider.setSupabaseDeps(supabase, userId);
  if (userId != null) {
    await settingsProvider.loadFromCloud();
  }

  // Create Supabase repositories for location and email settings
  final supabaseLocationRepo = SupabaseLocationRepository(supabase);
  final supabaseEmailSettingsRepo = SupabaseEmailSettingsRepository(supabase);

  runApp(
    MyApp(
      authService: authService,
      localeProvider: localeProvider,
      contractProvider: contractProvider,
      settingsProvider: settingsProvider,
      locationRepository: locationRepository,
      supabaseLocationRepo: supabaseLocationRepo,
      supabaseEmailSettingsRepo: supabaseEmailSettingsRepo,
      absenceBox: absenceBox,
      adjustmentBox: adjustmentBox,
      redDayBox: redDayBox,
    ),
  );
}

class MyApp extends StatelessWidget {
  final SupabaseAuthService authService;
  final LocaleProvider localeProvider;
  final ContractProvider contractProvider;
  final SettingsProvider settingsProvider;
  final LocationRepository locationRepository;
  final SupabaseLocationRepository supabaseLocationRepo;
  final SupabaseEmailSettingsRepository supabaseEmailSettingsRepo;
  final Box<AbsenceEntry> absenceBox;
  final Box<BalanceAdjustment> adjustmentBox;
  final Box<UserRedDay> redDayBox;

  const MyApp({
    super.key,
    required this.authService,
    required this.localeProvider,
    required this.contractProvider,
    required this.settingsProvider,
    required this.locationRepository,
    required this.supabaseLocationRepo,
    required this.supabaseEmailSettingsRepo,
    required this.absenceBox,
    required this.adjustmentBox,
    required this.redDayBox,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SupabaseAuthService>.value(value: authService),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
        ),
        // Network status provider (for offline/online detection)
        ChangeNotifierProvider(create: (_) => NetworkStatusProvider()),
        // Existing providers
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider<ContractProvider>.value(
          value: contractProvider,
        ),
        ChangeNotifierProvider(create: (_) {
          final provider = EmailSettingsProvider();
          provider.initialize();
          // Set up Supabase sync (pull-before-push)
          provider.setSupabaseDeps(supabaseEmailSettingsRepo, authService);
          if (authService.currentUser != null) {
            provider.loadFromCloud();
          }
          return provider;
        }),
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
        ChangeNotifierProxyProvider<SupabaseAuthService, EntryProvider>(
          create: (context) =>
              EntryProvider(context.read<SupabaseAuthService>()),
          update: (context, authService, previous) =>
              previous ?? EntryProvider(authService),
        ),
        // AbsenceProvider depends on SupabaseAuthService
        ChangeNotifierProxyProvider<SupabaseAuthService, AbsenceProvider>(
          create: (context) {
            final authService = context.read<SupabaseAuthService>();
            final absenceService = SupabaseAbsenceService();
            final provider = AbsenceProvider(authService, absenceService);
            provider.initHive(absenceBox);
            return provider;
          },
          update: (context, authService, previous) =>
              previous ??
              AbsenceProvider(authService, SupabaseAbsenceService()),
        ),
        // BalanceAdjustmentProvider depends on SupabaseAuthService
        ChangeNotifierProxyProvider<SupabaseAuthService,
            BalanceAdjustmentProvider>(
          create: (context) {
            final authService = context.read<SupabaseAuthService>();
            final supabase = SupabaseConfig.client;
            final repository = BalanceAdjustmentRepository(supabase);
            final provider =
                BalanceAdjustmentProvider(authService, repository);
            provider.initHive(adjustmentBox);
            return provider;
          },
          update: (context, authService, previous) {
            if (previous != null) return previous;
            final supabase = SupabaseConfig.client;
            final repository = BalanceAdjustmentRepository(supabase);
            return BalanceAdjustmentProvider(authService, repository);
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
        child: Consumer2<ThemeProvider, LocaleProvider>(
          builder: (context, themeProvider, localeProvider, child) {
            return MaterialApp.router(
              title: 'KvikTime',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
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
              locale: localeProvider.locale,
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
  @override
  void initState() {
    super.initState();
    // Set up connectivity restored callback after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityCallback();
    });
  }

  void _setupConnectivityCallback() {
    final networkProvider = context.read<NetworkStatusProvider>();
    final entryProvider = context.read<EntryProvider>();

    // Register callback to sync pending operations when connectivity is restored
    networkProvider.addOnConnectivityRestoredCallback(() async {
      debugPrint('main_prod: Connectivity restored, processing pending sync...');
      final result = await entryProvider.processPendingSync();
      if (result.succeeded > 0) {
        debugPrint('main_prod: Auto-synced ${result.succeeded} pending operations');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
