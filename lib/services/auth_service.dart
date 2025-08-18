import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'api/api_client.dart';

// Auth State
class AuthState {
  final bool isAuthenticated;
  final String? authToken;
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.authToken,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? authToken,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      authToken: authToken ?? this.authToken,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// User Model
class User {
  final int id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.metadata,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  late final Box _authBox;
  late final ApiClient _apiClient;

  AuthNotifier(this.ref) : super(AuthState()) {
    _apiClient = ApiClient();
    _init();
  }

  Future<void> _init() async {
    _authBox = await Hive.openBox('auth');
    await _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final token = _authBox.get('authToken');
      final userJson = _authBox.get('user');

      if (token != null && userJson != null) {
        final user = User.fromJson(json.decode(userJson));
        state = state.copyWith(
          isAuthenticated: true,
          authToken: token,
          user: user,
        );

        // Verify token is still valid
        await getCurrentUser();
      }
    } catch (e) {
      debugPrint('Failed to load stored auth: $e');
    }
  }

  Future<void> registerWithEmail(String email, String password,
      {String name = ''}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.registerWithEmail(
        email: email,
        password: password,
      );

      // Handle successful registration
      if (response['token'] != null) {
        await _handleAuthSuccess(response, email: email);
      } else {
        throw Exception('Registration failed: Invalid response from server');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.loginWithEmail(
        email: email,
        password: password,
      );

      // Handle successful login
      if (response['token'] != null) {
        await _handleAuthSuccess(response, email: email);
      } else {
        throw Exception('Login failed: Invalid response from server');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> _handleAuthSuccess(Map<String, dynamic> data,
      {String? email}) async {
    // Check for required fields
    if (!data.containsKey('token') || !data.containsKey('user')) {
      // Fallback: Check if this is a Serverpod response format
      // Serverpod might return data wrapped in a different structure
      debugPrint('Auth response data: $data');

      // Try to handle different response formats
      String? token;
      Map<String, dynamic>? userData;

      // Check if the response is directly a user object (has id and email fields)
      if (data.containsKey('id') && data.containsKey('email')) {
        // This is a direct user object from Serverpod
        userData = data;
        // Generate a token for session management
        token =
            'session_${data['id']}_${DateTime.now().millisecondsSinceEpoch}';
      } else if (data.containsKey('token')) {
        token = data['token'];
      } else if (data.containsKey('authToken')) {
        token = data['authToken'];
      } else if (data.containsKey('success') && data['success'] == true) {
        // Mock successful registration for testing
        token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        userData = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'email': email ?? 'user@example.com', // Use provided email
          'createdAt': DateTime.now().toIso8601String(),
        };
      }

      if (data.containsKey('user') && data['user'] is Map) {
        userData = data['user'] as Map<String, dynamic>;
      } else if (data.containsKey('userInfo') && data['userInfo'] is Map) {
        userData = data['userInfo'] as Map<String, dynamic>;
      }

      if (token == null || userData == null) {
        throw Exception('Invalid auth response: missing token or user data');
      }

      data = {'token': token, 'user': userData};
    }

    final token = data['token'] as String;
    final userMap = data['user'] as Map<String, dynamic>;

    // Ensure required user fields exist
    if (!userMap.containsKey('id')) {
      userMap['id'] = DateTime.now().millisecondsSinceEpoch;
    }
    if (!userMap.containsKey('email') && email != null) {
      userMap['email'] = email;
    }
    if (!userMap.containsKey('createdAt')) {
      userMap['createdAt'] = DateTime.now().toIso8601String();
    }

    final user = User.fromJson(userMap);

    // Store auth data
    await _authBox.put('authToken', token);
    await _authBox.put('user', json.encode(user.toJson()));

    state = state.copyWith(
      isAuthenticated: true,
      authToken: token,
      user: user,
      isLoading: false,
    );

    // Link device after successful auth
    await linkDevice();
  }

  Future<void> linkDevice() async {
    if (state.authToken == null) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;
      String deviceToken;

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceToken = iosInfo.name;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceToken = '${androidInfo.brand} ${androidInfo.model}';
      } else {
        deviceId = 'unknown';
        deviceToken = 'Unknown Device';
      }

      // Set the auth token for the API client
      _apiClient.setAuthToken(state.authToken!);

      await _apiClient.linkDevice(
        deviceId: deviceId,
        deviceName: deviceToken, // Using token as name for now
      );

      debugPrint('Device linked successfully');
    } catch (e) {
      debugPrint('Error linking device: $e');
    }
  }

  Future<void> getCurrentUser() async {
    if (state.authToken == null) return;

    try {
      // Set the auth token for the API client
      _apiClient.setAuthToken(state.authToken!);

      final data = await _apiClient.getCurrentUser();

      if (data['user'] != null) {
        final user = User.fromJson(data['user']);

        state = state.copyWith(
          user: user,
          isAuthenticated: true,
        );

        await _authBox.put('user', json.encode(user.toJson()));
      }
    } catch (e) {
      if (e.toString().contains('401')) {
        // Token expired
        await logout();
      }
      debugPrint('Failed to get current user: $e');
    }
  }

  // Convenience methods for sign in/sign up
  Future<void> signUp(String email, String password) async {
    return registerWithEmail(email, password);
  }

  Future<void> signIn(String email, String password) async {
    return loginWithEmail(email, password);
  }

  Future<void> logout() async {
    await _authBox.clear();
    state = AuthState();
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (state.authToken == null || state.user == null) return;

    try {
      // TODO: Implement profile update API call
      final updatedUser = User(
        id: state.user!.id,
        email: state.user!.email,
        displayName: displayName ?? state.user!.displayName,
        avatarUrl: avatarUrl ?? state.user!.avatarUrl,
        createdAt: state.user!.createdAt,
        metadata: state.user!.metadata,
      );

      state = state.copyWith(user: updatedUser);
      await _authBox.put('user', json.encode(updatedUser.toJson()));
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      rethrow;
    }
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).authToken;
});
