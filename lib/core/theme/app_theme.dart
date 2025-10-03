// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary brand color
  static const Color primary = Color(0xFF0066FF);

  // Neutral palette (light)
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral10 = Color(0xFFF7F7FA);
  static const Color neutral50 = Color(0xFFBFC7D6);
  static const Color neutral100 = Color(0xFF1A2330);

  // Success / Error
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);

  // Elevation surfaces (light)
  static const Color surface = neutral0;
  static const Color background = neutral10;
}

/// Centralized text styles. Use Theme.of(context).textTheme as the source of truth,
/// but keep commonly used variants here for convenience.
class AppTextStyles {
  static TextStyle titleLarge(ColorScheme colorScheme) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: colorScheme.onBackground,
    height: 1.25,
  );

  static TextStyle titleMedium(ColorScheme colorScheme) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: colorScheme.onBackground,
  );

  static TextStyle bodyLarge(ColorScheme colorScheme) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: colorScheme.onBackground,
  );

  static TextStyle bodySmall(ColorScheme colorScheme) => TextStyle(
    fontSize: 12,
    color: colorScheme.onBackground.withOpacity(0.8),
  );
}

class AppTheme {
  // Seed colors for Material 3 ColorScheme generation.
  static const Color _seed = AppColors.primary;

  // Light color scheme built from a seed
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.light,
    primary: AppColors.primary,
    background: AppColors.background,
    surface: AppColors.surface,
    error: AppColors.error,
    secondary: AppColors.primary,
  );
  // Dark color scheme built from a seed
  static final ColorScheme _darkColorScheme = (() {
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      primary: AppColors.primary,
    );

    // App-Wide colors
    return base.copyWith(
      background: const Color(0xFF071018), // deep neutral background
      surface: const Color(0xFF0B1520), // slightly lighter surface for cards/panels
      surfaceVariant: const Color(0xFF12232C), // subtle variant for dividers/bars
      onBackground: const Color(0xFFE6F0F8), // readable text on deep background
      onSurface: const Color(0xFFE6EEF5), // text on surface
      primaryContainer: const Color(0xFF2539FF), // subtle container tint for primary
      onPrimaryContainer: Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      outline: const Color(0xFF3A4952),
      shadow: Colors.black54,
      secondary: AppColors.primary,
    );
  })();

  /// Light ThemeData
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: _lightColorScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightColorScheme.surface,
      foregroundColor: _lightColorScheme.onSurface,
      elevation: 1,
      centerTitle: false,
      titleTextStyle: AppTextStyles.titleLarge(_lightColorScheme),
      iconTheme: IconThemeData(color: _lightColorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: _lightColorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    textTheme: TextTheme(
      titleLarge: AppTextStyles.titleLarge(_lightColorScheme),
      titleMedium: AppTextStyles.titleMedium(_lightColorScheme),
      bodyLarge: AppTextStyles.bodyLarge(_lightColorScheme),
      bodySmall: AppTextStyles.bodySmall(_lightColorScheme),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _lightColorScheme.onPrimary,
        backgroundColor: _lightColorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    iconTheme: IconThemeData(color: _lightColorScheme.onSurface),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  /// Dark ThemeData
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: _darkColorScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkColorScheme.surface,
      foregroundColor: _darkColorScheme.onSurface,
      elevation: 1,
      centerTitle: false,
      titleTextStyle: AppTextStyles.titleLarge(_darkColorScheme),
      iconTheme: IconThemeData(color: _darkColorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: _darkColorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    textTheme: TextTheme(
      titleLarge: AppTextStyles.titleLarge(_darkColorScheme),
      titleMedium: AppTextStyles.titleMedium(_darkColorScheme),
      bodyLarge: AppTextStyles.bodyLarge(_darkColorScheme),
      bodySmall: AppTextStyles.bodySmall(_darkColorScheme),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _darkColorScheme.onPrimary,
        backgroundColor: _darkColorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _darkColorScheme.surfaceVariant,
      labelStyle: TextStyle(color: _darkColorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: _darkColorScheme.onSurface),
      selectedColor: _darkColorScheme.primary,
      disabledColor: _darkColorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      secondarySelectedColor: _darkColorScheme.primaryContainer,
      brightness: Brightness.dark,
    ),
    iconTheme: IconThemeData(color: _darkColorScheme.onSurface),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static ThemeData getThemeData({required bool isDark}) =>
      isDark ? darkTheme : lightTheme;
}