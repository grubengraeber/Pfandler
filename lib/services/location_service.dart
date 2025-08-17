import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'auth_service.dart';
import '../models/store.dart';
import '../core/config.dart';

class LocationService {
  final Ref ref;
  final String baseUrl = ApiConfig.baseUrl;
  Box? _locationCache;

  LocationService(this.ref) {
    _init();
  }

  Future<void> _init() async {
    _locationCache = await Hive.openBox('location_cache');
  }

  Future<Box> _getLocationCache() async {
    _locationCache ??= await Hive.openBox('location_cache');
    return _locationCache!;
  }

  // Get Austrian deposit locations
  Future<List<Store>> getAustrianDepositLocations({
    required double lat,
    required double lng,
    double maxDistanceKm = 50.0,
  }) async {
    try {
      // Check cache first
      final cache = await _getLocationCache();
      final cacheKey = 'locations_${lat}_${lng}_$maxDistanceKm';
      final cached = cache.get(cacheKey);

      if (cached != null) {
        try {
          final cachedData = json.decode(cached);
          final cachedTime = DateTime.parse(cachedData['timestamp']);

          // Use cache if less than 1 hour old
          if (DateTime.now().difference(cachedTime) < const Duration(hours: 1)) {
              return _parseStores(cachedData['locations']);
          }
        } catch (cacheError) {
          // Continue to fetch from server
        }
      }

      // Try to fetch from server with timeout
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/location/getAustrianDepositLocations'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'lat': lat,
            'lng': lng,
            'maxDistanceKm': maxDistanceKm,
          }),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            // Handle both array and object response formats
            List<dynamic> locations = [];
            if (data is List) {
              locations = data;
            } else if (data is Map && data['locations'] != null) {
              locations = data['locations'] as List? ?? [];
            }


            // Cache the result
            await cache.put(
                cacheKey,
                json.encode({
                  'timestamp': DateTime.now().toIso8601String(),
                  'locations': locations,
                }));

            return _parseStores(locations);
          } catch (parseError) {
            rethrow;
          }
        }
        
        throw Exception('Failed to get locations: Status ${response.statusCode}');
      } catch (e) {
        
        // Try to use any cached data, even if expired
        if (cached != null) {
          try {
            final cachedData = json.decode(cached);
            return _parseStores(cachedData['locations']);
          } catch (expiredCacheError) {
            // Fall through to mock data
          }
        }
        
        // Fall through to mock data
        rethrow;
      }
    } catch (e) {
      // Return mock data as fallback
      return _getMockStores();
    }
  }

  // Get nearby locations
  Future<List<Store>> getNearbyLocations({
    required double lat,
    required double lng,
    double maxDistanceKm = 10.0,
  }) async {
    final authToken = ref.read(authTokenProvider);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/location/nearby'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'lat': lat,
          'lng': lng,
          'maxDistanceKm': maxDistanceKm,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          // Handle both array and object response formats
          List<dynamic> locations = [];
          if (data is List) {
            locations = data;
          } else if (data is Map && data['locations'] != null) {
            locations = data['locations'] as List? ?? [];
          }
          
          return _parseStores(locations);
        } catch (parseError) {
          rethrow;
        }
      }
      throw Exception('Failed to get nearby locations: Status ${response.statusCode}');
    } catch (e) {
      // Fallback to Austrian locations
      return getAustrianDepositLocations(
        lat: lat,
        lng: lng,
        maxDistanceKm: maxDistanceKm,
      );
    }
  }

  // Search locations by query - implements client-side filtering
  Future<List<Store>> searchLocations(String query) async {
    // Since the backend doesn't have a search endpoint, do client-side filtering
    try {
      // First try to get all nearby locations from a large radius
      final allStores = await getNearbyLocations(
        lat: 47.6965, // Austria center
        lng: 13.3457,
        maxDistanceKm: 500.0, // Cover most of Austria
      );
      
      if (query.isEmpty) {
        return allStores;
      }
      
      // Filter stores based on query
      final lowerQuery = query.toLowerCase();
      final filteredStores = allStores.where((store) {
        return store.name.toLowerCase().contains(lowerQuery) ||
               store.address.toLowerCase().contains(lowerQuery) ||
               store.city.toLowerCase().contains(lowerQuery) ||
               store.chain.name.toLowerCase().contains(lowerQuery);
      }).toList();
      
      return filteredStores;
    } catch (e) {
      return [];
    }
  }

  // Parse store data from API response
  List<Store> _parseStores(List<dynamic> locations) {
    return locations.map((loc) {
      // Handle various data formats
      Map<String, dynamic> locMap;
      
      if (loc is Map<String, dynamic>) {
        locMap = loc;
      } else if (loc is Map) {
        // Convert non-typed Map to Map<String, dynamic>
        try {
          locMap = Map<String, dynamic>.from(loc);
        } catch (e) {
          return null;
        }
      } else {
        return null;
      }
      
      try {
        final id = locMap['id']?.toString() ?? '';
        final name = locMap['name'] ?? 'Unknown Store';
        final chainRaw = locMap['chain'] ?? locMap['storeChain'];
        final chain = _parseStoreChain(chainRaw);
        final lat = _parseDouble(locMap['lat'] ?? locMap['latitude']) ?? 0.0;
        final lng = _parseDouble(locMap['lng'] ?? locMap['longitude']) ?? 0.0;
        final address = locMap['address']?.toString() ?? '';
        final city = locMap['city']?.toString() ?? '';
        final postalCode = (locMap['postalCode'] ?? locMap['postal_code'])?.toString() ?? '';
        final acceptedTypes = _parseAcceptedTypes(locMap['acceptedTypes'] ?? locMap['accepted_types']);
        final hasReturnMachine = locMap['hasReturnMachine'] ?? locMap['has_return_machine'] ?? true;
        final machineCount = _parseInt(locMap['machineCount'] ?? locMap['machine_count']) ?? 1;
        
        return Store(
          id: id,
          name: name,
          chain: chain,
          location: LatLng(lat, lng),
          address: address,
          city: city,
          postalCode: postalCode,
          acceptedTypes: acceptedTypes,
          hasReturnMachine: hasReturnMachine,
          machineCount: machineCount,
        );
      } catch (e) {
        return null;
      }
    }).where((store) => store != null).cast<Store>().toList();
  }
  
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  StoreChain _parseStoreChain(String? chain) {
    if (chain == null) return StoreChain.other;

    switch (chain.toLowerCase()) {
      case 'billa':
        return StoreChain.billa;
      case 'billaplus':
      case 'billa_plus':
        return StoreChain.billaPlus;
      case 'spar':
        return StoreChain.spar;
      case 'eurospar':
        return StoreChain.eurospar;
      case 'interspar':
        return StoreChain.interspar;
      case 'hofer':
        return StoreChain.hofer;
      case 'lidl':
        return StoreChain.lidl;
      case 'penny':
        return StoreChain.penny;
      case 'merkur':
        return StoreChain.merkur;
      case 'mpreis':
        return StoreChain.mpreis;
      default:
        return StoreChain.other;
    }
  }

  List<AcceptedDepositType> _parseAcceptedTypes(dynamic types) {
    if (types == null) return AcceptedDepositType.values;

    // Handle different input formats
    List<dynamic> typesList = [];
    
    if (types is List) {
      typesList = types;
    } else if (types is String) {
      // Handle comma-separated string
      typesList = types.split(',').map((s) => s.trim()).toList();
    } else if (types is Map) {
      // Handle map format safely - convert to list regardless of key type
      try {
        // Convert Map to List, handling any key type
        if (types is Map<String, dynamic>) {
          typesList = types.values.toList();
        } else {
          // For Maps with non-String keys, convert safely
          Map<String, dynamic> stringKeyMap = {};
          types.forEach((key, value) {
            stringKeyMap[key.toString()] = value;
          });
          typesList = stringKeyMap.values.toList();
        }
      } catch (e) {
        return AcceptedDepositType.values;
      }
    } else {
      // Fallback to all types
      return AcceptedDepositType.values;
    }

    // Parse the types list
    final parsedTypes = typesList.map((type) {
      final typeStr = type.toString().toLowerCase().trim();
      switch (typeStr) {
        case 'plastic':
        case 'plastic_025':
        case 'plastic_0.25':
        case 'plastic025':
          return AcceptedDepositType.plastic025;
        case 'plastic_05':
        case 'plastic_0.5':
        case 'plastic05':
          return AcceptedDepositType.plastic05;
        case 'plastic_1':
        case 'plastic_1.0':
        case 'plastic1':
          return AcceptedDepositType.plastic1;
        case 'plastic_15':
        case 'plastic_1.5':
        case 'plastic15':
          return AcceptedDepositType.plastic15;
        case 'can':
        case 'aluminum':
        case 'cans':
          return AcceptedDepositType.can;
        case 'glass':
        case 'bottle':
          return AcceptedDepositType.glass;
        case 'crate':
        case 'crates':
          return AcceptedDepositType.crate;
        default:
          return null;
      }
    }).where((type) => type != null).cast<AcceptedDepositType>().toList();

    // Return parsed types or all types if none were successfully parsed
    return parsedTypes.isNotEmpty ? parsedTypes : AcceptedDepositType.values;
  }

  // Get mock stores for fallback
  List<Store> _getMockStores() {
    return [
      // Vienna stores
      Store(
        id: '1',
        name: 'Billa Hauptbahnhof',
        chain: StoreChain.billa,
        location: LatLng(48.2082, 16.3738),
        address: 'Am Hauptbahnhof 1',
        city: 'Wien',
        postalCode: '1100',
        acceptedTypes: AcceptedDepositType.values,
        hasReturnMachine: true,
        machineCount: 2,
      ),
      Store(
        id: '2',
        name: 'SPAR Mariahilfer Straße',
        chain: StoreChain.spar,
        location: LatLng(48.2012, 16.3580),
        address: 'Mariahilfer Straße 85',
        city: 'Wien',
        postalCode: '1060',
        acceptedTypes: AcceptedDepositType.values,
        hasReturnMachine: true,
        machineCount: 3,
      ),
      // Graz stores
      Store(
        id: '3',
        name: 'Hofer Graz',
        chain: StoreChain.hofer,
        location: LatLng(47.0707, 15.4395),
        address: 'Hauptplatz 1',
        city: 'Graz',
        postalCode: '8010',
        acceptedTypes: AcceptedDepositType.values,
        hasReturnMachine: true,
      ),
      // Salzburg stores
      Store(
        id: '4',
        name: 'Lidl Salzburg',
        chain: StoreChain.lidl,
        location: LatLng(47.8095, 13.0550),
        address: 'Getreidegasse 9',
        city: 'Salzburg',
        postalCode: '5020',
        acceptedTypes: AcceptedDepositType.values,
        hasReturnMachine: true,
      ),
      // Innsbruck stores
      Store(
        id: '5',
        name: 'SPAR Innsbruck',
        chain: StoreChain.spar,
        location: LatLng(47.2692, 11.4041),
        address: 'Maria-Theresien-Straße 31',
        city: 'Innsbruck',
        postalCode: '6020',
        acceptedTypes: AcceptedDepositType.values,
        hasReturnMachine: true,
      ),
      // Linz stores
      Store(
        id: '6',
        name: 'Billa Plus Linz',
        chain: StoreChain.billaPlus,
        location: LatLng(48.3069, 14.2858),
        address: 'Landstraße 17',
        city: 'Linz',
        postalCode: '4020',
        acceptedTypes: AcceptedDepositType.values,
        hasReturnMachine: true,
        machineCount: 2,
      ),
    ];
  }
}

// Providers
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref);
});

// Austrian stores provider - centered on Austria
final austrianStoresProvider = FutureProvider<List<Store>>((ref) async {
  final service = ref.read(locationServiceProvider);

  // Austria center coordinates
  return service.getAustrianDepositLocations(
    lat: 47.6965,
    lng: 13.3457,
    maxDistanceKm: 500.0, // Cover whole Austria
  );
});

// Nearby stores provider - for user's current location
final nearbyStoresProvider =
    FutureProvider.family<List<Store>, LatLng>((ref, location) async {
  final service = ref.read(locationServiceProvider);

  return service.getNearbyLocations(
    lat: location.latitude,
    lng: location.longitude,
    maxDistanceKm: 20.0,
  );
});

// Search stores provider
final searchStoresProvider =
    FutureProvider.family<List<Store>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final service = ref.read(locationServiceProvider);
  return service.searchLocations(query);
});
