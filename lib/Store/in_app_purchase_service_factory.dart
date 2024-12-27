import 'package:flutter/foundation.dart' show kIsWeb;
import 'in_app_purchase_services_mobile.dart';
import 'in_app_purchase_web_services.dart';

abstract class InAppPurchaseService {
  static Future<dynamic> create() async {
    if (kIsWeb) {
      final service = InAppPurchaseServiceWeb();
      await service.initialize();
      return service;
    } else {
      final service = InAppPurchaseServiceMobile();
      await service.initialize();
      return service;
    }
  }
}
