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
    testWidgets('App starts with launch screen', (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Build our app and trigger a frame
        await tester.pumpWidget(
          const ProviderScope(
            child: PfandlerApp(),
          ),
        );

        // Wait for the widget to settle
        await tester.pump();

        // Verify that launch screen is shown
        expect(find.byType(LaunchScreen), findsOneWidget);
        
        // Verify app title is present
        expect(find.text('Pfandler'), findsOneWidget);
      });
    });

    testWidgets('App has correct theme colors', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const ProviderScope(
            child: PfandlerApp(),
          ),
        );

        await tester.pump();

        // Get the MaterialApp widget
        final MaterialApp app = tester.widget(find.byType(MaterialApp));
        
        // Verify theme is set
        expect(app.theme, isNotNull);
        expect(app.darkTheme, isNotNull);
        
        // Verify primary color is Austrian red
        expect(app.theme?.primaryColor, AppColors.primaryLight);
      });
    });

    testWidgets('App shows logo on launch screen', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const ProviderScope(
            child: PfandlerApp(),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Check for the presence of a circular container (logo container)
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
          findsWidgets,
        );
      });
    });

    testWidgets('Dark mode support exists', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const ProviderScope(
            child: PfandlerApp(),
          ),
        );

        await tester.pump();

        // Get initial theme mode
        final MaterialApp app = tester.widget(find.byType(MaterialApp));
        
        // Verify both light and dark themes are configured
        expect(app.theme, isNotNull);
        expect(app.darkTheme, isNotNull);
        expect(app.themeMode, isNotNull);
      });
    });
  });
}