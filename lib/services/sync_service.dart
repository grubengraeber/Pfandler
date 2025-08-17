import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'auth_service.dart';
import '../models/bottle.dart';
import 'api/api_client.dart';

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
  late final ApiClient _apiClient;
  Box<Bottle>? _bottlesBox;
  Box? _storesBox;
  Box? _syncBox;
  Box? _pendingBox;
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  SyncService(this.ref) : super(SyncState()) {
    _apiClient = ApiClient();
    _init();
  }

  Future<void> waitForInit() async {
    if (_isInitialized) return;
    await _initCompleter.future;
  }

  Future<void> _init() async {
    try {
      // Open Hive boxes
      _bottlesBox = await Hive.openBox<Bottle>('bottles');
      _storesBox = await Hive.openBox('stores');
      _syncBox = await Hive.openBox('sync');
      _pendingBox = await Hive.openBox('pending_sync');

      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }

      // Load last sync time
      final lastSyncString = _syncBox?.get('last_sync');
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
    } catch (e) {
      debugPrint('Failed to initialize SyncService: $e');
      // Even if init fails, complete the completer to prevent hanging
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _updatePendingCount() {
    final pendingCount = _pendingBox?.length ?? 0;
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
      await _syncBox?.put('last_sync', now.toIso8601String());

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
    // TODO: Implement pending changes sync using ApiClient
    // This would need a bulk upload endpoint in ApiClient
    final pendingScans = _pendingBox?.get('scans', defaultValue: []) ?? [];
    if (pendingScans.isNotEmpty) {
      // For now, just clear pending since we can't sync yet
      await _pendingBox?.delete('scans');
      _updatePendingCount();
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
      // TODO: Implement using ApiClient when getUserScans is ready
      _apiClient.setAuthToken(authToken);
      // final scans = await _apiClient.getUserScans(limit: 100, offset: 0);
      // Process and store scans...
    } catch (e) {
      debugPrint('Failed to fetch user scans: $e');
    }
  }

  Future<void> _fetchNearbyStores() async {
    try {
      // TODO: Implement using ApiClient
      // final locations = await _apiClient.getAustrianDepositLocations(
      //   lat: 48.2082,
      //   lng: 16.3738,
      // );
      // Store locations...
    } catch (e) {
      debugPrint('Failed to fetch stores: $e');
    }
  }

  Future<void> _fetchProductUpdates() async {
    // TODO: Implement product catalog sync
  }

  // Add bottle locally with pending sync
  Future<void> addBottleLocally(Bottle bottle) async {
    // Save to local database
    await _bottlesBox?.put(bottle.id, bottle);

    // Add to pending sync queue
    final pendingScans =
        (_pendingBox?.get('scans', defaultValue: <dynamic>[]) ?? <dynamic>[])
            as List;
    pendingScans.add({
      'barcode': bottle.barcode,
      'volumeML': (bottle.volume * 1000).toInt(),
      'containerType': bottle.type.name,
      'depositCents': (bottle.depositAmount * 100).toInt(),
      'source': 'manual',
      'scannedAt': bottle.scannedAt.toIso8601String(),
    });

    await _pendingBox?.put('scans', pendingScans);
    _updatePendingCount();

    // Try to sync immediately
    performSync();
  }

  // Scan barcode and get product info
  Future<Map<String, dynamic>?> scanBarcode(String barcode) async {
    try {
      // First check local cache
      final cachedProduct = _syncBox?.get('product_$barcode');
      if (cachedProduct != null) {
        return json.decode(cachedProduct);
      }

      // Try to fetch from server
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        // TODO: Implement using ApiClient
        // final product = await _apiClient.getProductByBarcode(barcode: barcode);
        // if (product != null) {
        //   await _syncBox?.put('product_$barcode', json.encode(product));
        //   return product;
        // }
      }
    } catch (e) {
      debugPrint('Failed to scan barcode: $e');
    }

    return null;
  }

  // Get stats from local data
  Future<Map<String, dynamic>> getLocalStats() async {
    final bottles = _bottlesBox?.values.toList() ?? [];

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
  await syncService.waitForInit();
  return syncService._bottlesBox?.values.toList() ?? [];
});

// Stores provider for accessing stores
final storesProvider = FutureProvider<List<dynamic>>((ref) async {
  final syncService = ref.read(syncServiceProvider.notifier);
  await syncService.waitForInit();
  return syncService._storesBox?.values.toList() ?? [];
});

final lastSyncProvider = Provider<DateTime?>((ref) {
  return ref.watch(syncServiceProvider).lastSync;
});

final pendingChangesProvider = Provider<int>((ref) {
  return ref.watch(syncServiceProvider).pendingChanges;
});
