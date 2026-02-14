import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/analytics_view_model.dart';
import '../services/admin_api_service.dart';
import '../services/supabase_auth_service.dart';
import '../config/app_router.dart';
import '../design/app_theme.dart';
import '../l10n/generated/app_localizations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    // Load mock data for testing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsViewModel>().loadMockData();
    });
  }

  Future<void> _checkAdminStatus() async {
    final authService = context.read<SupabaseAuthService>();
    final isAdmin = await authService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _isCheckingAdmin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Show loading while checking admin status
    if (_isCheckingAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Redirect non-admin users
    if (!_isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.analytics_accessDeniedAdminRequired),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        context.go(AppRouter.homePath);
      });
      return Scaffold(
        body: Center(child: Text(t.analytics_accessDeniedRedirecting)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(t.analytics_dashboardTitle),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                t.analytics_adminBadge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Consumer<AnalyticsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: AppIconSize.xl,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    t.analytics_errorLoadingDashboard,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    viewModel.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => viewModel.refresh(),
                    child: Text(t.common_retry),
                  ),
                ],
              ),
            );
          }

          final data = viewModel.dashboardData;
          if (data == null) {
            return Center(child: Text(t.analytics_noDataAvailable));
          }

          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Cards
                  _buildKPICards(data),
                  const SizedBox(height: AppSpacing.xl),

                  // Charts Section
                  _buildChartsSection(data),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPICards(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).analytics_kpiSectionTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          childAspectRatio: 1.5,
          children: [
            _buildKPICard(
              AppLocalizations.of(context).analytics_kpiTotalHoursWeek,
              '${data.totalHoursLoggedThisWeek.toStringAsFixed(1)}h',
              Icons.access_time,
              AppColors.primary,
            ),
            _buildKPICard(
              AppLocalizations.of(context).analytics_kpiActiveUsers,
              data.activeUsers.toString(),
              Icons.people,
              AppColors.success,
            ),
            _buildKPICard(
              AppLocalizations.of(context).analytics_kpiOvertimeBalance,
              '${data.overtimeBalance.toStringAsFixed(1)}h',
              Icons.trending_up,
              data.overtimeBalance >= 0 ? AppColors.accent : AppColors.error,
            ),
            _buildKPICard(
              AppLocalizations.of(context).analytics_kpiAvgDailyHours,
              '${data.averageDailyHours.toStringAsFixed(1)}h',
              Icons.analytics,
              AppColors.secondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: AppIconSize.md),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).analytics_chartsSectionTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Daily Trends Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).analytics_dailyTrends7d,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 200,
                  child: _buildDailyTrendsChart(data.dailyTrends),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // User Distribution Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).analytics_userDistribution,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 200,
                  child: _buildUserDistributionChart(data.userDistribution),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTrendsChart(List<DailyTrend> trends) {
    if (trends.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).analytics_noDataAvailable));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: trends.map((t) => t.totalHours).reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < trends.length) {
                  final date = trends[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      date,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: trends.asMap().entries.map((entry) {
          final index = entry.key;
          final trend = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: trend.totalHours,
                color: Theme.of(context).colorScheme.primary,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.sm / 2),
                  topRight: Radius.circular(AppRadius.sm / 2),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserDistributionChart(List<UserDistribution> distribution) {
    if (distribution.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).analytics_noDataAvailable));
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: false),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: distribution.map<PieChartSectionData>((user) {
          return PieChartSectionData(
            color: _getColorForIndex(distribution.indexOf(user)),
            value: user.percentage,
            title: '${user.percentage.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          );
        }).toList(),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.accent,
      AppColors.error,
      AppColors.secondary,
      AppColors.secondaryLight,
      AppColors.primaryLight,
      AppColors.primaryDark,
    ];
    return colors[index % colors.length];
  }
}
