import 'package:flutter/material.dart';

class AppSpacing {
  // Base spacing unit (8pt grid system)
  static const double unit = 8.0;
  
  // Spacing values following 8pt grid
  static const double xxs = 2.0;   // 0.25 * unit
  static const double xs = 4.0;    // 0.5 * unit
  static const double sm = 8.0;    // 1 * unit
  static const double md = 16.0;   // 2 * unit
  static const double lg = 24.0;   // 3 * unit
  static const double xl = 32.0;   // 4 * unit
  static const double xxl = 40.0;  // 5 * unit
  static const double xxxl = 48.0; // 6 * unit
  static const double huge = 56.0; // 7 * unit
  static const double giant = 64.0; // 8 * unit
  
  // Page padding
  static const EdgeInsets pagePadding = EdgeInsets.all(md);
  static const EdgeInsets pagePaddingHorizontal = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pagePaddingVertical = EdgeInsets.symmetric(vertical: md);
  
  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(sm);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(lg);
  
  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  
  // Button padding
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );
  
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
  
  // Icon sizes
  static const double iconSizeXs = 16.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 40.0;
  static const double iconSizeXxl = 48.0;
}

class AppBorders {
  // Border radius values
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 20.0;
  static const double radiusRound = 999.0;
  
  // BorderRadius instances
  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusXxl = BorderRadius.all(Radius.circular(radiusXxl));
  static const BorderRadius borderRadiusRound = BorderRadius.all(Radius.circular(radiusRound));
  
  // Border width
  static const double borderWidthThin = 0.5;
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 2.0;
  
  // Predefined borders
  static Border thinBorder(Color color) => Border.all(
    color: color,
    width: borderWidthThin,
  );
  
  static Border normalBorder(Color color) => Border.all(
    color: color,
    width: borderWidth,
  );
  
  static Border thickBorder(Color color) => Border.all(
    color: color,
    width: borderWidthThick,
  );
  
  // Box decorations
  static BoxDecoration cardDecoration({
    Color? color,
    Color? borderColor,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadiusMd,
      border: borderColor != null ? normalBorder(borderColor) : null,
      boxShadow: boxShadow,
    );
  }
}

class AppShadows {
  // Elevation shadows
  static const List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
  
  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
  
  // Dark mode shadows (slightly stronger for better visibility)
  static const List<BoxShadow> shadowDarkSm = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowDarkMd = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowDarkLg = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}