import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseModel {
    final String id;
    final String name;
    final String muscleGroup;
    final String type;

    ExerciseModel({
        required this.id,
        required this.name,
        required this.muscleGroup,
        required this.type,
    });

    factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>; // Cast esplicito
        return ExerciseModel(
            id: doc.id,
            name: data['name'] ?? '',
            muscleGroup: data['muscleGroup'] ?? '',
            type: data['type'] ?? '',
        );
    }
}
