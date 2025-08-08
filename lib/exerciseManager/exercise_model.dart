import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseModel {
  final String id;
  final String name;
  final String type;
  final List<String> muscleGroups;
  final String? status;
  final String? userId;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.type,
    required this.muscleGroups,
    this.status,
    this.userId,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    List<String> getMuscleGroups() {
      var muscleGroups = json['muscleGroups'];
      if (muscleGroups is List) {
        return muscleGroups.cast<String>();
      } else if (muscleGroups is String) {
        return [muscleGroups];
      }
      return [];
    }

    return ExerciseModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      muscleGroups: getMuscleGroups(),
      status: json['status'],
      userId: json['userId'],
    );
  }

  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseModel.fromJson({...data, 'id': doc.id});
  }
}
