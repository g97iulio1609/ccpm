import 'package:alphanessone/providers/theme_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final uiGlassEnabledProvider = StateNotifierProvider<UiGlassEnabledNotifier, bool>((ref) {
  final prefs = ref.read(prefsForThemeProvider);
  return UiGlassEnabledNotifier(prefs);
});

class UiGlassEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'ui_glass_enabled';
  final SharedPreferences prefs;
  UiGlassEnabledNotifier(this.prefs) : super(prefs.getBool(_key) ?? false);

  void setEnabled(bool enabled) {
    state = enabled;
    prefs.setBool(_key, enabled);
  }
}

// Scope applicazione effetto Glass sulla AppBar:
// false => solo top-level, true => tutte le route
final appBarGlassAllRoutesProvider = StateNotifierProvider<UiAppBarGlassScopeNotifier, bool>((ref) {
  final prefs = ref.read(prefsForThemeProvider);
  return UiAppBarGlassScopeNotifier(prefs);
});

class UiAppBarGlassScopeNotifier extends StateNotifier<bool> {
  static const _key = 'ui_appbar_glass_all_routes';
  final SharedPreferences prefs;
  UiAppBarGlassScopeNotifier(this.prefs) : super(prefs.getBool(_key) ?? false);

  void setAllRoutes(bool allRoutes) {
    state = allRoutes;
    prefs.setBool(_key, allRoutes);
  }
}
