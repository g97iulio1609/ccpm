import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_model.dart'; // Assicurati che il percorso sia corretto

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
}
