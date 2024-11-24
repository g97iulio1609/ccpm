import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseModel {
  final String id;
  final String name;
  final String type;
  final String muscleGroup;
  final String? status;
  final String? userId;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.type,
    required this.muscleGroup,
    this.status,
    this.userId,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      muscleGroup: json['muscleGroup'] ?? '',
      status: json['status'],
      userId: json['userId'],
    );
  }

  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }
}