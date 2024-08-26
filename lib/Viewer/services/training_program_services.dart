import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TrainingProgramServices {
  // Exercise Service
  Future<void> updateSeriesData(String seriesId, int? repsDone, double? weightDone) async {
    await FirebaseFirestore.instance.collection('series').doc(seriesId).update({
      'done': repsDone != null && weightDone != null,
      'reps_done': repsDone,
      'weight_done': weightDone,
    });
  }

  // Timer Service
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

  // Training Service
  Future<List<Map<String, dynamic>>> fetchTrainingWeeks(String programId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('weeks')
        .where('programId', isEqualTo: programId)
        .orderBy('number')
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  // Week Service
  Stream<QuerySnapshot> getWorkouts(String weekId) {
    return FirebaseFirestore.instance
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .orderBy('order')
        .snapshots();
  }

  // Workout Service
  Future<List<Map<String, dynamic>>> fetchExercises(String workoutId) async {
    final exercisesSnapshot = await FirebaseFirestore.instance
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('order')
        .get();

    final seriesDataList = <String, List<Map<String, dynamic>>>{};

    for (final doc in exercisesSnapshot.docs) {
      final exerciseId = doc.id;
      final seriesSnapshot = await FirebaseFirestore.instance
          .collection('series')
          .where('exerciseId', isEqualTo: exerciseId)
          .orderBy('order')
          .get();
      seriesDataList[exerciseId] = seriesSnapshot.docs
          .map((doc) => doc.data()..['id'] = doc.id)
          .toList();
    }

    return exercisesSnapshot.docs.map((doc) {
      final exerciseData = doc.data()..['id'] = doc.id;
      exerciseData['series'] = seriesDataList[doc.id] ?? [];
      return exerciseData;
    }).toList();
  }

  Future<void> updateSeries(String seriesId, int repsDone, double weightDone) async {
    final seriesRef = FirebaseFirestore.instance.collection('series').doc(seriesId);
    final seriesDoc = await seriesRef.get();
    final seriesData = seriesDoc.data();

    if (seriesData != null) {
      final reps = seriesData['reps'] ?? 0;
      final weight = (seriesData['weight'] ?? 0.0).toDouble();
      final done = repsDone >= reps && weightDone >= weight;

      final batch = FirebaseFirestore.instance.batch();
      batch.update(seriesRef, {
        'reps_done': repsDone,
        'weight_done': weightDone,
        'done': done,
      });
      await batch.commit();
    }
  }


 Future<String> fetchWeekName(String weekId) async {
    try {
      final weekDoc = await FirebaseFirestore.instance.collection('weeks').doc(weekId).get();
      final number = weekDoc.data()?['number']?.toString() ?? '';
      return number.isNotEmpty ? 'Settimana $number' : 'Settimana';
    } catch (e) {
      debugPrint('Error fetching workout name: $e');
      return 'Settimana';
    }
  }

   Future<String> fetchWorkoutName(String workoutId) async {
    try {
      final workoutDoc = await FirebaseFirestore.instance.collection('workouts').doc(workoutId).get();
      final order = workoutDoc.data()?['order']?.toString() ?? '';
      return order.isNotEmpty ? 'Allenamento $order' : 'Allenamento';
    } catch (e) {
      debugPrint('Error fetching workout name: $e');
      return 'Allenamento';
    }
  }

}