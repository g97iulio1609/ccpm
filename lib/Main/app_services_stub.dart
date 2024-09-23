// lib/services/app_services_stub.dart

abstract class AppServices {
  Future<void> initialize();
  Future<bool> isAppVersionSupported();
  Future<bool> checkSubscriptionStatus();
  Future<void> checkForUpdate();
}
