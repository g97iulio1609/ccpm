import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_model.dart';
import '../models/series_model.dart';
import 'series_service.dart';

class ExerciseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SeriesService _seriesService = SeriesService();

  Future<String> addExerciseToWorkout(
      String workoutId, Map<String, dynamic> exerciseData) async {
    // Ensure exerciseData contains the exerciseId which will be used as originalExerciseId
    if (!exerciseData.containsKey('exerciseId')) {
      throw ArgumentError('exerciseId is required in exerciseData');
    }

    // Salviamo le serie separatamente
    List<Series>? series;
    if (exerciseData.containsKey('series')) {
      series = List<Series>.from(
          exerciseData['series']?.map((x) => Series.fromMap(x)) ?? []);
      exerciseData.remove('series');
    }

    DocumentReference ref = await _db.collection('exercisesWorkout').add({
      ...exerciseData,
      'workoutId': workoutId,
    });

    // Se ci sono serie, le salviamo con l'originalExerciseId corretto
    if (series != null) {
      for (var serie in series) {
        await _seriesService.addSeriesToExercise(
          ref.id,
          serie,
          originalExerciseId: exerciseData['exerciseId'],
        );
      }
    }

    return ref.id;
  }

  Future<void> updateExercise(
      String exerciseId, Map<String, dynamic> exerciseData) async {
    // Se ci sono serie da aggiornare
    if (exerciseData.containsKey('series')) {
      List<Series> series = List<Series>.from(
          exerciseData['series']?.map((x) => Series.fromMap(x)) ?? []);
      exerciseData.remove('series');

      // Aggiorniamo ogni serie con l'originalExerciseId corretto
      for (var serie in series) {
        if (serie.id != null) {
          await _seriesService.updateSeries(serie.id!,
              serie.copyWith(originalExerciseId: exerciseData['exerciseId']));
        } else {
          await _seriesService.addSeriesToExercise(
            exerciseId,
            serie,
            originalExerciseId: exerciseData['exerciseId'],
          );
        }
      }
    }

    await _db
        .collection('exercisesWorkout')
        .doc(exerciseId)
        .update(exerciseData);
  }

  Future<void> removeExercise(String exerciseId) async {
    await _db.collection('exercisesWorkout').doc(exerciseId).delete();
  }

  Future<List<Exercise>> fetchExercisesByWorkoutId(String workoutId) async {
    var snapshot = await _db
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('order')
        .get();
    var exercises =
        snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();
    return exercises;
  }
}
