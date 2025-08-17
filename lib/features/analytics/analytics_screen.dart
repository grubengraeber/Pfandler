import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:screenshot/screenshot.dart'; // Temporarily disabled - incompatible with Flutter 3.16.0
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../services/stats_service.dart';
import '../../services/sync_service.dart';
import '../../l10n/app_localizations.dart';

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
    if (breakdown.isNotEmpty) {
      var maxCount = 0;
      breakdown.forEach((type, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonType = type;
        }
      });
    }

    final daysSinceStart = now.difference(startOfMonth).inDays + 1;
    final avgPerDay = totals['totalCount'] / daysSinceStart;

    return {
      'totalBottles': totals['totalCount'] ?? 0,
      'totalValue': totals['totalValue'] ?? 0.0,
      'averagePerDay': avgPerDay,
      'mostCommonType': mostCommonType,
    };
  } catch (e) {
    // Fall back to local sync data if server request fails
    final bottles = await ref.read(bottlesProvider.future);
    
    if (bottles.isEmpty) {
      return {
        'totalBottles': 0,
        'totalValue': 0.0,
        'averagePerDay': 0.0,
        'mostCommonType': 'Unknown',
      };
    }

    final totalValue = bottles.fold<double>(
      0, (sum, bottle) => sum + bottle.depositAmount
    );

    // Calculate average per day
    final oldestBottle = bottles.reduce((a, b) => 
      a.scannedAt.isBefore(b.scannedAt) ? a : b
    );
    final daysSinceFirst = DateTime.now().difference(oldestBottle.scannedAt).inDays + 1;
    final avgPerDay = bottles.length / daysSinceFirst;

    // Find most common type
    final typeCount = <String, int>{};
    for (final bottle in bottles) {
      typeCount[bottle.typeLabel] = (typeCount[bottle.typeLabel] ?? 0) + 1;
    }
    String mostCommonType = 'Unknown';
    if (typeCount.isNotEmpty) {
      mostCommonType = typeCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return {
      'totalBottles': bottles.length,
      'totalValue': totalValue,
      'averagePerDay': avgPerDay,
      'mostCommonType': mostCommonType,
    };
  }
});

// Chart data providers
final chartDataProvider = FutureProvider<List<FlSpot>>((ref) async {
  final period = ref.watch(analyticsPeriodProvider);
  final authState = ref.read(authProvider);
  
  if (!authState.isAuthenticated) {
    return [];
  }

  // Generate appropriate date range based on period
  int dataPoints;
  
  switch (period) {
    case AnalyticsPeriod.daily:
      dataPoints = 7;
      break;
    case AnalyticsPeriod.weekly:
      dataPoints = 4;
      break;
    case AnalyticsPeriod.monthly:
      dataPoints = 12;
      break;
    case AnalyticsPeriod.yearly:
      dataPoints = 5;
      break;
  }

  // Generate chart data based on actual bottle data
  try {
    final bottles = await ref.read(bottlesProvider.future);
    if (bottles.isEmpty) {
      return List.generate(dataPoints, (index) => FlSpot(index.toDouble(), 0));
    }
    
    // Group bottles by time period
    final now = DateTime.now();
    final counts = List.filled(dataPoints, 0);
    
    for (final bottle in bottles) {
      final daysDiff = now.difference(bottle.scannedAt).inDays;
      int index = -1;
      
      switch (period) {
        case AnalyticsPeriod.daily:
          if (daysDiff < 7) {
            index = 6 - daysDiff;
          }
          break;
        case AnalyticsPeriod.weekly:
          final weeksDiff = daysDiff ~/ 7;
          if (weeksDiff < 4) {
            index = 3 - weeksDiff;
          }
          break;
        case AnalyticsPeriod.monthly:
          final monthsDiff = daysDiff ~/ 30;
          if (monthsDiff < 12) {
            index = 11 - monthsDiff;
          }
          break;
        case AnalyticsPeriod.yearly:
          final yearsDiff = daysDiff ~/ 365;
          if (yearsDiff < 5) {
            index = 4 - yearsDiff;
          }
          break;
      }
      
      if (index >= 0 && index < dataPoints) {
        counts[index]++;
      }
    }
    
    return List.generate(dataPoints, (index) {
      return FlSpot(index.toDouble(), counts[index].toDouble());
    });
  } catch (e) {
    // Fallback to empty data
    return List.generate(dataPoints, (index) => FlSpot(index.toDouble(), 0));
  }
});

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedDepositTypeIndex = -1;
  // final ScreenshotController _screenshotController = ScreenshotController(); // Temporarily disabled
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.analytics ?? 'Analytics'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: _isSharing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CupertinoIcons.share),
            onPressed: _isSharing ? null : _shareAnalytics,
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final statsAsync = ref.watch(bottleStatsProvider);
          final chartDataAsync = ref.watch(chartDataProvider);
          final depositDataAsync = ref.watch(depositPieDataProvider);
          final basePieDataAsync = ref.watch(bottleTypePieDataProvider);

          return statsAsync.when(
            data: (stats) => chartDataAsync.when(
              data: (chartData) => depositDataAsync.when(
                data: (depositData) => basePieDataAsync.when(
                  data: (basePieData) => Container( // Screenshot temporarily disabled
                    color: theme.scaffoldBackgroundColor,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsCards(context, stats),
                          const SizedBox(height: AppSpacing.xl),
                          _buildPeriodSelector(context),
                          const SizedBox(height: AppSpacing.xl),
                          _buildTrendChart(context, chartData),
                          const SizedBox(height: AppSpacing.xl),
                          _buildDepositTypesChart(context, depositData),
                          const SizedBox(height: AppSpacing.xl),
                          _buildBottleTypesChart(context, basePieData),
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
                          'Error loading deposit data',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading deposit data: $error'),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading chart data: $error'),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading stats: $error'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareAnalytics() async {
    setState(() {
      _isSharing = true;
    });

    final l10n = AppLocalizations.of(context);
    final shareText = l10n?.translate('shareAnalytics') ?? 'Check out my Pfandler bottle return analytics!';

    try {
      // Screenshot functionality temporarily disabled for Flutter 3.16.0 compatibility
      // TODO: Re-enable when screenshot package is compatible
      
      // For now, just share text without screenshot
      await Share.share(
        shareText,
        subject: 'Pfandler Analytics',
      );
      
      /* Original screenshot code - to be restored later:
      // Capture the screenshot
      final image = await _screenshotController.capture();
      if (image == null) {
        throw Exception('Failed to capture screenshot');
      }

      // Save the image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'pfandler_analytics_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path.join(tempDir.path, fileName));
      await file.writeAsBytes(image);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'Pfandler Analytics',
      );

      // Clean up the temporary file after a delay
      Future.delayed(const Duration(seconds: 10), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
      */
    } catch (e) {
      final failedMessage = l10n?.translate('failedToShare') ?? 'Failed to share analytics';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$failedMessage: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Widget _buildStatsCards(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: l10n?.totalBottles ?? 'Total Bottles',
                value: stats['totalBottles'].toString(),
                icon: CupertinoIcons.cube_box_fill,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                context,
                title: l10n?.translate('totalValue') ?? 'Total Value',
                value: '€${stats['totalValue'].toStringAsFixed(2)}',
                icon: CupertinoIcons.money_euro_circle_fill,
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
                title: l10n?.translate('averagePerDay') ?? 'Avg/Day',
                value: stats['averagePerDay'].toStringAsFixed(1),
                icon: CupertinoIcons.chart_bar_fill,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                context,
                title: l10n?.translate('mostCommon') ?? 'Most Common',
                value: stats['mostCommonType'] == 'Unknown' 
                    ? (l10n?.translate('unknown') ?? 'Unknown')
                    : stats['mostCommonType'],
                icon: CupertinoIcons.star_fill,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
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
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: AnalyticsPeriod.values.map((period) {
            final isSelected = ref.watch(analyticsPeriodProvider) == period;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(
                    _getLocalizedPeriod(l10n, period),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(analyticsPeriodProvider.notifier).state = period;
                    }
                  },
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, List<FlSpot> chartData) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final period = ref.watch(analyticsPeriodProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.translate('returnTrend') ?? 'Return Trend',
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
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _getBottomTitle(value, period, l10n),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  minX: 0,
                  maxX: chartData.length - 1,
                  minY: 0,
                  maxY: chartData.isEmpty 
                      ? 10 
                      : chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
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
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.3),
                            theme.colorScheme.primary.withValues(alpha: 0),
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

  String _getLocalizedPeriod(AppLocalizations? l10n, AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return l10n?.translate('daily') ?? 'Daily';
      case AnalyticsPeriod.weekly:
        return l10n?.translate('weekly') ?? 'Weekly';
      case AnalyticsPeriod.monthly:
        return l10n?.translate('monthly') ?? 'Monthly';
      case AnalyticsPeriod.yearly:
        return l10n?.translate('yearly') ?? 'Yearly';
    }
  }

  String _getBottomTitle(double value, AnalyticsPeriod period, AppLocalizations? l10n) {
    switch (period) {
      case AnalyticsPeriod.daily:
        final days = l10n != null ? [
          l10n.translate('mon'),
          l10n.translate('tue'),
          l10n.translate('wed'),
          l10n.translate('thu'),
          l10n.translate('fri'),
          l10n.translate('sat'),
          l10n.translate('sun'),
        ] : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return value.toInt() < days.length ? days[value.toInt()] : '';
      case AnalyticsPeriod.weekly:
        final weekAbbr = l10n?.translate('weekAbbr') ?? 'W';
        return '$weekAbbr${value.toInt() + 1}';
      case AnalyticsPeriod.monthly:
        return '${value.toInt() + 1}';
      case AnalyticsPeriod.yearly:
        final months = l10n != null ? [
          l10n.translate('jan'),
          l10n.translate('feb'),
          l10n.translate('mar'),
          l10n.translate('apr'),
          l10n.translate('mayShort'),
          l10n.translate('jun'),
          l10n.translate('jul'),
          l10n.translate('aug'),
          l10n.translate('sep'),
          l10n.translate('oct'),
          l10n.translate('nov'),
          l10n.translate('dec'),
        ] : [
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
    final l10n = AppLocalizations.of(context);

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
              l10n?.translate('depositTypes') ?? 'Deposit Types',
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
                    if (depositData.isNotEmpty)
                      _buildClickableLegendItem(
                        context,
                        depositData[0],
                        0,
                        _selectedDepositTypeIndex == 0,
                      ),
                    if (depositData.length > 1) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildClickableLegendItem(
                        context,
                        depositData[1],
                        1,
                        _selectedDepositTypeIndex == 1,
                      ),
                    ],
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (depositData.length > 2)
                      _buildClickableLegendItem(
                        context,
                        depositData[2],
                        2,
                        _selectedDepositTypeIndex == 2,
                      ),
                    if (depositData.length > 3) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildClickableLegendItem(
                        context,
                        depositData[3],
                        3,
                        _selectedDepositTypeIndex == 3,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottleTypesChart(
      BuildContext context, List<PieChartSectionData> pieData) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.translate('bottleTypes') ?? 'Bottle Types',
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
                    sections: pieData,
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                  ),
                ),
              ),
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
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDepositTypeIndex = isSelected ? -1 : index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? data.color.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          border: isSelected
              ? Border.all(color: data.color, width: 2)
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
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              data.label == 'No Data' 
                  ? (AppLocalizations.of(context)?.translate('noData') ?? 'No Data')
                  : data.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              data.percentage,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data classes for charts
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

// Providers for pie chart data
final depositPieDataProvider = FutureProvider<List<DepositTypeData>>((ref) async {
  final bottles = await ref.read(bottlesProvider.future);
  
  if (bottles.isEmpty) {
    return [
      DepositTypeData(
        label: 'No Data',
        value: 1,
        color: Colors.grey,
        percentage: '100%',
      ),
    ];
  }

  // Group by deposit amount
  final depositGroups = <double, int>{};
  for (final bottle in bottles) {
    depositGroups[bottle.depositAmount] = 
        (depositGroups[bottle.depositAmount] ?? 0) + 1;
  }

  final total = bottles.length;
  final colors = [
    AppColors.primaryLight,
    AppColors.secondaryLight,
    AppColors.success,
    AppColors.warning,
  ];

  final sortedEntries = depositGroups.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
    
  return sortedEntries.take(4).map((entry) {
    final index = depositGroups.keys.toList().indexOf(entry.key);
    return DepositTypeData(
      label: '€${entry.key.toStringAsFixed(2)}',
      value: entry.value.toDouble(),
      color: colors[index % colors.length],
      percentage: '${((entry.value / total) * 100).toStringAsFixed(0)}%',
    );
  }).toList();
});

final bottleTypePieDataProvider = FutureProvider<List<PieChartSectionData>>((ref) async {
  final bottles = await ref.read(bottlesProvider.future);
  
  if (bottles.isEmpty) {
    return [
      PieChartSectionData(
        color: Colors.grey,
        value: 1,
        title: 'No Data',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  // Group by bottle type
  final typeGroups = <String, int>{};
  for (final bottle in bottles) {
    typeGroups[bottle.typeLabel] = 
        (typeGroups[bottle.typeLabel] ?? 0) + 1;
  }

  final total = bottles.length;
  final colors = [
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
  ];

  final sortedEntries = typeGroups.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
    
  return sortedEntries.take(4).map((entry) {
    final index = typeGroups.keys.toList().indexOf(entry.key);
    final percentage = ((entry.value / total) * 100).toStringAsFixed(0);
    return PieChartSectionData(
      color: colors[index % colors.length],
      value: entry.value.toDouble(),
      title: '$percentage%',
      radius: 60,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }).toList();
});