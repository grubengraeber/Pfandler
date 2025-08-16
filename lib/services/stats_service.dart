import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import 'auth_service.dart';
import '../core/theme/app_colors.dart';
import '../core/config.dart';

class StatsService {
  final Ref ref;
  final String baseUrl = ApiConfig.baseUrl;

  StatsService(this.ref);

  // Get total statistics for date range
  Future<Map<String, dynamic>> getTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final authToken = ref.read(authTokenProvider);
    if (authToken == null) throw Exception('Not authenticated');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stats/totals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get totals');
    } catch (e) {
      debugPrint('Error getting totals: $e');
      // Return mock data as fallback
      return {
        'totalBottles': 247,
        'totalValue': 61.75,
        'averagePerDay': 8.2,
        'co2Saved': 123.5,
      };
    }
  }

  // Get breakdown by category
  Future<Map<String, dynamic>> getBreakdown({
    required String breakdownBy,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final authToken = ref.read(authTokenProvider);
    if (authToken == null) throw Exception('Not authenticated');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stats/breakdown'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'breakdownBy': breakdownBy,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get breakdown');
    } catch (e) {
      debugPrint('Error getting breakdown: $e');
      // Return mock data as fallback
      return _getMockBreakdown(breakdownBy);
    }
  }

  // Export data as CSV
  Future<String?> exportCSV({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final authToken = ref.read(authTokenProvider);
    if (authToken == null) throw Exception('Not authenticated');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stats/exportCSV'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return response.body;
      }
      throw Exception('Failed to export CSV');
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return null;
    }
  }

  // Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String period,
    int limit = 10,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stats/getLeaderboard'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'period': period,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['leaderboard'] as List)
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList();
      }
      throw Exception('Failed to get leaderboard');
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      // Return mock data
      return _getMockLeaderboard();
    }
  }

  Map<String, dynamic> _getMockBreakdown(String breakdownBy) {
    switch (breakdownBy) {
      case 'containerType':
        return {
          'breakdown': [
            {'type': 'plastic', 'count': 145, 'value': 36.25},
            {'type': 'glass', 'count': 67, 'value': 6.03},
            {'type': 'can', 'count': 35, 'value': 8.75},
          ]
        };
      case 'brand':
        return {
          'breakdown': [
            {'brand': 'Coca-Cola', 'count': 45, 'percentage': 18.2},
            {'brand': 'Fanta', 'count': 30, 'percentage': 12.1},
            {'brand': 'Sprite', 'count': 25, 'percentage': 10.1},
            {'brand': 'Red Bull', 'count': 20, 'percentage': 8.1},
            {'brand': 'Others', 'count': 127, 'percentage': 51.5},
          ]
        };
      case 'location':
        return {
          'breakdown': [
            {'location': 'Billa Hauptbahnhof', 'count': 87},
            {'location': 'SPAR Mariahilfer', 'count': 65},
            {'location': 'Hofer Favoriten', 'count': 43},
            {'location': 'Lidl Meidling', 'count': 32},
            {'location': 'Penny Ottakring', 'count': 20},
          ]
        };
      default:
        return {'breakdown': []};
    }
  }

  List<LeaderboardEntry> _getMockLeaderboard() {
    return [
      LeaderboardEntry(
        rank: 1,
        userId: '1',
        username: 'EcoWarrior',
        bottleCount: 523,
        totalValue: 130.75,
      ),
      LeaderboardEntry(
        rank: 2,
        userId: '2',
        username: 'GreenHero',
        bottleCount: 412,
        totalValue: 103.00,
      ),
      LeaderboardEntry(
        rank: 3,
        userId: '3',
        username: 'RecycleKing',
        bottleCount: 387,
        totalValue: 96.75,
      ),
    ];
  }

  // Convert period data to chart spots
  List<FlSpot> convertToChartData(Map<String, dynamic> data, String period) {
    final List<FlSpot> spots = [];
    
    if (data['chartData'] != null) {
      final chartData = data['chartData'] as List;
      for (int i = 0; i < chartData.length; i++) {
        spots.add(FlSpot(i.toDouble(), chartData[i]['value'].toDouble()));
      }
    } else {
      // Generate mock data based on period
      switch (period) {
        case 'daily':
          for (int i = 0; i < 24; i++) {
            spots.add(FlSpot(i.toDouble(), (5 + (i % 8) * 2).toDouble()));
          }
          break;
        case 'weekly':
          spots.addAll([
            const FlSpot(0, 12),
            const FlSpot(1, 8),
            const FlSpot(2, 15),
            const FlSpot(3, 10),
            const FlSpot(4, 18),
            const FlSpot(5, 14),
            const FlSpot(6, 9),
          ]);
          break;
        case 'monthly':
          for (int i = 0; i < 30; i++) {
            spots.add(FlSpot(i.toDouble(), (10 + (i % 10) * 3).toDouble()));
          }
          break;
        case 'yearly':
          for (int i = 0; i < 12; i++) {
            spots.add(FlSpot(i.toDouble(), (50 + (i % 4) * 20).toDouble()));
          }
          break;
      }
    }
    
    return spots;
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final int bottleCount;
  final double totalValue;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.bottleCount,
    required this.totalValue,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'],
      userId: json['userId'].toString(),
      username: json['username'],
      bottleCount: json['bottleCount'],
      totalValue: json['totalValue'].toDouble(),
    );
  }
}

class DepositTypeBreakdown {
  final String label;
  final double value;
  final Color color;
  final String percentage;

  DepositTypeBreakdown({
    required this.label,
    required this.value,
    required this.color,
    required this.percentage,
  });

  static List<DepositTypeBreakdown> fromBreakdownData(Map<String, dynamic> data) {
    final breakdown = data['breakdown'] as List? ?? [];
    final colors = [
      AppColors.primaryLight,
      AppColors.secondaryLight,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    
    final List<DepositTypeBreakdown> result = [];
    final total = breakdown.fold<double>(
      0, 
      (sum, item) => sum + (item['count'] ?? 0).toDouble(),
    );
    
    for (int i = 0; i < breakdown.length && i < colors.length; i++) {
      final item = breakdown[i];
      final count = (item['count'] ?? 0).toDouble();
      final percentage = total > 0 ? (count / total * 100) : 0.0;
      
      result.add(DepositTypeBreakdown(
        label: item['type'] ?? item['brand'] ?? 'Unknown',
        value: count,
        color: colors[i],
        percentage: '${percentage.toStringAsFixed(1)}%',
      ));
    }
    
    return result;
  }
}

// Providers
final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService(ref);
});

// Stats providers for different periods
final currentMonthStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(statsServiceProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  
  return service.getTotals(
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
});

final containerTypeBreakdownProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(statsServiceProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  
  return service.getBreakdown(
    breakdownBy: 'containerType',
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
});

final locationBreakdownProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(statsServiceProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  
  return service.getBreakdown(
    breakdownBy: 'location',
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
});

final monthlyLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final service = ref.read(statsServiceProvider);
  return service.getLeaderboard(period: 'month');
});