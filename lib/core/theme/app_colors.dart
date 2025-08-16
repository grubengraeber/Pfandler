import 'package:flutter/material.dart';

class AppColors {
  // Primary color palette - Austrian deposit symbol red
  static const Color primaryLight = Color(0xFFEF3340); // Austrian red from logo
  static const Color primaryDark = Color(0xFFF87171);  // Lighter red for dark mode
  
  // Secondary color palette - Complementary green (for recycling theme)
  static const Color secondaryLight = Color(0xFF16A34A); // Green
  static const Color secondaryDark = Color(0xFF4ADE80);   // Lighter green for dark mode
  
  // Accent colors
  static const Color accentOrange = Color(0xFFF97316);  // Orange for CTAs
  static const Color accentPink = Color(0xFFEC4899);    // Pink for highlights
  
  // Success, Warning, Error colors
  static const Color success = Color(0xFF10B981);  // Green
  static const Color warning = Color(0xFFF59E0B);  // Amber
  static const Color error = Color(0xFFEF4444);    // Red
  static const Color info = Color(0xFF3B82F6);     // Blue
  
  // Neutral colors for light theme
  static const Color backgroundLight = Color(0xFFFAFAFA);      // Off-white
  static const Color surfaceLight = Color(0xFFFFFFFF);         // Pure white
  static const Color surfaceVariantLight = Color(0xFFF3F4F6);  // Light gray
  static const Color textPrimaryLight = Color(0xFF111827);     // Almost black
  static const Color textSecondaryLight = Color(0xFF6B7280);   // Medium gray
  static const Color textTertiaryLight = Color(0xFF9CA3AF);    // Light gray
  static const Color dividerLight = Color(0xFFE5E7EB);         // Border gray
  
  // Neutral colors for dark theme
  static const Color backgroundDark = Color(0xFF0F0F14);       // Deep dark blue
  static const Color surfaceDark = Color(0xFF1A1A23);          // Dark surface
  static const Color surfaceVariantDark = Color(0xFF25252F);   // Elevated dark surface
  static const Color textPrimaryDark = Color(0xFFF9FAFB);      // Almost white
  static const Color textSecondaryDark = Color(0xFFD1D5DB);    // Light gray
  static const Color textTertiaryDark = Color(0xFF9CA3AF);     // Medium gray
  static const Color dividerDark = Color(0xFF374151);          // Border dark gray
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFEF3340), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Light Theme Colors
class LightColors {
  static const ColorScheme colorScheme = ColorScheme.light(
    primary: AppColors.primaryLight,
    secondary: AppColors.secondaryLight,
    surface: AppColors.surfaceLight,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textPrimaryLight,
    onError: Colors.white,
    brightness: Brightness.light,
  );
}

// Dark Theme Colors
class DarkColors {
  static const ColorScheme colorScheme = ColorScheme.dark(
    primary: AppColors.primaryDark,
    secondary: AppColors.secondaryDark,
    surface: AppColors.surfaceDark,
    error: AppColors.error,
    onPrimary: AppColors.backgroundDark,
    onSecondary: AppColors.backgroundDark,
    onSurface: AppColors.textPrimaryDark,
    onError: Colors.white,
    brightness: Brightness.dark,
  );
}