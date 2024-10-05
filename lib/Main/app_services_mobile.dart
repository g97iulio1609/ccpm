// lib/services/app_services_mobile.dart

import 'package:alphanessone/utils/debug_logger.dart';

import 'app_services_stub.dart';
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AppServicesMobile implements AppServices {
  AppServicesMobile._privateConstructor();
  static final AppServicesMobile instance = AppServicesMobile._privateConstructor();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  String? _minimumVersion;

  @override
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      await _fetchRemoteConfig();
    } catch (e) {
      debugLog('Error initializing AppServicesMobile: $e');
    }
  }

  Future<void> _fetchRemoteConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _minimumVersion = _remoteConfig.getString('minimum_app_version');
    } catch (e) {
      debugLog('Error fetching remote config: $e');
    }
  }

  @override
  Future<bool> isAppVersionSupported() async {
    if (_minimumVersion == null) {
      await _fetchRemoteConfig();
    }

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      return _compareVersions(currentVersion, _minimumVersion!);
    } catch (e) {
      debugLog('Error checking app version: $e');
      return true; 
    }
  }

  bool _compareVersions(String currentVersion, String minimumVersion) {
    final List<int> currentVersionParts = _parseVersion(currentVersion);
    final List<int> minimumVersionParts = _parseVersion(minimumVersion);

    for (int i = 0; i < minimumVersionParts.length; i++) {
      if (currentVersionParts.length <= i) return false;
      if (currentVersionParts[i] > minimumVersionParts[i]) return true;
      if (currentVersionParts[i] < minimumVersionParts[i]) return false;
    }

    return true;
  }

  List<int> _parseVersion(String version) {
    return version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  @override
  Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      if (_minimumVersion == null) {
        await _fetchRemoteConfig();
      }

      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      if (!_compareVersions(currentVersion, _minimumVersion!)) {
        await _performUpdate();
      }
    } catch (e) {
      debugLog('Error checking for update: $e');
    }
  }

  Future<void> _performUpdate() async {
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
        }
      }
    } catch (e) {
      debugLog('Error performing update: $e');
    }
  }

  @override
  Future<bool> checkSubscriptionStatus() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      String role = userData['role'] ?? 'client';
      String subscriptionPlatform = userData['subscriptionPlatform'] ?? '';

      if (role == 'client') return false;

      if (role == 'client_premium' || role == 'coach') {
        Timestamp? expiryDate = userData['subscriptionExpiryDate'];

        if (expiryDate == null) {
          await _updateUserToClient(user.uid);
          return false;
        }

        if (expiryDate.toDate().isBefore(DateTime.now())) {
          if (subscriptionPlatform == 'stripe') {
            await _checkStripeSubscription(user.uid, userData['subscriptionId']);
          } else {
            await _checkGooglePlaySubscription(user.uid, userData['productId'], userData['purchaseToken']);
          }
          userDoc = await _firestore.collection('users').doc(user.uid).get();
          userData = userDoc.data() as Map<String, dynamic>;
          role = userData['role'] ?? 'client';
          return role == 'client_premium' || role == 'coach';
        }

        return true;
      }

      return false;
    } catch (e) {
      debugLog('Error checking subscription status: $e');
      return false;
    }
  }

  Future<void> _checkStripeSubscription(String userId, String subscriptionId) async {
    try {
      final result = await _functions.httpsCallable('checkStripeSubscription').call({
        'subscriptionId': subscriptionId,
      });

      if (result.data['active']) {
        await _firestore.collection('users').doc(userId).update({
          'subscriptionExpiryDate': result.data['expiryDate'],
        });
      } else {
        await _updateUserToClient(userId);
      }
    } catch (e) {
      debugLog('Error checking Stripe subscription: $e');
      await _updateUserToClient(userId);
    }
  }

  Future<void> _checkGooglePlaySubscription(String userId, String productId, String purchaseToken) async {
    try {
      final result = await _functions.httpsCallable('checkGooglePlaySubscription').call({
        'productId': productId,
        'purchaseToken': purchaseToken,
      });

      if (result.data['valid']) {
        await _firestore.collection('users').doc(userId).update({
          'subscriptionExpiryDate': result.data['expiryDate'],
        });
      } else {
        await _updateUserToClient(userId);
      }
    } catch (e) {
      debugLog('Error checking Google Play subscription: $e');
      await _updateUserToClient(userId);
    }
  }

  Future<void> _updateUserToClient(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'client',
        'subscriptionExpiryDate': null,
        'subscriptionId': null,
        'subscriptionPlatform': null,
        'productId': null,
        'purchaseToken': null,
      });
    } catch (e) {
      debugLog('Error updating user to client: $e');
    }
  }
}

// Esponi l'istanza tramite una funzione getter
AppServices getAppServices() => AppServicesMobile.instance;
