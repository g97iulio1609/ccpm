import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppServices {
  static final AppServices _instance = AppServices._internal();
  factory AppServices() => _instance;
  AppServices._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Error initializing Remote Config: $e');
    }
  }

  Future<bool> isAppVersionSupported() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final String minimumVersion = _remoteConfig.getString('minimum_app_version');

      final List<int> currentVersionParts = currentVersion.split('.').map(int.parse).toList();
      final List<int> minimumVersionParts = minimumVersion.split('.').map(int.parse).toList();

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
      print('Error checking app version: $e');
      return true;
    }
  }
}