import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Client - Matching Postman Collection Format
/// All endpoints use JSON body for requests as per the backend specification
class ApiClient {
  final String baseUrl = 'https://api.pfandler.fabiotietz.com';
  final http.Client _client;
  String? _authToken;
  String? _refreshToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String token) {
    _authToken = token;
  }

  void setRefreshToken(String token) {
    _refreshToken = token;
  }

  void clearTokens() {
    _authToken = null;
    _refreshToken = null;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ============================================================================
  // AUTH ENDPOINTS
  // ============================================================================

  /// Register a new user with email and password
  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/registerWithEmail'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  /// Login with email and password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/loginWithEmail'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    final data = _handleResponse(response);
    
    // Store tokens if login successful
    if (data['token'] != null) {
      _authToken = data['token'];
    }
    if (data['refreshToken'] != null) {
      _refreshToken = data['refreshToken'];
    }
    
    return data;
  }

  /// Get current authenticated user information
  Future<Map<String, dynamic>> getCurrentUser() async {
    // Backend expects token as query parameter for this endpoint
    if (_authToken != null) {
      final uri = Uri.parse('$baseUrl/auth/getCurrentUser').replace(
        queryParameters: {
          'token': _authToken!,
        },
      );
      
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode({}),
      );
      return _handleResponse(response);
    } else {
      // If no token, send without query parameter (will fail with proper error)
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/getCurrentUser'),
        headers: _headers,
        body: jsonEncode({}),
      );
      return _handleResponse(response);
    }
  }

  /// Link a device to the user account
  Future<Map<String, dynamic>> linkDevice({
    required String deviceId,
    required String deviceName,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/linkDevice'),
      headers: _headers,
      body: jsonEncode({
        'deviceId': deviceId,
        'deviceName': deviceName,
      }),
    );
    return _handleResponse(response);
  }

  // ============================================================================
  // CATALOG ENDPOINTS
  // ============================================================================

  /// Get product information by barcode
  Future<Map<String, dynamic>> getProductByBarcode({
    required String barcode,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/catalog/getProductByBarcode'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'barcode': barcode,
      }),
    );
    return _handleResponse(response);
  }

  /// Suggest a new product to be added to the catalog
  Future<Map<String, dynamic>> suggestProduct({
    required String barcode,
    required String name,
    required String brand,
    required int volumeML,
    required String containerType,
    required int defaultDepositCents,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/catalog/suggestProduct'),
      headers: _headers,
      body: jsonEncode({
        'data': {
          'barcode': barcode,
          'name': name,
          'brand': brand,
          'volumeML': volumeML,
          'containerType': containerType,
          'defaultDepositCents': defaultDepositCents,
        },
      }),
    );
    return _handleResponse(response);
  }

  /// Search products by query
  Future<List<dynamic>> searchProducts({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/catalog/searchProducts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'limit': limit,
        'offset': offset,
      }),
    );
    return _handleResponse(response);
  }

  /// Verify a product (admin/moderator function)
  Future<Map<String, dynamic>> verifyProduct({
    required int productId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/catalog/verifyProduct'),
      headers: _headers,
      body: jsonEncode({
        'productId': productId,
      }),
    );
    return _handleResponse(response);
  }

  /// Lookup product from external APIs (OpenFoodFacts, OpenGTIN)
  Future<Map<String, dynamic>> lookupProductExternal({
    required String barcode,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/catalog/lookupProductExternal'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'barcode': barcode,
      }),
    );
    return _handleResponse(response);
  }

  /// Enrich existing product data with external sources
  Future<Map<String, dynamic>> enrichProductData({
    required int productId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/catalog/enrichProductData'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'productId': productId,
      }),
    );
    return _handleResponse(response);
  }

  // ============================================================================
  // SCAN ENDPOINTS
  // ============================================================================

  /// Start a new scan session at a location
  Future<Map<String, dynamic>> startSession({
    required int locationId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/scan/startSession'),
      headers: _headers,
      body: jsonEncode({
        'locationId': locationId,
      }),
    );
    return _handleResponse(response);
  }

  /// Record a single bottle scan
  Future<Map<String, dynamic>> recordScan({
    required int sessionId,
    required String barcode,
    required int volumeML,
    required String containerType,
    required int depositCents,
    String source = 'scan',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/scan/recordScan'),
      headers: _headers,
      body: jsonEncode({
        'scanInput': {
          'sessionId': sessionId,
          'barcode': barcode,
          'volumeML': volumeML,
          'containerType': containerType,
          'depositCents': depositCents,
          'source': source,
        },
      }),
    );
    return _handleResponse(response);
  }

  /// End a scan session
  Future<Map<String, dynamic>> endSession({
    required int sessionId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/scan/endSession'),
      headers: _headers,
      body: jsonEncode({
        'sessionId': sessionId,
      }),
    );
    return _handleResponse(response);
  }

  /// Bulk upload multiple scans at once
  Future<Map<String, dynamic>> bulkUpload({
    required List<Map<String, dynamic>> scans,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/scan/bulkUpload'),
      headers: _headers,
      body: jsonEncode({
        'scans': scans,
      }),
    );
    return _handleResponse(response);
  }

  /// Get user's scan history
  Future<List<dynamic>> getUserScans({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/scan/getUserScans'),
      headers: _headers,
      body: jsonEncode({
        'limit': limit,
        'offset': offset,
      }),
    );
    return _handleResponse(response);
  }

  // ============================================================================
  // LOCATION ENDPOINTS
  // ============================================================================

  /// Find nearby locations (local or Austria-wide)
  /// If maxDistance is null or > 100km, searches all of Austria
  Future<List<dynamic>> findNearbyLocations({
    required double lat,
    required double lng,
    String? type,
    double? maxDistance,
  }) async {
    final filters = <String, dynamic>{};
    if (type != null) {
      filters['type'] = type;
    }
    if (maxDistance != null) {
      filters['maxDistance'] = maxDistance;
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/location/nearby'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'lat': lat,
        'lng': lng,
        'filters': filters,
      }),
    );
    return _handleResponse(response);
  }

  /// Report location status (e.g., machine full, out of order)
  Future<Map<String, dynamic>> reportLocationStatus({
    required int locationId,
    required String status,
    String? note,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/location/reportStatus'),
      headers: _headers,
      body: jsonEncode({
        'locationId': locationId,
        'status': status,
        if (note != null) 'note': note,
      }),
    );
    return _handleResponse(response);
  }

  /// Add a new location
  Future<Map<String, dynamic>> addLocation({
    required String name,
    required String type,
    required double lat,
    required double lng,
    required String address,
    String? googleMapsUrl,
    String? acceptsJson,
    String? openingHoursJson,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/location/addLocation'),
      headers: _headers,
      body: jsonEncode({
        'suggestedLocation': {
          'name': name,
          'type': type,
          'lat': lat,
          'lng': lng,
          'address': address,
          if (googleMapsUrl != null) 'googleMapsUrl': googleMapsUrl,
          if (acceptsJson != null) 'acceptsJson': acceptsJson,
          if (openingHoursJson != null) 'openingHoursJson': openingHoursJson,
        },
      }),
    );
    return _handleResponse(response);
  }

  /// Get user's favorite locations
  Future<List<dynamic>> getFavoriteLocations() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/location/getFavorites'),
      headers: _headers,
      body: jsonEncode({}),
    );
    return _handleResponse(response);
  }

  /// Add a location to favorites
  Future<Map<String, dynamic>> addFavoriteLocation({
    required int locationId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/location/addFavorite'),
      headers: _headers,
      body: jsonEncode({
        'locationId': locationId,
      }),
    );
    return _handleResponse(response);
  }

  /// Remove a location from favorites
  Future<void> removeFavoriteLocation({
    required int locationId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/location/removeFavorite'),
      headers: _headers,
      body: jsonEncode({
        'locationId': locationId,
      }),
    );
    _handleResponse(response);
  }

  /// Get Austrian deposit locations
  Future<List<dynamic>> getAustrianDepositLocations({
    required double lat,
    required double lng,
    required double maxDistanceKm,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/location/getAustrianDepositLocations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'lat': lat,
        'lng': lng,
        'maxDistanceKm': maxDistanceKm,
      }),
    );
    return _handleResponse(response);
  }

  /// Import Austrian stores from OpenStreetMap
  Future<Map<String, dynamic>> importAustrianStores({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/location/importAustrianStores'),
      headers: _headers,
      body: jsonEncode({
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
      }),
    );
    return _handleResponse(response);
  }

  // ============================================================================
  // STATS ENDPOINTS
  // ============================================================================

  /// Get total statistics for a date range
  Future<Map<String, dynamic>> getTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/stats/totals'),
      headers: _headers,
      body: jsonEncode({
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
      }),
    );
    return _handleResponse(response);
  }

  /// Get breakdown statistics by category
  Future<Map<String, dynamic>> getBreakdown({
    required String breakdownBy, // containerType, month, location, brand
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/stats/breakdown'),
      headers: _headers,
      body: jsonEncode({
        'breakdownBy': breakdownBy,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
      }),
    );
    return _handleResponse(response);
  }

  /// Export statistics as CSV
  Future<String> exportCSV({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/stats/exportCSV'),
      headers: _headers,
      body: jsonEncode({
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
      }),
    );
    
    if (response.statusCode == 200) {
      return response.body;
    }
    throw ApiException('Failed to export CSV', response.statusCode);
  }

  /// Get leaderboard
  Future<List<dynamic>> getLeaderboard({
    String period = 'month', // week, month, year, all
    int limit = 10,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/stats/getLeaderboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'period': period,
        'limit': limit,
      }),
    );
    return _handleResponse(response);
  }

  // ============================================================================
  // SOCIAL ENDPOINTS
  // ============================================================================

  /// Get user's friends list
  Future<List<dynamic>> getFriends() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/social/getFriends'),
      headers: _headers,
      body: jsonEncode({}),
    );
    return _handleResponse(response);
  }

  /// Get user's badges
  Future<List<dynamic>> getUserBadges() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/social/getUserBadges'),
      headers: _headers,
      body: jsonEncode({}),
    );
    return _handleResponse(response);
  }

  /// Award a badge to a user
  Future<Map<String, dynamic>> awardBadge({
    required int userId,
    required int badgeId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/social/awardBadge'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'badgeId': badgeId,
      }),
    );
    return _handleResponse(response);
  }

  /// Check and award badges based on user achievements
  Future<List<dynamic>> checkAndAwardBadges({
    required int userId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/social/checkAndAwardBadges'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
      }),
    );
    return _handleResponse(response);
  }

  /// Get all available badges
  Future<List<dynamic>> getAllBadges() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/social/getAllBadges'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    return _handleResponse(response);
  }

  /// Create a new badge (admin function)
  Future<Map<String, dynamic>> createBadge({
    required String name,
    required String description,
    required String iconUrl,
    required String criteria,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/social/createBadge'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'description': description,
        'iconUrl': iconUrl,
        'criteria': criteria,
      }),
    );
    return _handleResponse(response);
  }

  /// Get social leaderboard
  Future<List<dynamic>> getSocialLeaderboard({
    String period = 'month', // week, month, year, all
    int limit = 10,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/social/getLeaderboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'period': period,
        'limit': limit,
      }),
    );
    return _handleResponse(response);
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Handle HTTP response and parse JSON
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        // If JSON decode fails, return the raw body
        return response.body;
      }
    } else if (response.statusCode == 401) {
      // Token expired or invalid
      throw AuthException('Authentication failed', response.statusCode);
    } else {
      throw ApiException(
        'Request failed with status ${response.statusCode}: ${response.body}',
        response.statusCode,
      );
    }
  }

  /// Dispose of the HTTP client
  void dispose() {
    _client.close();
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Authentication Exception
class AuthException extends ApiException {
  AuthException(String message, int statusCode) : super(message, statusCode);
}