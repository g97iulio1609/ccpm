import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design Tokens Classes
class Spacing {
  const Spacing();
  final double xxs = 4.0;
  final double xs = 8.0;
  final double sm = 12.0;
  final double md = 16.0;
  final double lg = 24.0;
  final double xl = 32.0;
  final double xxl = 40.0;
}

class Radii {
  const Radii();
  final double sm = 8.0;
  final double md = 12.0;
  final double lg = 16.0;
  final double xl = 24.0;
  final double xxl = 32.0;
  final double full = 999.0;
}

class Elevations {
  const Elevations();

  List<BoxShadow> get small => [
    BoxShadow(color: Colors.black.withAlpha(13), offset: const Offset(0, 1), blurRadius: 2),
  ];

  List<BoxShadow> get medium => [
    BoxShadow(color: Colors.black.withAlpha(20), offset: const Offset(0, 4), blurRadius: 8),
  ];

  List<BoxShadow> get large => [
    BoxShadow(color: Colors.black.withAlpha(31), offset: const Offset(0, 8), blurRadius: 16),
  ];
}

class AppTheme {
  // Design Tokens
  static const Spacing spacing = Spacing();
  static const Radii radii = Radii();
  static const Elevations elevations = Elevations();

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
    primaryContainer: primaryGoldDark.withAlpha(38),
    onPrimaryContainer: primaryGold,
    secondary: accentBlue,
    onSecondary: Colors.white,
    secondaryContainer: accentBlue.withAlpha(38),
    onSecondaryContainer: accentBlueDark,
    tertiary: accentPurple,
    onTertiary: Colors.white,
    tertiaryContainer: accentPurple.withAlpha(38),
    onTertiaryContainer: accentPurpleDark,
    error: error,
    onError: Colors.white,
    errorContainer: error.withAlpha(38),
    onErrorContainer: errorDark,
    surface: surfaceDarkest,
    onSurface: Colors.white,
    onSurfaceVariant: Colors.white.withAlpha(179),
    surfaceContainerHighest: surfaceMedium,
    outline: Colors.white.withAlpha(51),
    outlineVariant: Colors.white.withAlpha(26),
  );

  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: primaryGold,
    brightness: Brightness.light,
    primary: primaryGold,
    onPrimary: Colors.white,
    primaryContainer: primaryGold.withAlpha(38),
    onPrimaryContainer: primaryGoldDark,
    secondary: accentBlue,
    onSecondary: Colors.white,
    secondaryContainer: accentBlue.withAlpha(38),
    onSecondaryContainer: accentBlueDark,
    tertiary: accentPurple,
    onTertiary: Colors.white,
    tertiaryContainer: accentPurple.withAlpha(38),
    onTertiaryContainer: accentPurpleDark,
    error: error,
    onError: Colors.white,
    errorContainer: error.withAlpha(38),
    onErrorContainer: errorDark,
    surface: surfaceLightest,
    onSurface: surfaceDarkest,
    onSurfaceVariant: surfaceDark.withAlpha(179),
    surfaceContainerHighest: surfaceLightMedium,
    outline: surfaceDark.withAlpha(51),
    outlineVariant: surfaceDark.withAlpha(26),
  );

  // Themes
  static ThemeData darkTheme = _buildTheme(darkColorScheme);
  static ThemeData lightTheme = _buildTheme(lightColorScheme);

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    final textTheme = GoogleFonts.interTextTheme()
        .copyWith(
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
        )
        .apply(
          // Rimuoviamo questi apply che sovrascrivevano i colori specifici
          // bodyColor: colorScheme.onSurface,
          // displayColor: colorScheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,

      brightness: isDark ? Brightness.dark : Brightness.light,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // Page transitions: Material 3 aligned transitions with safe builders
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _ReducedAwareTransitionsBuilder(),
          TargetPlatform.iOS: _ReducedAwareCupertinoTransitionsBuilder(),
          TargetPlatform.macOS: _ReducedAwareCupertinoTransitionsBuilder(),
          TargetPlatform.windows: _ReducedAwareTransitionsBuilder(),
          TargetPlatform.linux: _ReducedAwareTransitionsBuilder(),
        },
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? colorScheme.surface : colorScheme.surface.withAlpha(242),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: isDark ? 2 : 0.5,
        shadowColor: colorScheme.shadow.withAlpha(26),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
          side: BorderSide(color: colorScheme.outline.withAlpha(isDark ? 51 : 26), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest.withAlpha(76) : colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(color: colorScheme.outline.withAlpha(isDark ? 51 : 26)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.md),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.md),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant.withAlpha(128),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.primary.withAlpha(76);
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onPrimary.withAlpha(76);
            }
            return colorScheme.onPrimary;
          }),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radii.md)),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.onPrimary.withAlpha(26);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.onPrimary.withAlpha(13);
            }
            return null;
          }),
        ),
      ),

      // IconButton Theme: touch target >= 48, overlay states
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          padding: WidgetStateProperty.all(EdgeInsets.all(spacing.xs)),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.onSurface.withAlpha(20);
            }
            if (states.contains(WidgetState.focused)) {
              return colorScheme.primary.withAlpha(26);
            }
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.onSurface.withAlpha(30);
            }
            return null;
          }),
        ),
      ),

      // TextButton Theme: uniform hover/focus
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withAlpha(20);
            }
            if (states.contains(WidgetState.focused)) {
              return colorScheme.primary.withAlpha(30);
            }
            return null;
          }),
        ),
      ),

      // FilledButton Theme: uniform hover/focus
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.onPrimary.withAlpha(26);
            }
            if (states.contains(WidgetState.focused)) {
              return colorScheme.onPrimary.withAlpha(38);
            }
            return null;
          }),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? colorScheme.surface : colorScheme.surface.withAlpha(242),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radii.xl)),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? colorScheme.surface : colorScheme.surface.withAlpha(242),
        modalBackgroundColor: isDark ? colorScheme.surface : colorScheme.surface.withAlpha(242),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radii.xl)),
        ),
        elevation: 0,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colorScheme.inverseSurface : colorScheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? colorScheme.onInverseSurface : colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radii.sm)),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: spacing.md,
      ),

      // Progress Indicators: adopt latest Material spec (Flutter 3.29+)
      progressIndicatorTheme: const ProgressIndicatorThemeData(),

      // Slider: adopt latest Material spec (Flutter 3.29+)
      sliderTheme: const SliderThemeData(),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
        labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radii.sm)),
        side: BorderSide(color: colorScheme.outline.withAlpha(isDark ? 51 : 26)),
      ),

      // Global hover/focus colors (desktop/web)
      hoverColor: colorScheme.primary.withAlpha(16),
      focusColor: colorScheme.primary.withAlpha(26),
      highlightColor: colorScheme.primary.withAlpha(20),

      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

// Transitions che rispettano le preferenze di riduzione animazioni
class _ReducedAwareTransitionsBuilder extends PageTransitionsBuilder {
  const _ReducedAwareTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final mq = MediaQuery.maybeOf(context);
    final reduce = mq?.disableAnimations == true || mq?.accessibleNavigation == true;
    if (reduce) {
      return child;
    }
    return ZoomPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

class _ReducedAwareCupertinoTransitionsBuilder extends PageTransitionsBuilder {
  const _ReducedAwareCupertinoTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final mq = MediaQuery.maybeOf(context);
    final reduce = mq?.disableAnimations == true || mq?.accessibleNavigation == true;
    if (reduce) {
      return child;
    }
    return const CupertinoPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
