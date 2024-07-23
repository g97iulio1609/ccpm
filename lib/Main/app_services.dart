import 'dart:io';
import 'package:alphanessone/Store/inAppSubscriptions_model.dart';
import 'package:alphanessone/Store/inAppSubscriptions_services.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';

class AppServices {
  static final AppServices _instance = AppServices._internal();
  factory AppServices() => _instance;
  AppServices._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final InAppPurchaseService _inAppPurchaseService = InAppPurchaseService();

  String? _minimumVersion;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      await _fetchRemoteConfig();
      await _inAppPurchaseService.initStoreInfo();
      await checkSubscriptionStatus();
    } catch (e) {
      debugPrint("Error initializing AppServices: $e");
    }
  }

  Future<void> _fetchRemoteConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _minimumVersion = _remoteConfig.getString('minimum_app_version');
    } catch (e) {
      debugPrint("Error fetching remote config: $e");
    }
  }

  Future<bool> isAppVersionSupported() async {
    if (_minimumVersion == null) {
      await _fetchRemoteConfig();
    }

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final List<int> currentVersionParts =
          currentVersion.split('.').map(int.parse).toList();
      final List<int> minimumVersionParts =
          _minimumVersion!.split('.').map(int.parse).toList();

      for (int i = 0; i < minimumVersionParts.length; i++) {
        if (currentVersionParts.length <= i) {
          return false;
        }
        if (currentVersionParts[i] > minimumVersionParts[i]) {
          return true;
        }
        if (currentVersionParts[i] < minimumVersionParts[i]) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking app version: $e');
      return true;
    }
  }

  Future<void> checkForUpdate() async {
    if (Platform.isAndroid) {
      if (_minimumVersion == null) {
        await _fetchRemoteConfig();
      }

      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final List<int> currentVersionParts =
          currentVersion.split('.').map(int.parse).toList();
      final List<int> minimumVersionParts =
          _minimumVersion!.split('.').map(int.parse).toList();

      bool shouldUpdate = false;
      for (int i = 0; i < minimumVersionParts.length; i++) {
        if (currentVersionParts.length <= i ||
            currentVersionParts[i] < minimumVersionParts[i]) {
          shouldUpdate = true;
          break;
        }
      }

      if (shouldUpdate) {
        final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          if (info.immediateUpdateAllowed) {
            await InAppUpdate.performImmediateUpdate();
          } else if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate();
          }
        }
      }
    }
  }

  // Metodi per gestire gli abbonamenti
  Future<void> purchaseSubscription(String kId) async {
    await _inAppPurchaseService.purchaseSubscription(kId);
  }

  Future<void> redeemPromoCode(String promoCode) async {
    await _inAppPurchaseService.redeemPromoCode(promoCode);
  }

  Future<void> checkSubscriptionStatus() async {
    await _inAppPurchaseService.checkSubscriptionStatus();
  }

  List<SubscriptionPlan> get availableSubscriptionPlans => _inAppPurchaseService.availablePlans;

  List<Subscription> get activeSubscriptions => _inAppPurchaseService.activeSubscriptions;

  Stream<List<PurchaseDetails>> get purchaseStream => _inAppPurchaseService.purchaseStream;

  void handlePurchaseUpdate(PurchaseDetails purchaseDetails) {
    _inAppPurchaseService.handlePurchaseUpdate(purchaseDetails);
  }
}
