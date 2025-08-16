import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import 'auth_service.dart';
import '../models/bottle.dart';
import '../core/config.dart';

// Sync Status
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSync;
  final String? error;
  final int pendingChanges;

  SyncState({
    this.status = SyncStatus.idle,
    this.lastSync,
    this.error,
    this.pendingChanges = 0,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSync,
    String? error,
    int? pendingChanges,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
      error: error ?? this.error,
      pendingChanges: pendingChanges ?? this.pendingChanges,
    );
  }
}

// Sync Service
class SyncService extends StateNotifier<SyncState> {
  final Ref ref;
  final String baseUrl = ApiConfig.baseUrl;
  late Box<Bottle> _bottlesBox;
  late Box _storesBox;
  late Box _syncBox;
  late Box _pendingBox;
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;

  SyncService(this.ref) : super(SyncState()) {
    _init();
  }

  Future<void> _init() async {
    // Open Hive boxes
    _bottlesBox = await Hive.openBox<Bottle>('bottles');
    _storesBox = await Hive.openBox('stores');
    _syncBox = await Hive.openBox('sync');
    _pendingBox = await Hive.openBox('pending_sync');

    // Load last sync time
    final lastSyncString = _syncBox.get('last_sync');
    if (lastSyncString != null) {
      state = state.copyWith(
        lastSync: DateTime.parse(lastSyncString),
      );
    }

    // Count pending changes
    _updatePendingCount();

    // Listen to connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.none)) {
        state = state.copyWith(status: SyncStatus.offline);
      } else if (state.status == SyncStatus.offline) {
        // Back online, trigger sync
        performSync();
      }
    });

    // Start periodic sync (every 5 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      performSync();
    });

    // Initial sync
    performSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _updatePendingCount() {
    final pendingCount = _pendingBox.length;
    state = state.copyWith(pendingChanges: pendingCount);
  }

  Future<void> performSync() async {
    final authToken = ref.read(authTokenProvider);
    if (authToken == null) return;

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      state = state.copyWith(status: SyncStatus.offline);
      return;
    }

    state = state.copyWith(status: SyncStatus.syncing, error: null);

    try {
      // Sync pending changes first
      await _syncPendingChanges(authToken);

      // Fetch latest data from server
      await _fetchLatestData(authToken);

      // Update last sync time
      final now = DateTime.now();
      await _syncBox.put('last_sync', now.toIso8601String());

      state = state.copyWith(
        status: SyncStatus.success,
        lastSync: now,
        pendingChanges: 0,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> _syncPendingChanges(String authToken) async {
    final pendingScans = _pendingBox.get('scans', defaultValue: []);

    if (pendingScans.isNotEmpty) {
      // Bulk upload pending scans
      final response = await http.post(
        Uri.parse('$baseUrl/scan/bulkUpload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'scans': pendingScans,
        }),
      );

      if (response.statusCode == 200) {
        await _pendingBox.delete('scans');
        _updatePendingCount();
      } else {
        throw Exception('Failed to sync pending scans');
      }
    }
  }

  Future<void> _fetchLatestData(String authToken) async {
    // Fetch user's recent scans
    await _fetchUserScans(authToken);

    // Fetch nearby stores (if location available)
    await _fetchNearbyStores();

    // Fetch product catalog updates
    await _fetchProductUpdates();
  }

  Future<void> _fetchUserScans(String authToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scan/getUserScans'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'limit': 100,
          'offset': 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final scans = data['scans'] as List;

        // Update local database
        for (final scanData in scans) {
          final bottle = Bottle(
            id: scanData['id'].toString(),
            barcode: scanData['barcode'],
            name: scanData['productName'] ?? 'Unknown',
            brand: scanData['brand'] ?? 'Unknown',
            type: _parseBottleType(scanData['containerType']),
            volume: (scanData['volumeML'] ?? 0) / 1000.0,
            depositAmount: (scanData['depositCents'] ?? 0) / 100.0,
            scannedAt: DateTime.parse(scanData['scannedAt']),
            isReturned: scanData['isReturned'] ?? false,
            returnedAt: scanData['returnedAt'] != null
                ? DateTime.parse(scanData['returnedAt'])
                : null,
          );

          await _bottlesBox.put(bottle.id, bottle);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch user scans: $e');
    }
  }

  Future<void> _fetchNearbyStores() async {
    try {
      // For Austria/Vienna as default
      final response = await http.post(
        Uri.parse('$baseUrl/location/getAustrianDepositLocations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'lat': 48.2082,
          'lng': 16.3738,
          'maxDistanceKm': 50.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final locations = data['locations'] as List;

        // Clear and update stores
        await _storesBox.clear();

        for (final locationData in locations) {
          await _storesBox.put(
            locationData['id'].toString(),
            locationData,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch stores: $e');
    }
  }

  Future<void> _fetchProductUpdates() async {
    // TODO: Implement product catalog sync
  }

  BottleType _parseBottleType(String? type) {
    switch (type?.toLowerCase()) {
      case 'plastic':
        return BottleType.plastic;
      case 'glass':
        return BottleType.glass;
      case 'can':
      case 'aluminum':
        return BottleType.can;
      case 'crate':
        return BottleType.crate;
      default:
        return BottleType.plastic;
    }
  }

  // Add bottle locally with pending sync
  Future<void> addBottleLocally(Bottle bottle) async {
    // Save to local database
    await _bottlesBox.put(bottle.id, bottle);

    // Add to pending sync queue
    final pendingScans =
        _pendingBox.get('scans', defaultValue: <dynamic>[]) as List;
    pendingScans.add({
      'barcode': bottle.barcode,
      'volumeML': (bottle.volume * 1000).toInt(),
      'containerType': bottle.type.name,
      'depositCents': (bottle.depositAmount * 100).toInt(),
      'source': 'manual',
      'scannedAt': bottle.scannedAt.toIso8601String(),
    });

    await _pendingBox.put('scans', pendingScans);
    _updatePendingCount();

    // Try to sync immediately
    performSync();
  }

  // Scan barcode and get product info
  Future<Map<String, dynamic>?> scanBarcode(String barcode) async {
    try {
      // First check local cache
      final cachedProduct = _syncBox.get('product_$barcode');
      if (cachedProduct != null) {
        return json.decode(cachedProduct);
      }

      // Try to fetch from server
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        final response = await http.post(
          Uri.parse('$baseUrl/catalog/getProductByBarcode'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'barcode': barcode}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Cache the product
          await _syncBox.put('product_$barcode', json.encode(data));

          return data;
        }

        // Try external lookup
        final externalResponse = await http.post(
          Uri.parse('$baseUrl/catalog/lookupProductExternal'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'barcode': barcode}),
        );

        if (externalResponse.statusCode == 200) {
          final data = json.decode(externalResponse.body);

          // Cache the product
          await _syncBox.put('product_$barcode', json.encode(data));

          return data;
        }
      }
    } catch (e) {
      debugPrint('Failed to scan barcode: $e');
    }

    return null;
  }

  // Get stats from local data
  Future<Map<String, dynamic>> getLocalStats() async {
    final bottles = _bottlesBox.values.toList();

    final totalBottles = bottles.length;
    final returnedBottles = bottles.where((b) => b.isReturned).length;
    final totalValue = bottles.fold<double>(
      0,
      (sum, bottle) => sum + bottle.depositAmount,
    );

    // Group by type
    final typeBreakdown = <String, int>{};
    for (final bottle in bottles) {
      typeBreakdown[bottle.type.name] =
          (typeBreakdown[bottle.type.name] ?? 0) + 1;
    }

    return {
      'totalBottles': totalBottles,
      'returnedBottles': returnedBottles,
      'pendingBottles': totalBottles - returnedBottles,
      'totalValue': totalValue,
      'typeBreakdown': typeBreakdown,
      'lastSync': state.lastSync?.toIso8601String(),
      'pendingChanges': state.pendingChanges,
    };
  }
}

// Providers
final syncServiceProvider =
    StateNotifierProvider<SyncService, SyncState>((ref) {
  return SyncService(ref);
});

final localStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final syncService = ref.read(syncServiceProvider.notifier);
  return syncService.getLocalStats();
});

final syncStatusProvider = Provider<SyncStatus>((ref) {
  return ref.watch(syncServiceProvider).status;
});

// Bottles provider for accessing user's bottles
final bottlesProvider = FutureProvider<List<Bottle>>((ref) async {
  final syncService = ref.read(syncServiceProvider.notifier);
  return syncService._bottlesBox.values.toList();
});

final lastSyncProvider = Provider<DateTime?>((ref) {
  return ref.watch(syncServiceProvider).lastSync;
});

final pendingChangesProvider = Provider<int>((ref) {
  return ref.watch(syncServiceProvider).pendingChanges;
});
