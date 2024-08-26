import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFFD700),
    brightness: Brightness.dark,
    primary: const Color(0xFFFFD700),
    onPrimary: Colors.black,
    primaryContainer: const Color(0xFF3A3000),
    onPrimaryContainer: const Color(0xFFFFE08F),
    secondary: const Color(0xFF81D4FA),  // Light blue for accents
    onSecondary: Colors.black,
    secondaryContainer: const Color(0xFF0277BD),  // Darker blue
    onSecondaryContainer: Colors.white,
    tertiary: const Color(0xFFA5CED5),
    onTertiary: Colors.black,
    tertiaryContainer: const Color(0xFF1E464D),
    onTertiaryContainer: const Color(0xFFC1E9F1),
    error: const Color(0xFFCF6679),
    onError: Colors.black,
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
    surface: const Color(0xFF121212),  // Very dark gray for background
    onSurface: Colors.white,
    surfaceContainerHighest: const Color(0xFF2C2C2C),  // Lighter gray for cards
    onSurfaceVariant: const Color(0xFFDADADA),
    outline: const Color(0xFF9E9E9E),
    outlineVariant: const Color(0xFF575757),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Colors.white,
    onInverseSurface: Colors.black,
    inversePrimary: const Color(0xFF705D00),
    surfaceTint: const Color(0xFFFFD700).withOpacity(0.1),
  );

  static ThemeData darkTheme = _buildTheme(darkColorScheme);

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: colorScheme.surfaceContainerHighest,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}