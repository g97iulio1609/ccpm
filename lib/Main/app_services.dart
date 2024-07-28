import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AppServices {
  AppServices._();
  static final AppServices instance = AppServices._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  String? _minimumVersion;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      await _fetchRemoteConfig();
    } catch (e) {
      debugPrint('Error initializing AppServices: $e');
    }
  }

  Future<void> _fetchRemoteConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _minimumVersion = _remoteConfig.getString('minimum_app_version');
    } catch (e) {
      debugPrint('Error fetching remote config: $e');
    }
  }

  Future<bool> isAppVersionSupported() async {
    if (_minimumVersion == null) {
      await _fetchRemoteConfig();
    }

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      return _compareVersions(currentVersion, _minimumVersion!);
    } catch (e) {
      debugPrint('Error checking app version: $e');
      return true; // Assume supported if there's an error
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
      debugPrint('Error checking for update: $e');
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
      debugPrint('Error performing update: $e');
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      String role = userData['role'] ?? 'client';
      String productId = userData['productId'];
      String purchaseToken = userData['purchaseToken'];

      // Se l'utente è già un client base, non c'è bisogno di ulteriori controlli
      if (role == 'client') return false;

      // Procediamo con il controllo solo per utenti premium o coach
      if (role == 'client_premium' || role == 'coach') {
        Timestamp? expiryDate = userData['subscriptionExpiryDate'];

        if (expiryDate == null) {
          // Se non c'è una data di scadenza, consideriamo l'abbonamento non valido
          await _updateUserToClient(user.uid);
          return false;
        }

        if (expiryDate.toDate().isBefore(DateTime.now())) {
          // L'abbonamento è scaduto, chiamiamo la Cloud Function per verificare e aggiornare lo stato
          await _callSubscriptionCheckFunction(user.uid, productId, purchaseToken);
          // Rileggiamo i dati dell'utente dopo la chiamata alla Cloud Function
          userDoc = await _firestore.collection('users').doc(user.uid).get();
          userData = userDoc.data() as Map<String, dynamic>;
          role = userData['role'] ?? 'client';
          return role == 'client_premium' || role == 'coach';
        }

        return true;
      }

      // Per qualsiasi altro ruolo non riconosciuto, consideriamo l'abbonamento non valido
      return false;
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  Future<void> _callSubscriptionCheckFunction(String userId, String productId, String purchaseToken) async {
    try {
      HttpsCallable callable = _functions.httpsCallable('checkAndUpdateSubscription');
      final result = await callable.call({'purchaseToken': purchaseToken, 'productId': productId});
      debugPrint('Cloud Function result: ${result.data}');
    } catch (e) {
      debugPrint('Error calling Cloud Function: $e');
    }
  }

  Future<void> _updateUserToClient(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'client',
        'subscriptionExpiryDate': null
      });
      debugPrint('User role updated to client');
    } catch (e) {
      debugPrint('Error updating user role: $e');
    }
  }
}
