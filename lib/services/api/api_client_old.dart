import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // Auth endpoints
  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/registerWithEmail').replace(
      queryParameters: {
        'email': email,
        'password': password,
        'name': name,
      },
    );

    final response = await _client.post(uri);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/loginWithEmail').replace(
      queryParameters: {
        'email': email,
        'password': password,
      },
    );

    final response = await _client.post(uri);
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

  Future<Map<String, dynamic>> refreshAuthToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final uri = Uri.parse('$baseUrl/auth/refreshToken').replace(
      queryParameters: {
        'refreshToken': _refreshToken,
      },
    );

    final response = await _client.post(uri);
    final data = _handleResponse(response);

    // Update tokens
    if (data['token'] != null) {
      _authToken = data['token'];
    }
    if (data['refreshToken'] != null) {
      _refreshToken = data['refreshToken'];
    }

    return data;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    // Try with token as query parameter (as backend expects)
    if (_authToken != null) {
      final uri = Uri.parse('$baseUrl/auth/getCurrentUser').replace(
        queryParameters: {
          'token': _authToken!,
        },
      );
      
      final response = await _client.post(uri, headers: _headers);
      return _handleResponse(response);
    } else {
      // If no token, try without query parameter (might fail but gives proper error)
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/getCurrentUser'),
        headers: _headers,
      );
      return _handleResponse(response);
    }
  }

  Future<Map<String, dynamic>> linkDevice({
    required String deviceId,
    required String deviceToken,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/linkDevice').replace(
      queryParameters: {
        'deviceId': deviceId,
        'deviceToken': deviceToken,
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<void> logout() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _headers,
    );
    _handleResponse(response);
    clearTokens();
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/changePassword').replace(
      queryParameters: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  // Location endpoints
  Future<List<dynamic>> getNearbyLocations({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse('$baseUrl/location/nearby').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );

    final response = await _client.post(uri);
    return _handleResponse(response);
  }

  Future<List<dynamic>> searchAllAustria({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse('$baseUrl/location/searchAllAustria').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );

    final response = await _client.post(uri);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> reportLocationStatus({
    required int locationId,
    required String status,
    String? notes,
  }) async {
    final params = {
      'locationId': locationId.toString(),
      'status': status,
    };
    if (notes != null) {
      params['notes'] = notes;
    }

    final uri = Uri.parse('$baseUrl/location/reportStatus').replace(
      queryParameters: params,
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addLocation({
    required String name,
    required double lat,
    required double lng,
    required String type,
    required String address,
  }) async {
    final uri = Uri.parse('$baseUrl/location/addLocation').replace(
      queryParameters: {
        'name': name,
        'lat': lat.toString(),
        'lng': lng.toString(),
        'type': type,
        'address': address,
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<List<dynamic>> getFavorites() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/location/getFavorites'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addFavorite({required int locationId}) async {
    final uri = Uri.parse('$baseUrl/location/addFavorite').replace(
      queryParameters: {
        'locationId': locationId.toString(),
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<void> removeFavorite({required int favoriteId}) async {
    final uri = Uri.parse('$baseUrl/location/removeFavorite').replace(
      queryParameters: {
        'favoriteId': favoriteId.toString(),
      },
    );

    final response = await _client.post(uri, headers: _headers);
    _handleResponse(response);
  }

  Future<List<dynamic>> getAustrianDepositLocations({
    required double lat,
    required double lng,
  }) async {
    final uri =
        Uri.parse('$baseUrl/location/getAustrianDepositLocations').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );

    final response = await _client.post(uri);
    return _handleResponse(response);
  }

  // Scan endpoints
  Future<Map<String, dynamic>> recordScan({
    required String barcode,
    required int locationId,
  }) async {
    final uri = Uri.parse('$baseUrl/scan/recordScan').replace(
      queryParameters: {
        'barcode': barcode,
        'locationId': locationId.toString(),
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> startSession({required int locationId}) async {
    final uri = Uri.parse('$baseUrl/scan/startSession').replace(
      queryParameters: {
        'locationId': locationId.toString(),
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> endSession({required int sessionId}) async {
    final uri = Uri.parse('$baseUrl/scan/endSession').replace(
      queryParameters: {
        'sessionId': sessionId.toString(),
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<List<dynamic>> getUserScans({
    int limit = 10,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/scan/getUserScans').replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  // Catalog endpoints
  Future<Map<String, dynamic>> getProductByBarcode(
      {required String barcode}) async {
    final uri = Uri.parse('$baseUrl/catalog/getProductByBarcode').replace(
      queryParameters: {
        'barcode': barcode,
      },
    );

    final response = await _client.post(uri);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> suggestProduct({
    required String barcode,
    required String name,
    required String brand,
    required double depositAmount,
  }) async {
    final uri = Uri.parse('$baseUrl/catalog/suggestProduct').replace(
      queryParameters: {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'depositAmount': depositAmount.toString(),
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<List<dynamic>> searchProducts({required String query}) async {
    final uri = Uri.parse('$baseUrl/catalog/searchProducts').replace(
      queryParameters: {
        'query': query,
      },
    );

    final response = await _client.post(uri);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> lookupProductExternal(
      {required String barcode}) async {
    final uri = Uri.parse('$baseUrl/catalog/lookupProductExternal').replace(
      queryParameters: {
        'barcode': barcode,
      },
    );

    final response = await _client.post(uri);
    return _handleResponse(response);
  }

  // Stats endpoints
  Future<Map<String, dynamic>> getTotals({String period = 'week'}) async {
    final uri = Uri.parse('$baseUrl/stats/totals').replace(
      queryParameters: {
        'period': period,
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getBreakdown({
    String by = 'location',
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/stats/breakdown').replace(
      queryParameters: {
        'by': by,
        'limit': limit.toString(),
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<String> exportCSV({
    required String startDate,
    required String endDate,
  }) async {
    final uri = Uri.parse('$baseUrl/stats/exportCSV').replace(
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
      },
    );

    final response = await _client.post(uri, headers: _headers);
    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception('Failed to export CSV: ${response.statusCode}');
  }

  Future<List<dynamic>> getLeaderboard({
    String period = 'month',
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/stats/getLeaderboard').replace(
      queryParameters: {
        'period': period,
        'limit': limit.toString(),
      },
    );

    final response = await _client.post(uri);
    return _handleResponse(response);
  }

  // Social endpoints
  Future<List<dynamic>> getFriends() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/social/getFriends'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getUserBadges() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/social/getUserBadges'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> awardBadge({required int badgeId}) async {
    final uri = Uri.parse('$baseUrl/social/awardBadge').replace(
      queryParameters: {
        'badgeId': badgeId.toString(),
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<List<dynamic>> checkAndAwardBadges({required int userId}) async {
    final uri = Uri.parse('$baseUrl/social/checkAndAwardBadges').replace(
      queryParameters: {
        'userId': userId.toString(),
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<List<dynamic>> getAllBadges() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/social/getAllBadges'),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createBadge({
    required String name,
    required String description,
    required String icon,
    required String criteria,
  }) async {
    final uri = Uri.parse('$baseUrl/social/createBadge').replace(
      queryParameters: {
        'name': name,
        'description': description,
        'icon': icon,
        'criteria': criteria,
      },
    );

    final response = await _client.post(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<List<dynamic>> getSocialLeaderboard({
    String period = 'week',
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/social/getLeaderboard').replace(
      queryParameters: {
        'period': period,
        'limit': limit.toString(),
      },
    );

    final response = await _client.post(uri);
    return _handleResponse(response);
  }

  // Greeting endpoint (for testing)
  Future<String> hello({String name = 'World'}) async {
    final uri = Uri.parse('$baseUrl/greeting/hello').replace(
      queryParameters: {
        'name': name,
      },
    );

    final response = await _client.post(uri);
    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception('Failed to get greeting: ${response.statusCode}');
  }

  // Response handler
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
      // Token expired, try to refresh
      throw AuthException('Authentication failed', response.statusCode);
    } else {
      throw ApiException(
        'Request failed with status ${response.statusCode}: ${response.body}',
        response.statusCode,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class AuthException extends ApiException {
  AuthException(super.message, super.statusCode);
}
