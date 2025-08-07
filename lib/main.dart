import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'providers/app_state_provider.dart';
import 'providers/contract_provider.dart';
import 'providers/email_settings_provider.dart';
import 'providers/local_entry_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/travel_provider.dart';
import 'providers/entry_provider.dart';
import 'providers/location_provider.dart';
import 'services/auth_service.dart';
import 'services/stripe_service.dart';
import 'repositories/repository_provider.dart';
import 'repositories/travel_repository.dart';
import 'repositories/work_repository.dart';
import 'repositories/contract_repository.dart';
import 'repositories/leave_repository.dart';
import 'services/admin_api_service.dart';
import 'viewmodels/analytics_view_model.dart';

void main() async {
  // Add this line to use "clean" URLs
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Stripe
  await StripeService.initialize();

  // Create and initialize RepositoryProvider
  final repositoryProvider = RepositoryProvider();
  await repositoryProvider.initialize();

  // Initialize AuthService
  final authService = AuthService();
  await authService.initialize();

  runApp(
    MyApp(
      repositoryProvider: repositoryProvider,
      authService: authService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final RepositoryProvider repositoryProvider;
  final AuthService authService;

  const MyApp({
    super.key,
    required this.repositoryProvider,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<RepositoryProvider>.value(value: repositoryProvider),
        // Individual Repositories
        ProxyProvider<RepositoryProvider, TravelRepository>(
          create: (context) =>
              context.read<RepositoryProvider>().travelRepository,
          update: (context, repositoryProvider, previous) =>
              repositoryProvider.travelRepository,
        ),
        ProxyProvider<RepositoryProvider, WorkRepository>(
          create: (context) =>
              context.read<RepositoryProvider>().workRepository,
          update: (context, repositoryProvider, previous) =>
              repositoryProvider.workRepository,
        ),
        ProxyProvider<RepositoryProvider, ContractRepository>(
          create: (context) =>
              context.read<RepositoryProvider>().contractRepository,
          update: (context, repositoryProvider, previous) =>
              repositoryProvider.contractRepository,
        ),
        ProxyProvider<RepositoryProvider, LeaveRepository>(
          create: (context) =>
              context.read<RepositoryProvider>().leaveRepository,
          update: (context, repositoryProvider, previous) =>
              repositoryProvider.leaveRepository,
        ),
        // Existing providers
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ContractProvider()),
        ChangeNotifierProvider(create: (_) => EmailSettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocalEntryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TravelProvider()),
        ChangeNotifierProxyProvider<RepositoryProvider, LocationProvider>(
          create: (context) => LocationProvider(
              context.read<RepositoryProvider>().locationRepository),
          update: (context, repositoryProvider, previous) =>
              previous ??
              LocationProvider(repositoryProvider.locationRepository),
        ),
        ChangeNotifierProxyProvider2<RepositoryProvider, AuthService,
            EntryProvider>(
          create: (context) => EntryProvider(
              context.read<RepositoryProvider>(), context.read<AuthService>()),
          update: (context, repositoryProvider, authService, previous) =>
              previous ?? EntryProvider(repositoryProvider, authService),
        ),
        // Services
        Provider(create: (_) => AdminApiService()),
        // ViewModels
        ChangeNotifierProxyProvider<AdminApiService, AnalyticsViewModel>(
          create: (context) =>
              AnalyticsViewModel(context.read<AdminApiService>()),
          update: (context, apiService, previous) =>
              previous ?? AnalyticsViewModel(apiService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
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
}
