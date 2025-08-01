import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Mock AppStateProvider for demo
class MockAppStateProvider extends ChangeNotifier {
  // Mock implementation
}

void main() {
  runApp(const MigrationDemoApp());
}

class MigrationDemoApp extends StatelessWidget {
  const MigrationDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MockAppStateProvider(),
      child: MaterialApp(
        title: 'Migration Screen Demo',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.dark,
          ),
        ),
        home: const MigrationScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo fade-in animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));
    
    // Progress indicator animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.secondary.withOpacity(0.03),
              colorScheme.tertiary.withOpacity(0.02),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // Top spacing
                const Spacer(flex: 2),
                
                // App Logo Section
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoAnimation.value,
                      child: Transform.scale(
                        scale: 0.8 + (_logoAnimation.value * 0.2),
                        child: _buildAppLogo(context),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 64),
                
                // Progress Indicator Section
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _progressAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _progressAnimation.value)),
                        child: _buildProgressSection(context),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 48),
                
                // Migration Status Text
                Consumer<MockAppStateProvider>(
                  builder: (context, appState, child) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildStatusText(context, appState),
                    );
                  },
                ),
                
                const Spacer(flex: 3),
                
                // Footer
                _buildFooter(context),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 8,
      shadowColor: colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 48,
              color: colorScheme.onPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              'TT',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
                backgroundColor: colorScheme.primary.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Migrating Data',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we update your data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText(BuildContext context, MockAppStateProvider appState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Mock migration status with dynamic updates
    String statusMessage = _getMigrationStatusMessage();
    Color statusColor = _getStatusColor(colorScheme);
    IconData statusIcon = _getStatusIcon();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 16.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              size: 20,
              color: statusColor,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                statusMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        Text(
          'Travel Time Tracker',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version 1.0.0',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _getMigrationStatusMessage() {
    // Simulate different migration phases
    final now = DateTime.now();
    final seconds = now.second % 12;
    
    if (seconds < 2) {
      return 'Initializing migration...';
    } else if (seconds < 4) {
      return 'Scanning existing data...';
    } else if (seconds < 7) {
      return 'Migrating travel entries...';
    } else if (seconds < 9) {
      return 'Migrated 42 entries in 3s';
    } else if (seconds < 11) {
      return 'Finalizing migration...';
    } else {
      return 'Migration completed successfully!';
    }
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    final now = DateTime.now();
    final seconds = now.second % 12;
    
    if (seconds < 9) {
      return colorScheme.primary;
    } else if (seconds < 11) {
      return colorScheme.tertiary;
    } else {
      return colorScheme.secondary;
    }
  }

  IconData _getStatusIcon() {
    final now = DateTime.now();
    final seconds = now.second % 12;
    
    if (seconds < 2) {
      return Icons.hourglass_empty_rounded;
    } else if (seconds < 4) {
      return Icons.search_rounded;
    } else if (seconds < 7) {
      return Icons.sync_rounded;
    } else if (seconds < 9) {
      return Icons.check_circle_outline_rounded;
    } else if (seconds < 11) {
      return Icons.settings_rounded;
    } else {
      return Icons.done_all_rounded;
    }
  }
}
