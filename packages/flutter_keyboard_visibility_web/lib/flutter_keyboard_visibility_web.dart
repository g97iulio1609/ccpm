import 'package:flutter_keyboard_visibility_platform_interface/flutter_keyboard_visibility_platform_interface.dart';

/// Minimal WASM-safe web implementation that avoids importing dart:html.
/// It provides a no-op visibility stream and always returns false for isVisible.
class FlutterKeyboardVisibilityWeb extends FlutterKeyboardVisibilityPlatform {
  static void registerWith([Object? registrar]) {
    FlutterKeyboardVisibilityPlatform.instance = FlutterKeyboardVisibilityWeb();
  }

  @override
  Stream<bool> get onChange {
    // No keyboard visibility events on web wasm in this stub
    return const Stream<bool>.empty();
  }
}
