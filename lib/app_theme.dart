import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1976D2),
    primary: const Color(0xFFFFD700),
    secondary: const Color(0xFFFF9800),
    tertiary: const Color(0xFF4CAF50),
    error: const Color(0xFFF44336),
    background: const Color(0xFF121212),
    surface: const Color(0xFF1E1E1E),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onTertiary: Colors.black,
    onError: Colors.white,
    onBackground: Colors.white,
    onSurface: Colors.white,
    brightness: Brightness.dark,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    textTheme: GoogleFonts.robotoTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
