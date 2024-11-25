import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design Tokens Classes
class _Spacing {
  const _Spacing();
  final double xs = 4.0;
  final double sm = 8.0;
  final double md = 16.0;
  final double lg = 24.0;
  final double xl = 32.0;
  final double xxl = 40.0;
}

class _Radii {
  const _Radii();
  final double sm = 8.0;
  final double md = 12.0;
  final double lg = 16.0;
  final double xl = 24.0;
  final double xxl = 32.0;
  final double full = 999.0;
}

class _Elevations {
  const _Elevations();
  
  List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      offset: const Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      offset: const Offset(0, 8),
      blurRadius: 16,
    ),
  ];
}

class AppTheme {
  // Design Tokens
  static const _Spacing spacing = _Spacing();
  static const _Radii radii = _Radii();
  static const _Elevations elevations = _Elevations();

  // Brand Colors
  static const primaryGold = Color(0xFFFFC107);
  static const primaryGoldLight = Color(0xFFFFD700);
  static const primaryGoldDark = Color(0xFFC79100);

  // Neutral Colors - Dark Theme
  static const surfaceDarkest = Color(0xFF0A0A0A);
  static const surfaceDark = Color(0xFF121212);
  static const surfaceMedium = Color(0xFF1E1E1E);
  static const surfaceLight = Color(0xFF2C2C2C);

  // Neutral Colors - Light Theme
  static const surfaceLightest = Color(0xFFFAFAFA);
  static const surfaceLightMedium = Color(0xFFF0F0F0);
  static const surfaceLightDark = Color(0xFFE0E0E0);

  // Accent Colors
  static const accentBlue = Color(0xFF60A5FA);
  static const accentBlueDark = Color(0xFF1E40AF);
  static const accentGreen = Color(0xFF34D399);
  static const accentGreenDark = Color(0xFF047857);
  static const accentPurple = Color(0xFFA78BFA);
  static const accentPurpleDark = Color(0xFF6D28D9);
  
  // Semantic Colors
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const errorDark = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // Gradients
  static const gradientGold = LinearGradient(
    colors: [primaryGold, primaryGoldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientDark = LinearGradient(
    colors: [surfaceDarkest, surfaceDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const gradientLight = LinearGradient(
    colors: [surfaceLightMedium, surfaceLightDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Color Schemes
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: primaryGold,
    brightness: Brightness.dark,
    primary: primaryGold,
    onPrimary: surfaceDarkest,
    primaryContainer: primaryGoldDark.withOpacity(0.15),
    onPrimaryContainer: primaryGold,
    
    secondary: accentBlue,
    onSecondary: Colors.white,
    secondaryContainer: accentBlue.withOpacity(0.15),
    onSecondaryContainer: accentBlueDark,
    
    tertiary: accentPurple,
    onTertiary: Colors.white,
    tertiaryContainer: accentPurple.withOpacity(0.15),
    onTertiaryContainer: accentPurpleDark,
    
    error: error,
    onError: Colors.white,
    errorContainer: error.withOpacity(0.15),
    onErrorContainer: errorDark,
    
    background: surfaceDarkest,
    onBackground: Colors.white,
    
    surface: surfaceDark,
    onSurface: Colors.white,
    surfaceVariant: surfaceMedium,
    onSurfaceVariant: Colors.white.withOpacity(0.7),
    
    surfaceContainerHighest: surfaceLight,
    outline: Colors.white.withOpacity(0.2),
    outlineVariant: Colors.white.withOpacity(0.1),
  );

  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: primaryGold,
    brightness: Brightness.light,
    primary: primaryGold,
    onPrimary: Colors.white,
    primaryContainer: primaryGold.withOpacity(0.15),
    onPrimaryContainer: primaryGoldDark,
    
    secondary: accentBlue,
    onSecondary: Colors.white,
    secondaryContainer: accentBlue.withOpacity(0.15),
    onSecondaryContainer: accentBlueDark,
    
    tertiary: accentPurple,
    onTertiary: Colors.white,
    tertiaryContainer: accentPurple.withOpacity(0.15),
    onTertiaryContainer: accentPurpleDark,
    
    error: error,
    onError: Colors.white,
    errorContainer: error.withOpacity(0.15),
    onErrorContainer: errorDark,
    
    background: surfaceLightest,
    onBackground: surfaceDarkest,
    
    surface: Colors.white,
    onSurface: surfaceDarkest,
    surfaceVariant: surfaceLightMedium,
    onSurfaceVariant: surfaceDark.withOpacity(0.7),
    
    surfaceContainerHighest: surfaceLightDark,
    outline: surfaceDark.withOpacity(0.2),
    outlineVariant: surfaceDark.withOpacity(0.1),
  );

  // Themes
  static ThemeData darkTheme = _buildTheme(darkColorScheme);
  static ThemeData lightTheme = _buildTheme(lightColorScheme);

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    
    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.12,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.16,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.22,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.25,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.29,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.33,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        height: 1.27,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        height: 1.5,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        height: 1.43,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.5,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.43,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.33,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        height: 1.43,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        height: 1.33,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        height: 1.27,
        color: isDark ? Colors.white : colorScheme.onSurface,
      ),
    ).apply(
      // Rimuoviamo questi apply che sovrascrivevano i colori specifici
      // bodyColor: colorScheme.onSurface,
      // displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      
      brightness: isDark ? Brightness.dark : Brightness.light,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDark 
            ? colorScheme.surface
            : colorScheme.surface.withOpacity(0.95),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: isDark ? 2 : 0.5,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: isDark 
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(isDark ? 0.1 : 0.05),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark 
            ? colorScheme.surfaceVariant.withOpacity(0.3)
            : colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.md,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return colorScheme.primary.withOpacity(0.3);
            }
            return colorScheme.primary;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return colorScheme.onPrimary.withOpacity(0.3);
            }
            return colorScheme.onPrimary;
          }),
          elevation: MaterialStateProperty.all(0),
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: spacing.lg,
              vertical: spacing.md,
            ),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radii.md),
            ),
          ),
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return colorScheme.onPrimary.withOpacity(0.1);
            }
            if (states.contains(MaterialState.hovered)) {
              return colorScheme.onPrimary.withOpacity(0.05);
            }
            return null;
          }),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: isDark 
            ? colorScheme.surface
            : colorScheme.surface.withOpacity(0.95),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.xl),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark 
            ? colorScheme.surface
            : colorScheme.surface.withOpacity(0.95),
        modalBackgroundColor: isDark 
            ? colorScheme.surface
            : colorScheme.surface.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radii.xl)),
        ),
        elevation: 0,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark 
            ? colorScheme.inverseSurface
            : colorScheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark 
              ? colorScheme.onInverseSurface
              : colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.sm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: spacing.md,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: isDark 
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.sm),
        ),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.1),
        ),
      ),

      scaffoldBackgroundColor: colorScheme.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}