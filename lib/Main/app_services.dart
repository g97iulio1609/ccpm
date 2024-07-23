import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';

class AppServices {
  AppServices._();
  static final AppServices instance = AppServices._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
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
}