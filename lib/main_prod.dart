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
import 'services/supabase_absence_service.dart';
import 'repositories/user_red_day_repository.dart';
import 'services/holiday_service.dart';
import 'services/travel_cache_service.dart';
import 'services/legacy_hive_migration_service.dart';
import 'repositories/location_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/entry.dart';
import 'models/location.dart';
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

  final locationBox =
      await Hive.openBox<Location>(AppConstants.locationsBox);
  final locationRepository = LocationRepository(locationBox);

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

  runApp(
    MyApp(
      authService: authService,
      localeProvider: localeProvider,
      locationRepository: locationRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final SupabaseAuthService authService;
  final LocaleProvider localeProvider;
  final LocationRepository locationRepository;

  const MyApp({
    super.key,
    required this.authService,
    required this.localeProvider,
    required this.locationRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SupabaseAuthService>.value(value: authService),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        // Existing providers
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = ContractProvider();
            // Initialize to load saved settings from SharedPreferences
            // Note: init() is async, but we can't await in create
            // The screen will call init() when needed
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => EmailSettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocalEntryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<SupabaseAuthService, HolidayService>(
          create: (_) => HolidayService(),
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
        ChangeNotifierProvider(
            create: (_) => LocationProvider(locationRepository)),
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
            return AbsenceProvider(authService, absenceService);
          },
          update: (context, authService, previous) =>
              previous ??
              AbsenceProvider(authService, SupabaseAbsenceService()),
        ),
        // BalanceAdjustmentProvider depends on SupabaseAuthService
        ChangeNotifierProxyProvider<SupabaseAuthService, BalanceAdjustmentProvider>(
          create: (context) {
            final authService = context.read<SupabaseAuthService>();
            final supabase = SupabaseConfig.client;
            final repository = BalanceAdjustmentRepository(supabase);
            return BalanceAdjustmentProvider(authService, repository);
          },
          update: (context, authService, previous) {
            if (previous != null) return previous;
            final supabase = SupabaseConfig.client;
            final repository = BalanceAdjustmentRepository(supabase);
            return BalanceAdjustmentProvider(authService, repository);
          },
        ),
        // TimeProvider depends on EntryProvider, ContractProvider, AbsenceProvider, BalanceAdjustmentProvider, and HolidayService
        // Use ChangeNotifierProxyProvider5 since TimeProvider is a ChangeNotifier
        ChangeNotifierProxyProvider5<EntryProvider, ContractProvider, AbsenceProvider,
            BalanceAdjustmentProvider, HolidayService, TimeProvider>(
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
              TimeProvider(entryProvider, contractProvider, absenceProvider, adjustmentProvider, holidayService),
        ),
        // Services
        Provider(create: (_) => TravelCacheService()..init()),
      ],
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
    );
  }
}
