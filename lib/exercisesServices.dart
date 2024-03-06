// exercisesService.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_model.dart';

final exercisesServiceProvider = Provider<ExercisesService>((ref) {
  return ExercisesService(FirebaseFirestore.instance);
});

class ExercisesService {
  final FirebaseFirestore _firestore;

  ExercisesService(this._firestore);

  Stream<List<ExerciseModel>> getExercises() {
    return _firestore.collection('exercises').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ExerciseModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addExercise(String name, String muscleGroup, String type) async {
    await _firestore.collection('exercises').add({
      'name': name,
      'muscleGroup': muscleGroup,
      'type': type,
    });
  }

  Future<void> updateExercise(String id, String name, String muscleGroup, String type) async {
    await _firestore.collection('exercises').doc(id).update({
      'name': name,
      'muscleGroup': muscleGroup,
      'type': type,
    });
  }

  Future<void> deleteExercise(String id) async {
    await _firestore.collection('exercises').doc(id).delete();
  }
}