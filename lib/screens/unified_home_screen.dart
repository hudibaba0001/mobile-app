import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/app_router.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';
import '../repositories/repository_provider.dart';
import '../providers/entry_provider.dart';
import '../services/auth_service.dart';

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
  List<_EntryData> _recentEntries = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
    _loadRecentEntries();
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

  void _loadRecentEntries() {
    print('=== LOADING RECENT ENTRIES ===');
    try {
      final repositoryProvider =
          Provider.of<RepositoryProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        setState(() {
          _recentEntries = [];
        });
        return;
      }

      print('Loading entries for user: $userId');

      // Get recent travel entries
      final travelEntries =
          repositoryProvider.travelRepository.getAllForUser(userId);
      final workEntries =
          repositoryProvider.workRepository.getAllForUser(userId);

      print('Found ${travelEntries.length} travel entries');
      print('Found ${workEntries.length} work entries');

      // Combine and sort by date
      final allEntries = <_EntryData>[];

      // Convert travel entries
      for (final entry in travelEntries.take(5)) {
        allEntries.add(_EntryData(
          id: entry.id,
          type: 'travel',
          title: 'Travel: ${entry.fromLocation} → ${entry.toLocation}',
          subtitle:
              '${entry.date.toString().split(' ')[0]} • ${entry.remarks.isNotEmpty ? entry.remarks : 'No remarks'}',
          duration:
              '${entry.travelMinutes ~/ 60}h ${entry.travelMinutes % 60}m',
          icon: Icons.directions_car,
        ));
      }

      // Convert work entries
      for (final entry in workEntries.take(5)) {
        allEntries.add(_EntryData(
          id: entry.id,
          type: 'work',
          title: 'Work Session',
          subtitle:
              '${entry.date.toString().split(' ')[0]} • ${entry.remarks.isNotEmpty ? entry.remarks : 'No remarks'}',
          duration: '${entry.workMinutes ~/ 60}h ${entry.workMinutes % 60}m',
          icon: Icons.work,
        ));
      }

      // Sort by date (most recent first)
      allEntries.sort((a, b) {
        // Extract date from subtitle for sorting
        final aDate = a.subtitle.split(' • ')[0];
        final bDate = b.subtitle.split(' • ')[0];
        return bDate.compareTo(aDate);
      });

      setState(() {
        _recentEntries = allEntries.take(10).toList();
      });
    } catch (e) {
      // If there's an error, keep the mock data
      print('Error loading recent entries: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.push(AppRouter.homePath);
        break;
      case 1:
        context.push(AppRouter.historyPath);
        break;
      case 2:
        context.push(AppRouter.settingsPath);
        break;
      case 3:
        context.push(AppRouter.contractSettingsPath);
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.timer_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Tracker',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Track your productivity',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            onPressed: () => AppRouter.goToProfile(context),
            tooltip: 'Profile',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.settings_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            onPressed: () => AppRouter.goToSettings(context),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 16),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showQuickEntry,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onTabTapped(0),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.history_rounded,
                  label: 'History',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onTabTapped(1),
                ),
                const SizedBox(width: 40), // Space for FAB
                _buildNavItem(
                  context,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onTabTapped(2),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.assignment_rounded,
                  label: 'Contract',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onTabTapped(3),
                ),
              ],
            ),
          ),
        ),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Total',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '7h 45m',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1h 30m',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Travel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.work_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '6h 15m',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Work',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            icon: Icons.directions_car_rounded,
            title: 'Log Travel',
            subtitle: 'Track your commute',
            color: theme.colorScheme.primary,
            onTap: _startTravelEntry,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            theme,
            icon: Icons.work_rounded,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Recent Entries',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => AppRouter.goToHistory(context),
              child: Text(
                'View All',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No entries yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start tracking your time by logging travel or work entries',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...(_recentEntries
              .take(3)
              .map((entry) => _buildRecentEntryCard(theme, entry))),
      ],
    );
  }

  Widget _buildRecentEntryCard(ThemeData theme, _EntryData entry) {
    final isTravel = entry.type == 'travel';
    final color =
        isTravel ? theme.colorScheme.primary : theme.colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to edit entry
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    entry.icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.duration,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editEntry(entry);
                    } else if (value == 'delete') {
                      _deleteEntry(context, entry);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startTravelEntry() {
    // Show a simple dialog instead of navigating to complex screen
    _showQuickEntryDialog('travel');
  }

  void _startWorkEntry() {
    // Show a simple dialog instead of navigating to complex screen
    _showQuickEntryDialog('work');
  }

  void _showQuickEntryDialog(String type) {
    if (type == 'travel') {
      _showTravelEntryDialog();
    } else {
      _showWorkEntryDialog();
    }
  }

  void _showTravelEntryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _TravelEntryDialog();
      },
    );
  }

  void _showWorkEntryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _WorkEntryDialog();
      },
    );
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

  void _editEntry(_EntryData entry) {
    // Navigate to edit entry screen with the specific entry data
    AppRouter.goToEditEntry(context, entryId: entry.id, entryType: entry.type);
  }

  void _deleteEntry(_EntryData entry) {
    // Show confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: Text(
              'Are you sure you want to delete this ${entry.type} entry? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performDelete(entry);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDelete(_EntryData entry) async {
    try {
      final repositoryProvider =
          Provider.of<RepositoryProvider>(context, listen: false);

      if (entry.type == 'travel') {
        await repositoryProvider.travelRepository.delete(entry.id);
      } else if (entry.type == 'work') {
        await repositoryProvider.workRepository.delete(entry.id);
      }

      // Refresh the recent entries list
      _loadRecentEntries();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${entry.type[0].toUpperCase() + entry.type.substring(1)} entry deleted successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete entry: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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

class _TravelEntryDialog extends StatefulWidget {
  @override
  State<_TravelEntryDialog> createState() => _TravelEntryDialogState();
}

class _TravelEntryDialogState extends State<_TravelEntryDialog> {
  final List<_TripData> _trips = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _totalHoursController = TextEditingController();
  final TextEditingController _totalMinutesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add initial trip
    _trips.add(_TripData());
  }

  @override
  void dispose() {
    _notesController.dispose();
    _totalHoursController.dispose();
    _totalMinutesController.dispose();
    super.dispose();
  }

  void _addTrip() {
    setState(() {
      // If there are existing trips, use the last destination as the new starting point
      String? lastDestination;
      if (_trips.isNotEmpty) {
        lastDestination = _trips.last.toController.text.trim();
      }
      _trips.add(_TripData(initialFrom: lastDestination));
    });
  }

  void _removeTrip(int index) {
    setState(() {
      _trips.removeAt(index);
      // Ensure we always have at least one trip
      if (_trips.isEmpty) {
        _trips.add(_TripData());
      }
    });
  }

  void _updateTotalDuration() {
    int totalMinutes = 0;
    for (final trip in _trips) {
      totalMinutes += trip.totalMinutes;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    _totalHoursController.text = hours.toString();
    _totalMinutesController.text = minutes.toString();
  }

  bool _isValid() {
    if (_trips.isEmpty) return false;

    for (final trip in _trips) {
      if (!trip.isValid) return false;
    }

    // Check if total duration is greater than 0
    int totalMinutes = 0;
    for (final trip in _trips) {
      totalMinutes += trip.totalMinutes;
    }
    return totalMinutes > 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Travel Entry',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your journey details',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trips section
                    Row(
                      children: [
                        Icon(
                          Icons.route,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trip Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List of trips
                    ..._trips.asMap().entries.map((entry) {
                      final index = entry.key;
                      final trip = entry.value;

                      return Column(
                        children: [
                          if (index > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildTripRow(theme, index, trip),
                        ],
                      );
                    }),

                    // Add trip button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addTrip,
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          'Add Another Trip',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Total duration
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Duration',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hours',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _totalHoursController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minutes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _totalMinutesController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add details about your travel...',
                        prefixIcon: Icon(
                          Icons.note,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Entry will be logged for ${DateTime.now().toString().split(' ')[0]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isValid()
                          ? () async {
                              try {
                                print('=== TRAVEL ENTRY SAVE ATTEMPT ===');

                                // Get the repository provider
                                final repositoryProvider =
                                    Provider.of<RepositoryProvider>(context,
                                        listen: false);
                                print(
                                    'Repository provider obtained: ${repositoryProvider != null}');

                                // Create travel entry from the first trip (for now, we'll save each trip as a separate entry)
                                final trip = _trips.first;
                                print(
                                    'Trip data: from=${trip.fromController.text}, to=${trip.toController.text}, minutes=${trip.totalMinutes}');

                                final authService = context.read<AuthService>();
                                final userId = authService.currentUser?.uid;
                                if (userId == null) return;

                                final travelEntry = TravelEntry(
                                  id: '', // Will be generated by repository
                                  userId: userId,
                                  date: DateTime.now(),
                                  fromLocation: trip.fromController.text.trim(),
                                  toLocation: trip.toController.text.trim(),
                                  travelMinutes: trip.totalMinutes,
                                  remarks: _notesController.text.trim(),
                                );

                                print(
                                    'Created TravelEntry: ${travelEntry.toString()}');
                                print(
                                    'TravelEntry details: from=${travelEntry.fromLocation}, to=${travelEntry.toLocation}, minutes=${travelEntry.travelMinutes}');

                                // Save to repository
                                print(
                                    'Attempting to save to travel repository...');
                                await repositoryProvider.travelRepository
                                    .add(travelEntry);
                                print(
                                    'Successfully saved to travel repository!');

                                Navigator.of(context).pop();

                                // Refresh recent entries by calling the parent's method
                                if (context.mounted) {
                                  final parent =
                                      context.findAncestorStateOfType<
                                          _UnifiedHomeScreenState>();
                                  parent?._loadRecentEntries();
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                            'Travel entry logged successfully!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.error,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                            'Error saving entry: ${e.toString()}'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Log Entry',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripRow(ThemeData theme, int index, _TripData trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Trip ${index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (_trips.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _removeTrip(index),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red[600],
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // From field
          TextField(
            controller: trip.fromController,
            decoration: InputDecoration(
              labelText: 'From',
              hintText: 'Starting location',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: theme.colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // To field
          TextField(
            controller: trip.toController,
            decoration: InputDecoration(
              labelText: 'To',
              hintText: 'Destination',
              prefixIcon: Icon(
                Icons.location_on,
                color: theme.colorScheme.secondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.secondary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Duration fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hours',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: trip.hoursController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixIcon: Icon(
                          Icons.schedule,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (_) {
                        _updateTotalDuration();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minutes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: trip.minutesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixIcon: Icon(
                          Icons.timer,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        final minutes = int.tryParse(value) ?? 0;
                        if (minutes > 59) {
                          trip.minutesController.text = '59';
                          trip.minutesController.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: 2),
                          );
                        }
                        _updateTotalDuration();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripData {
  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController hoursController;
  final TextEditingController minutesController;

  _TripData({String? initialFrom})
      : fromController = TextEditingController(text: initialFrom ?? ''),
        toController = TextEditingController(),
        hoursController = TextEditingController(),
        minutesController = TextEditingController();

  bool get isValid {
    final from = fromController.text.trim();
    final to = toController.text.trim();
    final hours = int.tryParse(hoursController.text) ?? 0;
    final minutes = int.tryParse(minutesController.text) ?? 0;

    return from.isNotEmpty && to.isNotEmpty && (hours > 0 || minutes > 0);
  }

  int get totalMinutes {
    final hours = int.tryParse(hoursController.text) ?? 0;
    final minutes = int.tryParse(minutesController.text) ?? 0;
    return hours * 60 + minutes;
  }
}

class _WorkEntryDialog extends StatefulWidget {
  @override
  State<_WorkEntryDialog> createState() => _WorkEntryDialogState();
}

class _WorkEntryDialogState extends State<_WorkEntryDialog> {
  final List<_ShiftData> _shifts = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _totalHoursController = TextEditingController();
  final TextEditingController _totalMinutesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add initial shift
    _shifts.add(_ShiftData());
  }

  @override
  void dispose() {
    _notesController.dispose();
    _totalHoursController.dispose();
    _totalMinutesController.dispose();
    super.dispose();
  }

  void _addShift() {
    setState(() {
      _shifts.add(_ShiftData());
    });
  }

  void _removeShift(int index) {
    setState(() {
      _shifts.removeAt(index);
      // Ensure we always have at least one shift
      if (_shifts.isEmpty) {
        _shifts.add(_ShiftData());
      }
    });
  }

  void _updateTotalDuration() {
    int totalMinutes = 0;
    for (final shift in _shifts) {
      totalMinutes += shift.totalMinutes;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    _totalHoursController.text = hours.toString();
    _totalMinutesController.text = minutes.toString();
  }

  bool _isValid() {
    if (_shifts.isEmpty) return false;

    for (final shift in _shifts) {
      if (!shift.isValid) return false;
    }

    int totalMinutes = 0;
    for (final shift in _shifts) {
      totalMinutes += shift.totalMinutes;
    }
    return totalMinutes > 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.secondary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.work,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Work Entry',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your work shifts',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shifts section
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Work Shifts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List of shifts
                    ..._shifts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final shift = entry.value;

                      return Column(
                        children: [
                          if (index > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildShiftRow(theme, index, shift),
                        ],
                      );
                    }),

                    // Add shift button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addShift,
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        label: Text(
                          'Add Another Shift',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: theme.colorScheme.secondary.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Total duration
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Duration',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hours',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _totalHoursController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Minutes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _totalMinutesController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add details about your work...',
                        prefixIcon: Icon(
                          Icons.note,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.secondary,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Entry will be logged for ${DateTime.now().toString().split(' ')[0]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isValid()
                          ? () async {
                              try {
                                print('=== WORK ENTRY SAVE ATTEMPT ===');

                                // Get the repository provider
                                final repositoryProvider =
                                    Provider.of<RepositoryProvider>(context,
                                        listen: false);
                                print(
                                    'Repository provider obtained: ${repositoryProvider != null}');

                                // Calculate total work minutes from all shifts
                                int totalWorkMinutes = 0;
                                for (final shift in _shifts) {
                                  totalWorkMinutes += shift.totalMinutes;
                                  print(
                                      'Shift: ${shift.startTimeController.text} - ${shift.endTimeController.text}, minutes: ${shift.totalMinutes}');
                                }
                                print('Total work minutes: $totalWorkMinutes');

                                // Create work entry
                                final authService = context.read<AuthService>();
                                final userId = authService.currentUser?.uid;
                                if (userId == null) return;

                                final workEntry = WorkEntry(
                                  id: '', // Will be generated by repository
                                  userId: userId,
                                  date: DateTime.now(),
                                  workMinutes: totalWorkMinutes,
                                  remarks: _notesController.text.trim(),
                                );

                                print(
                                    'Created WorkEntry: ${workEntry.toString()}');
                                print(
                                    'WorkEntry details: minutes=${workEntry.workMinutes}, remarks=${workEntry.remarks}');

                                // Save to repository
                                print(
                                    'Attempting to save to work repository...');
                                await repositoryProvider.workRepository
                                    .add(workEntry);
                                print('Successfully saved to work repository!');

                                Navigator.of(context).pop();

                                // Refresh recent entries by calling the parent's method
                                if (context.mounted) {
                                  final parent =
                                      context.findAncestorStateOfType<
                                          _UnifiedHomeScreenState>();
                                  parent?._loadRecentEntries();
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                            'Work entry logged successfully!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.error,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                            'Error saving entry: ${e.toString()}'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Log Entry',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftRow(ThemeData theme, int index, _ShiftData shift) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Shift ${index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const Spacer(),
              if (_shifts.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _removeShift(index),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red[600],
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Time fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () =>
                          _selectTime(context, shift.startTimeController, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                shift.startTimeController.text.isEmpty
                                    ? 'Select time'
                                    : shift.startTimeController.text,
                                style: TextStyle(
                                  color: shift.startTimeController.text.isEmpty
                                      ? Colors.grey[500]
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () =>
                          _selectTime(context, shift.endTimeController, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                shift.endTimeController.text.isEmpty
                                    ? 'Select time'
                                    : shift.endTimeController.text,
                                style: TextStyle(
                                  color: shift.endTimeController.text.isEmpty
                                      ? Colors.grey[500]
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Duration display
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${shift.formattedDuration}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context,
      TextEditingController controller, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      controller.text = picked.format(context);
      _updateTotalDuration();
      setState(() {});
    }
  }
}

class _ShiftData {
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;

  _ShiftData()
      : startTimeController = TextEditingController(),
        endTimeController = TextEditingController();

  bool get isValid {
    final startTime = startTimeController.text.trim();
    final endTime = endTimeController.text.trim();

    return startTime.isNotEmpty && endTime.isNotEmpty && totalMinutes > 0;
  }

  int get totalMinutes {
    if (startTimeController.text.isEmpty || endTimeController.text.isEmpty) {
      return 0;
    }

    try {
      final startTime = _parseTimeOfDay(startTimeController.text);
      final endTime = _parseTimeOfDay(endTimeController.text);

      if (startTime == null || endTime == null) return 0;

      int startMinutes = startTime.hour * 60 + startTime.minute;
      int endMinutes = endTime.hour * 60 + endTime.minute;

      // Handle overnight shifts
      if (endMinutes < startMinutes) {
        endMinutes += 24 * 60; // Add 24 hours
      }

      return endMinutes - startMinutes;
    } catch (e) {
      return 0;
    }
  }

  String get formattedDuration {
    final minutes = totalMinutes;
    if (minutes <= 0) return '0h 0m';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0 && remainingMinutes > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${remainingMinutes}m';
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(' ');
      if (parts.length != 2) return null;

      final timePart = parts[0];
      final period = parts[1];

      final timeParts = timePart.split(':');
      if (timeParts.length != 2) return null;

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }
}
