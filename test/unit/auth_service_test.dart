import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pfandler/services/auth_service.dart';
import 'dart:io';

void main() {
  late ProviderContainer container;
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Create temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    
    // Initialize Hive with temp directory
    Hive.init(tempDir.path);
    
    // Mock the path provider channel for other uses
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return tempDir.path;
    });
    
    // Mock connectivity plus
    const MethodChannel connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return 'wifi';
      }
      return null;
    });
  });

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });
  
  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('AuthService Tests', () {
    test('Initial auth state should be not authenticated', () async {
      // Wait a bit for async initialization
      await Future.delayed(const Duration(milliseconds: 100));
      
      final authState = container.read(authProvider);
      
      expect(authState.isAuthenticated, false);
      expect(authState.authToken, isNull);
      expect(authState.user, isNull);
      expect(authState.isLoading, false);
      expect(authState.error, isNull);
    });

    test('Auth state can be updated', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final authNotifier = container.read(authProvider.notifier);
      
      // Initial state
      expect(container.read(authProvider).isAuthenticated, false);
      
      // Update state
      authNotifier.state = AuthState(
        isAuthenticated: true,
        authToken: 'test_token',
        user: User(
          id: 1,
          email: 'test@example.com',
          createdAt: DateTime.now(),
        ),
      );
      
      // Verify updated state
      final updatedState = container.read(authProvider);
      expect(updatedState.isAuthenticated, true);
      expect(updatedState.authToken, 'test_token');
      expect(updatedState.user?.email, 'test@example.com');
    });

    test('User model serialization works correctly', () {
      final now = DateTime.now();
      final user = User(
        id: 123,
        email: 'user@test.com',
        displayName: 'Test User',
        avatarUrl: 'https://example.com/avatar.jpg',
        createdAt: now,
        metadata: {'key': 'value'},
      );

      // Convert to JSON
      final json = user.toJson();
      
      expect(json['id'], 123);
      expect(json['email'], 'user@test.com');
      expect(json['displayName'], 'Test User');
      expect(json['avatarUrl'], 'https://example.com/avatar.jpg');
      expect(json['createdAt'], now.toIso8601String());
      expect(json['metadata'], {'key': 'value'});

      // Convert back from JSON
      final userFromJson = User.fromJson(json);
      
      expect(userFromJson.id, user.id);
      expect(userFromJson.email, user.email);
      expect(userFromJson.displayName, user.displayName);
      expect(userFromJson.avatarUrl, user.avatarUrl);
      expect(userFromJson.createdAt.toIso8601String(), user.createdAt.toIso8601String());
    });

    test('Auth state copyWith works correctly', () {
      final initialState = AuthState(
        isAuthenticated: false,
        authToken: 'initial_token',
        isLoading: false,
      );

      final updatedState = initialState.copyWith(
        isAuthenticated: true,
        isLoading: true,
      );

      expect(updatedState.isAuthenticated, true);
      expect(updatedState.authToken, 'initial_token'); // Should keep original value
      expect(updatedState.isLoading, true);
    });

    test('Auth providers return correct values', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final authNotifier = container.read(authProvider.notifier);
      
      // Set authenticated state
      authNotifier.state = AuthState(
        isAuthenticated: true,
        authToken: 'bearer_token',
        user: User(
          id: 456,
          email: 'provider@test.com',
          createdAt: DateTime.now(),
        ),
      );

      // Test isAuthenticatedProvider
      expect(container.read(isAuthenticatedProvider), true);
      
      // Test authTokenProvider
      expect(container.read(authTokenProvider), 'bearer_token');
      
      // Test currentUserProvider
      final currentUser = container.read(currentUserProvider);
      expect(currentUser?.email, 'provider@test.com');
      expect(currentUser?.id, 456);
    });

    test('Logout clears auth state', () async {
      // Give more time for initialization
      await Future.delayed(const Duration(milliseconds: 500));
      
      final authNotifier = container.read(authProvider.notifier);
      
      // Set authenticated state
      authNotifier.state = AuthState(
        isAuthenticated: true,
        authToken: 'token_to_clear',
        user: User(
          id: 789,
          email: 'logout@test.com',
          createdAt: DateTime.now(),
        ),
      );

      // Verify authenticated
      expect(container.read(authProvider).isAuthenticated, true);

      // Wait for initialization to complete before logout
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Logout
      await authNotifier.logout();

      // Verify cleared
      final clearedState = container.read(authProvider);
      expect(clearedState.isAuthenticated, false);
      expect(clearedState.authToken, isNull);
      expect(clearedState.user, isNull);
    });
  });
}