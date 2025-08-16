import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'l10n/app_localizations.dart';
import 'models/bottle.dart';
import 'features/launch/launch_screen.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BottleAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(BottleTypeAdapter());
  }
  
  runApp(
    const ProviderScope(
      child: PfandlerApp(),
    ),
  );
}

class PfandlerApp extends ConsumerWidget {
  const PfandlerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeServiceProvider);
    
    return MaterialApp(
      title: 'Pfandler',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authProvider);
          
          // Show launch screen while checking auth or if not authenticated
          if (authState.isLoading || !authState.isAuthenticated) {
            return const LaunchScreen();
          }
          
          // User is authenticated, but we need to handle this in LaunchScreen
          return const LaunchScreen();
        },
      ),
    );
  }
}