import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> requestNotificationPermission() async {
  if (!kIsWeb) {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      // I permessi delle notifiche sono stati concessi.
    } else {
      // I permessi delle notifiche sono stati negati o l'utente ha selezionato "Non chiedere più".
    }
  }
}
