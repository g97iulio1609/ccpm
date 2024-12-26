import 'package:flutter/foundation.dart';

String? getCurrentUrl() {
  if (kIsWeb) {
    // ignore: avoid_web_libraries_in_flutter
    return Uri.base.toString();
  }
  return null;
}
