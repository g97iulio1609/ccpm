import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TrainingProgramServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Exercise Service
  Future<void> updateSeriesData(String seriesId, int? repsDone, double? weightDone) async {
    await _firestore.collection('series').doc(seriesId).update({
      'done': repsDone != null && weightDone != null,
      'reps_done': repsDone,
      'weight_done': weightDone,
    });
  }

  Future<void> updateSeriesWithMaxValues(
    String seriesId,
    int reps,
    int? maxReps,
    double weight,
    double? maxWeight,
    int repsDone,
    double weightDone,
  ) async {
    bool isDone = _isSeriesDone(reps, maxReps, weight, maxWeight, repsDone, weightDone);
    
    await _firestore.collection('series').doc(seriesId).update({
      'reps': reps,
      'maxReps': maxReps,
      'weight': weight,
      'maxWeight': maxWeight,
      'reps_done': repsDone,
      'weight_done': weightDone,
      'done': isDone,
    });
  }

  bool _isSeriesDone(int reps, int? maxReps, double weight, double? maxWeight, int repsDone, double weightDone) {
    bool repsCompleted = maxReps != null
        ? repsDone >= reps && repsDone <= maxReps
        : repsDone >= reps;

    bool weightCompleted = maxWeight != null
        ? weightDone >= weight && weightDone <= maxWeight
        : weightDone >= weight;

    return repsCompleted && weightCompleted;
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

Future<void> updateSeriesForExerciseChange(String seriesId, {
  required double weight,
  double? maxWeight,
  required int reps,
  required String intensity,
  required String rpe,
  String? rpeMax, // Aggiunto rpeMax come parametro opzionale
}) async {
  final updateData = {
    'weight': weight,
    'reps': reps,
    'intensity': intensity,
    'rpe': rpe,
    'reps_done': 0,
    'weight_done': 0.0,
    'done': false,
  };

  // Aggiungi maxWeight se presente
  if (maxWeight != null) {
    updateData['maxWeight'] = maxWeight;
  }

  // Aggiungi rpeMax se presente
  if (rpeMax != null) {
    updateData['rpeMax'] = rpeMax;
  }

  await FirebaseFirestore.instance.collection('series').doc(seriesId).update(updateData);
}

  // Training Service
  Future<List<Map<String, dynamic>>> fetchTrainingWeeks(String programId) async {
    QuerySnapshot querySnapshot = await _firestore
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
    return _firestore
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .orderBy('order')
        .snapshots();
  }

  // Workout Service
  Future<List<Map<String, dynamic>>> fetchExercises(String workoutId) async {
    final exercisesSnapshot = await _firestore
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('order')
        .get();

    final seriesDataList = <String, List<Map<String, dynamic>>>{};

    for (final doc in exercisesSnapshot.docs) {
      final exerciseId = doc.id;
      final seriesSnapshot = await _firestore
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
    final seriesRef = _firestore.collection('series').doc(seriesId);
    final seriesDoc = await seriesRef.get();
    final seriesData = seriesDoc.data();

    if (seriesData != null) {
      final reps = seriesData['reps'] ?? 0;
      final maxReps = seriesData['maxReps'];
      final weight = (seriesData['weight'] ?? 0.0).toDouble();
      final maxWeight = seriesData['maxWeight'];

      final done = _isSeriesDone(reps, maxReps, weight, maxWeight, repsDone, weightDone);

      final batch = _firestore.batch();
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
      final weekDoc = await _firestore.collection('weeks').doc(weekId).get();
      final number = weekDoc.data()?['number']?.toString() ?? '';
      return number.isNotEmpty ? 'Settimana $number' : 'Settimana';
    } catch (e) {
      debugPrint('Error fetching workout name: $e');
      return 'Settimana';
    }
  }

  Future<String> fetchWorkoutName(String workoutId) async {
    try {
      final workoutDoc = await _firestore.collection('workouts').doc(workoutId).get();
      final order = workoutDoc.data()?['order']?.toString() ?? '';
      return order.isNotEmpty ? 'Allenamento $order' : 'Allenamento';
    } catch (e) {
      debugPrint('Error fetching workout name: $e');
      return 'Allenamento';
    }
  }

  Future<void> updateTrainingProgram(Map<String, dynamic> programData) async {
    final programId = programData['id'];
    if (programId == null) {
      throw Exception('Program ID is null');
    }

    await _firestore.collection('trainingPrograms').doc(programId).update(programData);
  }

  Future<void> deleteTrainingProgram(String programId) async {
    await _firestore.collection('trainingPrograms').doc(programId).delete();
  }

  Future<Map<String, dynamic>> fetchTrainingProgram(String programId) async {
    final docSnapshot = await _firestore.collection('trainingPrograms').doc(programId).get();
    if (!docSnapshot.exists) {
      throw Exception('Training program not found');
    }
    return docSnapshot.data()!;
  }

  Future<List<Map<String, dynamic>>> fetchUserTrainingPrograms(String userId) async {
    final querySnapshot = await _firestore
        .collection('trainingPrograms')
        .where('userId', isEqualTo: userId)
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  Future<void> createTrainingProgram(Map<String, dynamic> programData) async {
    await _firestore.collection('trainingPrograms').add(programData);
  }

  Future<void> updateExercise(String exerciseId, Map<String, dynamic> exerciseData) async {
    await _firestore.collection('exercisesWorkout').doc(exerciseId).update(exerciseData);
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _firestore.collection('exercisesWorkout').doc(exerciseId).delete();
  }

  Future<Map<String, dynamic>> fetchExercise(String exerciseId) async {
    final docSnapshot = await _firestore.collection('exercisesWorkout').doc(exerciseId).get();
    if (!docSnapshot.exists) {
      throw Exception('Exercise not found');
    }
    return docSnapshot.data()!;
  }

  Future<void> createExercise(Map<String, dynamic> exerciseData) async {
    await _firestore.collection('exercisesWorkout').add(exerciseData);
  }

  Future<void> updateWorkout(String workoutId, Map<String, dynamic> workoutData) async {
    await _firestore.collection('workouts').doc(workoutId).update(workoutData);
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _firestore.collection('workouts').doc(workoutId).delete();
  }

  Future<Map<String, dynamic>> fetchWorkout(String workoutId) async {
    final docSnapshot = await _firestore.collection('workouts').doc(workoutId).get();
    if (!docSnapshot.exists) {
      throw Exception('Workout not found');
    }
    return docSnapshot.data()!;
  }

  Future<void> createWorkout(Map<String, dynamic> workoutData) async {
    await _firestore.collection('workouts').add(workoutData);
  }

  Future<void> updateWeek(String weekId, Map<String, dynamic> weekData) async {
    await _firestore.collection('weeks').doc(weekId).update(weekData);
  }

  Future<void> deleteWeek(String weekId) async {
    await _firestore.collection('weeks').doc(weekId).delete();
  }

  Future<Map<String, dynamic>> fetchWeek(String weekId) async {
    final docSnapshot = await _firestore.collection('weeks').doc(weekId).get();
    if (!docSnapshot.exists) {
      throw Exception('Week not found');
    }
    return docSnapshot.data()!;
  }

  Future<void> createWeek(Map<String, dynamic> weekData) async {
    await _firestore.collection('weeks').add(weekData);
  }
}