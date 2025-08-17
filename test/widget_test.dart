import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pfandler/main.dart';
import 'package:pfandler/features/launch/launch_screen.dart';
import 'package:pfandler/core/theme/app_colors.dart';
import 'dart:io';

void main() {
  late Directory tempDir;
  
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Create temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    
    // Initialize Hive with temp directory
    Hive.init(tempDir.path);
    
    // Mock the path provider channel
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
  
  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PfandlerApp Widget Tests', () {
    testWidgets('App builds without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        const ProviderScope(
          child: PfandlerApp(),
        ),
      );
      
      // Wait for Consumer to build
      await tester.pump();
      
      // Verify app has MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Pump and settle all animations/timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('App has correct theme configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: PfandlerApp(),
        ),
      );

      // Get the MaterialApp widget
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      
      // Verify theme is set
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
      expect(app.title, 'Pfandler');
      
      // Verify primary color is Austrian red
      expect(app.theme?.primaryColor, AppColors.primaryLight);
      
      // Pump and settle all animations/timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('App supports localization', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: PfandlerApp(),
        ),
      );

      // Get the MaterialApp widget
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      
      // Verify localization delegates are set
      expect(app.localizationsDelegates, isNotNull);
      expect(app.supportedLocales, isNotNull);
      expect(app.supportedLocales.length, 2); // English and German
      
      // Pump and settle all animations/timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('App has theme mode support', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: PfandlerApp(),
        ),
      );

      // Get the MaterialApp widget
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      
      // Verify both light and dark themes are configured
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
      expect(app.themeMode, isNotNull);
      
      // Pump and settle all animations/timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });
}