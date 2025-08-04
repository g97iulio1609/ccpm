import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alphanessone/shared/shared.dart';

class TrainingWorkoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> addWorkoutToWeek(
      String weekId, Map<String, dynamic> workoutData) async {
    DocumentReference ref = await _db.collection('workouts').add({
      ...workoutData,
      'weekId': weekId,
    });
    return ref.id;
  }

  Future<void> updateWorkout(
      String workoutId, Map<String, dynamic> workoutData) async {
    await _db.collection('workouts').doc(workoutId).update(workoutData);
  }

  Future<void> removeWorkout(String workoutId) async {
    await _db.collection('workouts').doc(workoutId).delete();
  }

  Future<List<Workout>> fetchWorkoutsByWeekId(String weekId) async {
    var snapshot = await _db
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .orderBy('order')
        .get();
    var workouts =
        snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
    return workouts;
  }
}
