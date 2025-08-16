import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: LightColors.colorScheme,
    textTheme: AppTypography.lightTextTheme,
    scaffoldBackgroundColor: AppColors.backgroundLight,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTypography.lightTextTheme.titleLarge,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryLight,
        size: AppSpacing.iconSizeMd,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusMd,
        side: const BorderSide(
          color: AppColors.dividerLight,
          width: AppBorders.borderWidth,
        ),
      ),
      margin: const EdgeInsets.all(AppSpacing.sm),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadiusMd,
        ),
        textStyle: AppTypography.buttonText,
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadiusMd,
        ),
        textStyle: AppTypography.buttonText,
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(
          color: AppColors.primaryLight,
          width: AppBorders.borderWidth,
        ),
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadiusMd,
        ),
        textStyle: AppTypography.buttonText,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariantLight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMd,
        borderSide: const BorderSide(
          color: AppColors.dividerLight,
          width: AppBorders.borderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMd,
        borderSide: const BorderSide(
          color: AppColors.dividerLight,
          width: AppBorders.borderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMd,
        borderSide: const BorderSide(
          color: AppColors.primaryLight,
          width: AppBorders.borderWidthThick,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMd,
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppBorders.borderWidth,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMd,
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppBorders.borderWidthThick,
        ),
      ),
      labelStyle: AppTypography.lightTextTheme.bodyMedium,
      hintStyle: AppTypography.lightTextTheme.bodyMedium?.copyWith(
        color: AppColors.textTertiaryLight,
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariantLight,
      selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
      labelStyle: AppTypography.lightTextTheme.labelMedium!,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusRound,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerLight,
      thickness: AppBorders.borderWidth,
      space: AppSpacing.md,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textTertiaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Dialog Theme
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusXl,
      ),
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimaryLight,
      contentTextStyle: AppTypography.lightTextTheme.bodyMedium?.copyWith(
        color: AppColors.surfaceLight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusMd,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: DarkColors.colorScheme,
    textTheme: AppTypography.darkTextTheme,
    scaffoldBackgroundColor: AppColors.backgroundDark,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTypography.darkTextTheme.titleLarge,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryDark,
        size: AppSpacing.iconSizeMd,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusMd,
        side: const BorderSide(
          color: AppColors.dividerDark,
          width: AppBorders.borderWidth,
        ),
      ),
      margin: const EdgeInsets.all(AppSpacing.sm),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.backgroundDark,
        elevation: 0,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadiusMd,
        ),
        textStyle: AppTypography.buttonText,
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadiusMd,
        ),
        textStyle: AppTypography.buttonText,
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(
          color: AppColors.primaryDark,
          width: AppBorders.borderWidth,
        ),
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadiusMd,
        ),
        textStyle: AppTypography.buttonText,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariantDark,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMd,
        borderSide: const BorderSide(
          color: AppColors.dividerDark,
          width: AppBorders.borderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMd,
        borderSide: const BorderSide(
          color: AppColors.dividerDark,
          width: AppBorders.borderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMd,
        borderSide: const BorderSide(
          color: AppColors.primaryDark,
          width: AppBorders.borderWidthThick,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMd,
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppBorders.borderWidth,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppBorders.borderRadiusMd,
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppBorders.borderWidthThick,
        ),
      ),
      labelStyle: AppTypography.darkTextTheme.bodyMedium,
      hintStyle: AppTypography.darkTextTheme.bodyMedium?.copyWith(
        color: AppColors.textTertiaryDark,
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariantDark,
      selectedColor: AppColors.primaryDark.withValues(alpha: 0.3),
      labelStyle: AppTypography.darkTextTheme.labelMedium!,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusRound,
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerDark,
      thickness: AppBorders.borderWidth,
      space: AppSpacing.md,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.textTertiaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Dialog Theme
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusXl,
      ),
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimaryDark,
      contentTextStyle: AppTypography.darkTextTheme.bodyMedium?.copyWith(
        color: AppColors.backgroundDark,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusMd,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
