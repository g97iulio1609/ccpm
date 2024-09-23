// lib/services/app_services.dart

import 'package:alphanessone/Main/app_services_mobile.dart';
import 'package:alphanessone/Main/app_services_web.dart';

import 'app_services_stub.dart';

export 'app_services_stub.dart';

// Use conditional imports

// Provide the instance of AppServices via the getter
AppServices get appServices {
  // This will use the correct implementation based on the platform
  if (identical(0, 0.0)) {
    // This condition is always true for JavaScript (web)
    return AppServicesWeb.instance;
  } else {
    // This will be used for non-web platforms
    return AppServicesMobile.instance;
  }
}