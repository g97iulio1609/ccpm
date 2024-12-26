import 'package:flutter/foundation.dart';

String? getCurrentUrl() {
  if (kIsWeb) {
    return Uri.base.toString();
  }
  return null;
}
