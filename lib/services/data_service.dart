import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

enum ConnectionStatus {
  online,
  offline,
  connecting,
}

class DataService extends StateNotifier<ConnectionStatus> {
  static const String _cacheBoxName = 'offline_cache';
  static const String _bottlesKey = 'bottles';
  static const String _locationsKey = 'locations';
  static const String _analyticsKey = 'analytics';
  static const String _lastSyncKey = 'last_sync';
  
  Box? _cacheBox;
  http.Client? _client;
  final Connectivity _connectivity = Connectivity();
  final String _serverUrl = 'http://localhost:8080';
  
  DataService() : super(ConnectionStatus.connecting) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Open cache box for offline data
      _cacheBox = await Hive.openBox(_cacheBoxName);
      
      // Check connectivity
      await _checkConnectivity();
      
      // Listen to connectivity changes
      _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      });
      
      // Try to connect to server
      await _connectToServer();
    } catch (e) {
      debugPrint('Failed to initialize DataService: $e');
      state = ConnectionStatus.offline;
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      state = ConnectionStatus.offline;
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      state = ConnectionStatus.offline;
      debugPrint('Network disconnected - switching to offline mode');
    } else {
      // Try to reconnect when network is available
      _connectToServer();
    }
  }

  Future<void> _connectToServer() async {
    if (state == ConnectionStatus.online) return;
    
    state = ConnectionStatus.connecting;
    
    try {
      // Initialize HTTP client if not already done
      _client ??= http.Client();
      
      // Test connection with a simple health check
      final response = await _client!
          .get(Uri.parse('$_serverUrl/health'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        state = ConnectionStatus.online;
        debugPrint('Connected to server - online mode');
        
        // Sync local data with server
        await _syncData();
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to connect to server: $e');
      state = ConnectionStatus.offline;
      debugPrint('Using offline mode with cached data');
    }
  }

  Future<void> _syncData() async {
    if (state != ConnectionStatus.online || _client == null) return;
    
    try {
      final lastSync = _cacheBox?.get(_lastSyncKey) as DateTime?;
      
      // Sync bottles data
      await _syncBottles(lastSync);
      
      // Sync locations data
      await _syncLocations(lastSync);
      
      // Sync analytics data
      await _syncAnalytics(lastSync);
      
      // Update last sync time
      await _cacheBox?.put(_lastSyncKey, DateTime.now());
      
      debugPrint('Data sync completed successfully');
    } catch (e) {
      debugPrint('Failed to sync data: $e');
    }
  }

  Future<void> _syncBottles(DateTime? lastSync) async {
    // Implement bottle sync logic
    // For now, using mock data
    final bottles = [
      {
        'id': '1',
        'type': 'plastic',
        'value': 0.25,
        'collectedAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'type': 'glass',
        'value': 0.08,
        'collectedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
    
    await _cacheBox?.put(_bottlesKey, bottles);
  }

  Future<void> _syncLocations(DateTime? lastSync) async {
    // Implement location sync logic
    // For now, using mock data
    final locations = [
      {
        'id': '1',
        'name': 'REWE',
        'address': 'Hauptstraße 1, 12345 Berlin',
        'lat': 52.520008,
        'lng': 13.404954,
        'openingHours': {
          'monday': '08:00-20:00',
          'tuesday': '08:00-20:00',
          'wednesday': '08:00-20:00',
          'thursday': '08:00-20:00',
          'friday': '08:00-20:00',
          'saturday': '08:00-18:00',
          'sunday': 'closed',
        },
      },
      {
        'id': '2',
        'name': 'EDEKA',
        'address': 'Marktplatz 5, 12345 Berlin',
        'lat': 52.523429,
        'lng': 13.411440,
        'openingHours': {
          'monday': '07:00-21:00',
          'tuesday': '07:00-21:00',
          'wednesday': '07:00-21:00',
          'thursday': '07:00-21:00',
          'friday': '07:00-21:00',
          'saturday': '07:00-20:00',
          'sunday': '09:00-18:00',
        },
      },
    ];
    
    await _cacheBox?.put(_locationsKey, locations);
  }

  Future<void> _syncAnalytics(DateTime? lastSync) async {
    // Implement analytics sync logic
    // For now, using mock data
    final analytics = {
      'totalBottles': 156,
      'totalValue': 28.50,
      'weeklyData': [
        {'day': 'Mon', 'count': 12, 'value': 2.40},
        {'day': 'Tue', 'count': 8, 'value': 1.60},
        {'day': 'Wed', 'count': 15, 'value': 3.00},
        {'day': 'Thu', 'count': 10, 'value': 2.00},
        {'day': 'Fri', 'count': 18, 'value': 3.60},
        {'day': 'Sat', 'count': 22, 'value': 4.40},
        {'day': 'Sun', 'count': 5, 'value': 1.00},
      ],
      'monthlyData': [
        {'month': 'Jan', 'count': 120, 'value': 24.00},
        {'month': 'Feb', 'count': 156, 'value': 28.50},
      ],
    };
    
    await _cacheBox?.put(_analyticsKey, analytics);
  }

  // Public methods to get data
  Future<List<dynamic>> getBottles() async {
    if (state == ConnectionStatus.online && _client != null) {
      try {
        // Try to get from server
        // final bottles = await _client!.bottles.getAll();
        // return bottles;
      } catch (e) {
        debugPrint('Failed to get bottles from server: $e');
      }
    }
    
    // Fallback to cached data
    final cachedBottles = _cacheBox?.get(_bottlesKey) as List<dynamic>?;
    return cachedBottles ?? [];
  }

  Future<List<dynamic>> getLocations() async {
    if (state == ConnectionStatus.online && _client != null) {
      try {
        // Try to get from server
        // final locations = await _client!.locations.getAll();
        // return locations;
      } catch (e) {
        debugPrint('Failed to get locations from server: $e');
      }
    }
    
    // Fallback to cached data
    final cachedLocations = _cacheBox?.get(_locationsKey) as List<dynamic>?;
    return cachedLocations ?? [];
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    if (state == ConnectionStatus.online && _client != null) {
      try {
        // Try to get from server
        // final analytics = await _client!.analytics.get();
        // return analytics;
      } catch (e) {
        debugPrint('Failed to get analytics from server: $e');
      }
    }
    
    // Fallback to cached data
    final cachedAnalytics = _cacheBox?.get(_analyticsKey) as Map<String, dynamic>?;
    return cachedAnalytics ?? {};
  }

  // Method to manually trigger sync
  Future<void> refreshData() async {
    if (state == ConnectionStatus.offline) {
      await _connectToServer();
    } else if (state == ConnectionStatus.online) {
      await _syncData();
    }
  }

  // Method to save data locally first (for offline-first approach)
  Future<void> saveBottleLocally(Map<String, dynamic> bottle) async {
    final bottles = await getBottles();
    bottles.add(bottle);
    await _cacheBox?.put(_bottlesKey, bottles);
    
    // Try to sync with server if online
    if (state == ConnectionStatus.online && _client != null) {
      try {
        // await _client!.bottles.create(bottle);
      } catch (e) {
        debugPrint('Failed to sync bottle with server: $e');
        // Data is saved locally, will sync later
      }
    }
  }

  DateTime? get lastSyncTime => _cacheBox?.get(_lastSyncKey) as DateTime?;
  
  bool get isOffline => state == ConnectionStatus.offline;
  bool get isOnline => state == ConnectionStatus.online;
  bool get isConnecting => state == ConnectionStatus.connecting;
}

// Provider for data service
final dataServiceProvider = StateNotifierProvider<DataService, ConnectionStatus>((ref) {
  return DataService();
});

// Provider for connection status text
final connectionStatusTextProvider = Provider<String>((ref) {
  final status = ref.watch(dataServiceProvider);
  switch (status) {
    case ConnectionStatus.online:
      return 'Online';
    case ConnectionStatus.offline:
      return 'Offline Mode';
    case ConnectionStatus.connecting:
      return 'Connecting...';
  }
});