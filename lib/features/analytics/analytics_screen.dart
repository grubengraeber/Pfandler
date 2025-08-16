import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../services/stats_service.dart';
import '../../services/sync_service.dart';

// Analytics time period selector
enum AnalyticsPeriod { daily, weekly, monthly, yearly }

final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.weekly);

// Stats data provider using both local and server data
final bottleStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Check authentication first
  final authState = ref.read(authProvider);
  if (!authState.isAuthenticated) {
    return {
      'totalBottles': 0,
      'totalValue': 0.0,
      'averagePerDay': 0.0,
      'mostCommonType': 'Unknown',
    };
  }

  try {
    // Try to get server data first
    final statsService = ref.read(statsServiceProvider);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final totals = await statsService.getTotals(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    // Get container breakdown to find most common type
    final breakdown = await statsService.getBreakdown(
      breakdownBy: 'containerType',
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    String mostCommonType = 'Unknown';
    if (breakdown['breakdown'] != null &&
        (breakdown['breakdown'] as List).isNotEmpty) {
      final types = breakdown['breakdown'] as List;
      types.sort((a, b) => (b['count'] ?? 0).compareTo(a['count'] ?? 0));
      mostCommonType = types.first['type'] ?? 'Unknown';
    }

    return {
      'totalBottles': totals['totalBottles'] ?? 0,
      'totalValue': totals['totalValue'] ?? 0.0,
      'averagePerDay': totals['averagePerDay'] ?? 0.0,
      'mostCommonType': mostCommonType,
    };
  } catch (e) {
    // Fallback to local data if server fails
    final syncService = ref.read(syncServiceProvider.notifier);
    return await syncService.getLocalStats();
  }
});

final chartDataProvider =
    FutureProvider.family<List<FlSpot>, AnalyticsPeriod>((ref, period) async {
  final statsService = ref.read(statsServiceProvider);
  final now = DateTime.now();

  DateTime startDate;
  DateTime endDate;

  switch (period) {
    case AnalyticsPeriod.daily:
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
      break;
    case AnalyticsPeriod.weekly:
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 7));
      break;
    case AnalyticsPeriod.monthly:
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
      break;
    case AnalyticsPeriod.yearly:
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
      break;
  }

  final data = await statsService.getBreakdown(
    breakdownBy: 'time',
    startDate: startDate,
    endDate: endDate,
  );

  return statsService.convertToChartData(data, period.name);
});

class DepositTypeData {
  final String label;
  final double value;
  final Color color;
  final String percentage;

  DepositTypeData({
    required this.label,
    required this.value,
    required this.color,
    required this.percentage,
  });
}

final depositTypeDataProvider =
    FutureProvider<List<DepositTypeData>>((ref) async {
  final breakdownAsync = await ref.watch(containerTypeBreakdownProvider.future);
  final breakdown = DepositTypeBreakdown.fromBreakdownData(breakdownAsync);

  return breakdown
      .map((item) => DepositTypeData(
            label: item.label,
            value: item.value,
            color: item.color,
            percentage: item.percentage,
          ))
      .toList();
});

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedDepositTypeIndex = -1;

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(analyticsPeriodProvider);
    final statsAsync = ref.watch(bottleStatsProvider);
    final chartDataAsync = ref.watch(chartDataProvider(period));
    final basePieDataAsync = ref.watch(depositTypeDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.share),
            onPressed: () async {
              final statsService = ref.read(statsServiceProvider);
              final now = DateTime.now();
              final startOfMonth = DateTime(now.year, now.month, 1);
              final endOfMonth = DateTime(now.year, now.month + 1, 0);

              await statsService.exportCSV(
                startDate: startOfMonth,
                endDate: endOfMonth,
              );
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authProvider);

          if (!authState.isAuthenticated) {
            return const Center(
              child: Text('Please sign in to view analytics'),
            );
          }

          // Listen for sync status changes
          final syncStatus = ref.watch(syncStatusProvider);

          return statsAsync.when(
            data: (stats) => chartDataAsync.when(
              data: (chartData) => basePieDataAsync.when(
                data: (basePieData) => RefreshIndicator(
                  onRefresh: () async {
                    // Trigger sync and refresh data
                    final syncService = ref.read(syncServiceProvider.notifier);
                    await syncService.performSync();
                    ref.invalidate(bottleStatsProvider);
                    ref.invalidate(chartDataProvider);
                    ref.invalidate(depositTypeDataProvider);
                  },
                  child: SingleChildScrollView(
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sync status indicator
                        if (syncStatus == SyncStatus.syncing)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.sm),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Syncing analytics data...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ],
                            ),
                          ),

                        // Summary Cards
                        _buildSummaryCards(context, stats),

                        const SizedBox(height: AppSpacing.xl),

                        // Period Selector
                        _buildPeriodSelector(context, ref),

                        const SizedBox(height: AppSpacing.lg),

                        // Main Chart
                        _buildMainChart(context, period, chartData),

                        const SizedBox(height: AppSpacing.xl),

                        // Deposit Types Chart
                        _buildDepositTypesChart(context, basePieData),

                        const SizedBox(height: AppSpacing.xl),

                        // Store Statistics (now using location breakdown)
                        _buildStoreStatistics(context),

                        const SizedBox(height: AppSpacing.xl),

                        // Leaderboard Section
                        _buildLeaderboard(context),

                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Error loading pie chart data',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Pull to refresh and try again',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Error loading chart data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Pull to refresh and try again',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chart_bar,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Error loading stats',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pull to refresh and try again',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: CupertinoIcons.cube_box,
                title: 'Total Bottles',
                value: stats['totalBottles'].toString(),
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                context,
                icon: CupertinoIcons.money_euro_circle,
                title: 'Total Value',
                value: '€${stats['totalValue'].toStringAsFixed(2)}',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: CupertinoIcons.chart_bar,
                title: 'Avg per Day',
                value: stats['averagePerDay'].toString(),
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                context,
                icon: CupertinoIcons.star,
                title: 'Most Common',
                value: stats['mostCommonType'],
                color: AppColors.warning,
                isSmallText: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isSmallText = false,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: isSmallText
                  ? theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in AnalyticsPeriod.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(_getPeriodLabel(p)),
                selected: period == p,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(analyticsPeriodProvider.notifier).state = p;
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  String _getPeriodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return 'Daily';
      case AnalyticsPeriod.weekly:
        return 'Weekly';
      case AnalyticsPeriod.monthly:
        return 'Monthly';
      case AnalyticsPeriod.yearly:
        return 'Yearly';
    }
  }

  Widget _buildMainChart(
      BuildContext context, AnalyticsPeriod period, List<FlSpot> data) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bottles Returned',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: _getBottomInterval(period),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _getBottomTitle(period, value),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: data.length.toDouble() - 1,
                  minY: 0,
                  maxY:
                      data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.7),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: period == AnalyticsPeriod.weekly,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: theme.scaffoldBackgroundColor,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            theme.colorScheme.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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
    );
  }

  double _getBottomInterval(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return 4;
      case AnalyticsPeriod.weekly:
        return 1;
      case AnalyticsPeriod.monthly:
        return 5;
      case AnalyticsPeriod.yearly:
        return 1;
    }
  }

  String _getBottomTitle(AnalyticsPeriod period, double value) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return '${value.toInt()}h';
      case AnalyticsPeriod.weekly:
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return value.toInt() < days.length ? days[value.toInt()] : '';
      case AnalyticsPeriod.monthly:
        return '${value.toInt() + 1}';
      case AnalyticsPeriod.yearly:
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return value.toInt() < months.length ? months[value.toInt()] : '';
    }
  }

  Widget _buildDepositTypesChart(
      BuildContext context, List<DepositTypeData> depositData) {
    final theme = Theme.of(context);

    // Convert to PieChartSectionData with selection state
    final pieChartSections = depositData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isSelected = _selectedDepositTypeIndex == index;

      return PieChartSectionData(
        color: data.color,
        value: data.value,
        title: data.percentage,
        radius: isSelected ? 70 : 60,
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deposit Types',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: PieChart(
                  PieChartData(
                    sections: pieChartSections,
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _selectedDepositTypeIndex = -1;
                            return;
                          }
                          _selectedDepositTypeIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClickableLegendItem(
                      context,
                      depositData[0],
                      0,
                      _selectedDepositTypeIndex == 0,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildClickableLegendItem(
                      context,
                      depositData[1],
                      1,
                      _selectedDepositTypeIndex == 1,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClickableLegendItem(
                      context,
                      depositData[2],
                      2,
                      _selectedDepositTypeIndex == 2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildClickableLegendItem(
                      context,
                      depositData[3],
                      3,
                      _selectedDepositTypeIndex == 3,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableLegendItem(
    BuildContext context,
    DepositTypeData data,
    int index,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDepositTypeIndex = isSelected ? -1 : index;
        });
      },
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? data.color.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          border: isSelected
              ? Border.all(color: data.color.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: data.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              data.label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              data.percentage,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? data.color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreStatistics(BuildContext context) {
    final theme = Theme.of(context);
    final locationBreakdownAsync = ref.watch(locationBreakdownProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Return Locations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            locationBreakdownAsync.when(
              data: (data) {
                final locations = data['breakdown'] as List? ?? [];
                if (locations.isEmpty) {
                  return const Text('No location data available');
                }
                final colors = [
                  AppColors.primaryLight,
                  AppColors.secondaryLight,
                  AppColors.success,
                  AppColors.warning,
                  AppColors.info
                ];
                return Column(
                  children:
                      locations.take(5).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final location = entry.value;
                    if (index > 0) {
                      return Column(
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          _buildStoreItem(
                            context,
                            location['location'] ?? 'Unknown',
                            location['count'] ?? 0,
                            colors[index % colors.length],
                          ),
                        ],
                      );
                    }
                    return _buildStoreItem(
                      context,
                      location['location'] ?? 'Unknown',
                      location['count'] ?? 0,
                      colors[index % colors.length],
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading locations: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreItem(
      BuildContext context, String name, int bottles, Color color) {
    final theme = Theme.of(context);
    final maxBottles = 100.0;
    final percentage = bottles / maxBottles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$bottles bottles',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: percentage.clamp(0.0, 1.0),
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildLeaderboard(BuildContext context) {
    final theme = Theme.of(context);
    final leaderboardAsync = ref.watch(monthlyLeaderboardProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Leaderboard',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  CupertinoIcons.star_fill,
                  color: AppColors.warning,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            leaderboardAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Text('No leaderboard data available');
                }
                return Column(
                  children: entries.take(5).map((entry) {
                    Color rankColor;
                    IconData rankIcon;
                    switch (entry.rank) {
                      case 1:
                        rankColor = const Color(0xFFFFD700);
                        rankIcon = CupertinoIcons.star_circle_fill;
                        break;
                      case 2:
                        rankColor = const Color(0xFFC0C0C0);
                        rankIcon = CupertinoIcons.star_circle;
                        break;
                      case 3:
                        rankColor = const Color(0xFFCD7F32);
                        rankIcon = CupertinoIcons.star_circle;
                        break;
                      default:
                        rankColor =
                            theme.textTheme.bodyMedium?.color ?? Colors.grey;
                        rankIcon = CupertinoIcons.person_fill;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: entry.rank <= 3
                                  ? Icon(rankIcon, color: rankColor, size: 16)
                                  : Text(
                                      '${entry.rank}',
                                      style: TextStyle(
                                        color: rankColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.username,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${entry.bottleCount} bottles',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '€${entry.totalValue.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) =>
                  Text('Error loading leaderboard: $error'),
            ),
          ],
        ),
      ),
    );
  }
}
