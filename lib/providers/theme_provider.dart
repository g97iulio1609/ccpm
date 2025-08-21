import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

final appThemeModeProvider = StateNotifierProvider<AppThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.read(prefsForThemeProvider);
  return AppThemeModeNotifier(prefs);
});

// Provider pubblico da override in main.dart
final prefsForThemeProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences provider must be overridden');
});

class AppThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';
  final SharedPreferences prefs;
  AppThemeModeNotifier(this.prefs) : super(_loadInitial(prefs));

  static ThemeMode _loadInitial(SharedPreferences prefs) {
    final modeStr = prefs.getString(_key);
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    switch (mode) {
      case ThemeMode.light:
        prefs.setString(_key, 'light');
        break;
      case ThemeMode.dark:
        prefs.setString(_key, 'dark');
        break;
      case ThemeMode.system:
        prefs.setString(_key, 'system');
        break;
    }
  }
}
