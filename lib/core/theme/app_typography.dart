import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  // Font families
  static const String primaryFont = 'Inter';
  static const String secondaryFont = 'SF Pro Display';

  // Base text theme for light mode
  static TextTheme lightTextTheme = const TextTheme(
    // Display styles
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.12,
      color: AppColors.textPrimaryLight,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.16,
      color: AppColors.textPrimaryLight,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.22,
      color: AppColors.textPrimaryLight,
    ),

    // Headline styles
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.25,
      color: AppColors.textPrimaryLight,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.29,
      color: AppColors.textPrimaryLight,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.33,
      color: AppColors.textPrimaryLight,
    ),

    // Title styles
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.27,
      color: AppColors.textPrimaryLight,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.5,
      color: AppColors.textPrimaryLight,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
      color: AppColors.textPrimaryLight,
    ),

    // Body styles
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
      color: AppColors.textPrimaryLight,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
      color: AppColors.textPrimaryLight,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
      color: AppColors.textSecondaryLight,
    ),

    // Label styles
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
      color: AppColors.textPrimaryLight,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
      color: AppColors.textPrimaryLight,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
      color: AppColors.textSecondaryLight,
    ),
  );

  // Base text theme for dark mode
  static TextTheme darkTextTheme = TextTheme(
    // Display styles
    displayLarge:
        lightTextTheme.displayLarge!.copyWith(color: AppColors.textPrimaryDark),
    displayMedium: lightTextTheme.displayMedium!
        .copyWith(color: AppColors.textPrimaryDark),
    displaySmall:
        lightTextTheme.displaySmall!.copyWith(color: AppColors.textPrimaryDark),

    // Headline styles
    headlineLarge: lightTextTheme.headlineLarge!
        .copyWith(color: AppColors.textPrimaryDark),
    headlineMedium: lightTextTheme.headlineMedium!
        .copyWith(color: AppColors.textPrimaryDark),
    headlineSmall: lightTextTheme.headlineSmall!
        .copyWith(color: AppColors.textPrimaryDark),

    // Title styles
    titleLarge:
        lightTextTheme.titleLarge!.copyWith(color: AppColors.textPrimaryDark),
    titleMedium:
        lightTextTheme.titleMedium!.copyWith(color: AppColors.textPrimaryDark),
    titleSmall:
        lightTextTheme.titleSmall!.copyWith(color: AppColors.textPrimaryDark),

    // Body styles
    bodyLarge:
        lightTextTheme.bodyLarge!.copyWith(color: AppColors.textPrimaryDark),
    bodyMedium:
        lightTextTheme.bodyMedium!.copyWith(color: AppColors.textPrimaryDark),
    bodySmall:
        lightTextTheme.bodySmall!.copyWith(color: AppColors.textSecondaryDark),

    // Label styles
    labelLarge:
        lightTextTheme.labelLarge!.copyWith(color: AppColors.textPrimaryDark),
    labelMedium:
        lightTextTheme.labelMedium!.copyWith(color: AppColors.textPrimaryDark),
    labelSmall:
        lightTextTheme.labelSmall!.copyWith(color: AppColors.textSecondaryDark),
  );

  // Custom text styles
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.43,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.4,
  );
}
