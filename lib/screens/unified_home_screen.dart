import 'package:flutter/material.dart';
import '../config/app_router.dart';

/// Unified Home screen with navigation integration.
/// Main entry point combining travel and work time tracking.
/// Features: Navigation tabs, today's total, action cards, stats, recent entries.
class UnifiedHomeScreen extends StatefulWidget {
  const UnifiedHomeScreen({super.key});

  @override
  State<UnifiedHomeScreen> createState() => _UnifiedHomeScreenState();
}

class _UnifiedHomeScreenState extends State<UnifiedHomeScreen> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final currentRoute = AppRouter.getCurrentRouteName(context);
    switch (currentRoute) {
      case AppRouter.homeName:
        _selectedIndex = 0;
        break;
      case AppRouter.historyName:
        _selectedIndex = 1;
        break;
      case AppRouter.settingsName:
        _selectedIndex = 2;
        break;
      case AppRouter.contractSettingsName:
        _selectedIndex = 3;
        break;
      default:
        _selectedIndex = 0;
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        AppRouter.goToHome(context);
        break;
      case 1:
        AppRouter.goToHistory(context);
        break;
      case 2:
        AppRouter.goToSettings(context);
        break;
      case 3:
        AppRouter.goToContractSettings(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Time Tracker'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => AppRouter.goToProfile(context),
            tooltip: 'Profile',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => AppRouter.goToSettings(context),
            tooltip: 'Settings',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Total Card
            _buildTotalCard(theme),
            const SizedBox(height: 24),

            // Action Cards
            _buildActionCards(theme),
            const SizedBox(height: 24),

            // Stats Section
            _buildStatsSection(theme),
            const SizedBox(height: 24),

            // Recent Entries
            _buildRecentEntries(theme),
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickEntry,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: theme.textTheme.labelMedium,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Contract',
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Total',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '7h 45m',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Travel: 1h 30m • Work: 6h 15m',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            theme,
            icon: Icons.directions_car,
            title: 'Log Travel',
            subtitle: 'Track your commute',
            color: theme.colorScheme.primary,
            onTap: _startTravelEntry,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            theme,
            icon: Icons.work,
            title: 'Log Work',
            subtitle: 'Track work hours',
            color: theme.colorScheme.secondary,
            onTap: _startWorkEntry,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(theme, '38.5h', 'Total Hours'),
            _buildStatCard(theme, '5.2h', 'Travel Time'),
            _buildStatCard(theme, '33.3h', 'Work Hours'),
            _buildStatCard(theme, '96%', 'Contract %'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String value, String label) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries(ThemeData theme) {
    final entries = [
      _EntryData(
        id: '1',
        type: 'work',
        title: 'Work Session',
        subtitle: 'Office • Today 9:00 AM',
        duration: '8h',
        icon: Icons.work,
      ),
      _EntryData(
        id: '2',
        type: 'travel',
        title: 'Morning Commute',
        subtitle: 'Home → Office • Today 8:30 AM',
        duration: '30m',
        icon: Icons.directions_car,
      ),
      _EntryData(
        id: '3',
        type: 'work',
        title: 'Remote Work',
        subtitle: 'Home • Yesterday 10:00 AM',
        duration: '6h 30m',
        icon: Icons.work,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Entries',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...entries.map((entry) => _buildRecentEntry(theme, entry)),
      ],
    );
  }

  Widget _buildRecentEntry(ThemeData theme, _EntryData entry) {
    final isWork = entry.type == 'work';
    final color = isWork
        ? theme.colorScheme.secondary
        : theme.colorScheme.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => AppRouter.goToEditEntry(context, entryId: entry.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(entry.icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                entry.duration,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTravelEntry() {
    print('🚀 Starting travel entry navigation...');
    try {
      // Navigate to create new travel entry
      AppRouter.goToEditEntry(
        context,
        entryId: 'new', // Use 'new' to indicate creating a new entry
        entryType: 'travel',
      );
      print('✅ Travel entry navigation called successfully');
    } catch (e) {
      print('❌ Error navigating to travel entry: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Navigation error: $e')));
    }
  }

  void _startWorkEntry() {
    print('🚀 Starting work entry navigation...');
    try {
      // Navigate to create new work entry
      AppRouter.goToEditEntry(
        context,
        entryId: 'new', // Use 'new' to indicate creating a new entry
        entryType: 'work',
      );
      print('✅ Work entry navigation called successfully');
    } catch (e) {
      print('❌ Error navigating to work entry: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Navigation error: $e')));
    }
  }

  void _showQuickEntry() {
    // Show bottom sheet with quick entry options
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick Entry',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.blue),
                title: const Text('Log Travel'),
                subtitle: const Text('Quick travel entry'),
                onTap: () {
                  Navigator.pop(context);
                  _startTravelEntry();
                },
              ),
              ListTile(
                leading: const Icon(Icons.work, color: Colors.green),
                title: const Text('Log Work'),
                subtitle: const Text('Quick work entry'),
                onTap: () {
                  Navigator.pop(context);
                  _startWorkEntry();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class _EntryData {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String duration;
  final IconData icon;

  _EntryData({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.icon,
  });
}
