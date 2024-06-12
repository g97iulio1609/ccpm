import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutService {
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
}
