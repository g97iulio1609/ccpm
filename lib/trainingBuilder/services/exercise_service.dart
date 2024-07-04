import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_model.dart';

class ExerciseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> addExerciseToWorkout(
      String workoutId, Map<String, dynamic> exerciseData) async {
    DocumentReference ref = await _db.collection('exercisesWorkout').add({
      ...exerciseData,
      'workoutId': workoutId,
    });
    return ref.id;
  }

  Future<void> updateExercise(
      String exerciseId, Map<String, dynamic> exerciseData) async {
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
