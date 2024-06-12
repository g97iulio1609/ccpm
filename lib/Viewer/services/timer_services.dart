import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TimerService {
  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'rest_timer_channel',
      'Rest Timer',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      visibility: NotificationVisibility.public,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      timeoutAfter: null,
      autoCancel: false,
      ongoing: false,
      fullScreenIntent: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await FlutterLocalNotificationsPlugin().show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
