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

  // Initialize AuthService first
  final authService = AuthService();
  await authService.initialize();

  runApp(
    MyApp(
      authService: authService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({
    super.key,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        // RepositoryProvider will be managed by ProxyProvider
        ProxyProvider<AuthService, RepositoryProvider>(
          create: (context) => RepositoryProvider(),
          update: (context, authService, repositoryProvider) {
            debugPrint('RepositoryProvider ProxyProvider update called');
            debugPrint('RepositoryProvider ProxyProvider - authService.isAuthenticated: ${authService.isAuthenticated}');
            debugPrint('RepositoryProvider ProxyProvider - authService.currentUser: ${authService.currentUser?.uid}');
            debugPrint('RepositoryProvider ProxyProvider - repositoryProvider?.currentUserId: ${repositoryProvider?.currentUserId}');
            
            // Initialize repository for current user if authenticated
            if (authService.isAuthenticated && authService.currentUser != null) {
              final userId = authService.currentUser!.uid;
              debugPrint('RepositoryProvider ProxyProvider - User authenticated with ID: $userId');
              
              if (repositoryProvider?.currentUserId != userId) {
                debugPrint('RepositoryProvider ProxyProvider - User changed, reinitializing repositories');
                // User changed, reinitialize repositories
                // Only dispose if we have a different user and the repository is actually initialized
                if (repositoryProvider?.currentUserId != null && repositoryProvider?.currentUserId != '') {
                  debugPrint('RepositoryProvider ProxyProvider - Calling dispose() before reinitializing');
                  repositoryProvider?.dispose();
                }
                debugPrint('RepositoryProvider ProxyProvider - Calling initialize() for user: $userId');
                repositoryProvider?.initialize(userId);
              } else {
                debugPrint('RepositoryProvider ProxyProvider - Same user, no reinitialization needed');
              }
            } else {
              debugPrint('RepositoryProvider ProxyProvider - User not authenticated');
            }
            return repositoryProvider ?? RepositoryProvider();
          },
        ),
        // Individual Repositories - these will be null until user is authenticated
        ProxyProvider<RepositoryProvider, TravelRepository?>(
          create: (context) =>
              context.read<RepositoryProvider>().travelRepository,
          update: (context, repositoryProvider, previous) =>
              repositoryProvider.travelRepository,
        ),
        ProxyProvider<RepositoryProvider, WorkRepository?>(
          create: (context) =>
              context.read<RepositoryProvider>().workRepository,
          update: (context, repositoryProvider, previous) =>
              repositoryProvider.workRepository,
        ),
        ProxyProvider<RepositoryProvider, ContractRepository?>(
          create: (context) =>
              context.read<RepositoryProvider>().contractRepository,
          update: (context, repositoryProvider, previous) =>
              repositoryProvider.contractRepository,
        ),
        ProxyProvider<RepositoryProvider, LeaveRepository?>(
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
        ChangeNotifierProxyProvider<RepositoryProvider, LocationProvider?>(
          create: (context) {
            final locationRepo =
                context.read<RepositoryProvider>().locationRepository;
            return locationRepo != null ? LocationProvider(locationRepo) : null;
          },
          update: (context, repositoryProvider, previous) {
            final locationRepo = repositoryProvider.locationRepository;
            return locationRepo != null ? LocationProvider(locationRepo) : null;
          },
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
