import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }
  
  static const String _themeBoxName = 'settings';
  static const String _themeModeKey = 'theme_mode';
  
  // Load theme mode from local storage
  Future<void> _loadThemeMode() async {
    try {
      final box = await Hive.openBox(_themeBoxName);
      final savedThemeMode = box.get(_themeModeKey, defaultValue: 'system');
      
      switch (savedThemeMode) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        default:
          state = ThemeMode.system;
      }
    } catch (e) {
      // If there's an error loading, default to system
      state = ThemeMode.system;
    }
  }
  
  // Save theme mode to local storage
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final box = await Hive.openBox(_themeBoxName);
      String modeString;
      
      switch (mode) {
        case ThemeMode.light:
          modeString = 'light';
          break;
        case ThemeMode.dark:
          modeString = 'dark';
          break;
        default:
          modeString = 'system';
      }
      
      await box.put(_themeModeKey, modeString);
    } catch (e) {
      // Handle save error silently
    }
  }
  
  // Toggle between light and dark mode
  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      // If system, determine current brightness and toggle
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      setThemeMode(brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
    }
  }
  
  // Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _saveThemeMode(mode);
  }
  
  // Check if current theme is dark
  bool get isDarkMode {
    if (state == ThemeMode.dark) return true;
    if (state == ThemeMode.light) return false;
    
    // For system mode, check platform brightness
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }
}